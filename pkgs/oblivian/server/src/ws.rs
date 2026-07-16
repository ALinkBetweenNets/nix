use crate::vault::Vault;
use crate::App;
use axum::extract::ws::{Message as WsMessage, WebSocket, WebSocketUpgrade};
use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde::Deserialize;
use std::collections::HashSet;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use tokio::sync::broadcast::error::RecvError;

#[derive(Deserialize)]
struct Hello {
    password: String,
}

pub async fn ws_handler(
    Path(id): Path<String>,
    State(app): State<Arc<App>>,
    ws: WebSocketUpgrade,
) -> Response {
    let vault = match app.open_vault(&id).await {
        Ok(Some(v)) => v,
        Ok(None) => return StatusCode::NOT_FOUND.into_response(),
        Err(e) => {
            eprintln!("open vault {id}: {e:#}");
            return StatusCode::INTERNAL_SERVER_ERROR.into_response();
        }
    };
    let conn_id = app.next_conn_id.fetch_add(1, Ordering::Relaxed);
    ws.on_upgrade(move |socket| connection(socket, vault, conn_id))
}

async fn connection(mut socket: WebSocket, vault: Arc<Vault>, conn_id: u64) {
    // Handshake: first message is JSON {"password": ...}; reply "ok" or close.
    let authed = match socket.recv().await {
        Some(Ok(WsMessage::Text(t))) => serde_json::from_str::<Hello>(&t)
            .map(|h| vault.verify_password(&h.password))
            .unwrap_or(false),
        _ => return,
    };
    if !authed {
        let _ = socket.send(WsMessage::Text("denied".into())).await;
        return;
    }
    if socket.send(WsMessage::Text("ok".into())).await.is_err() {
        return;
    }

    let mut rx = vault.tx.subscribe();
    // Awareness client ids this connection introduced, cleaned up on close.
    let mut owned = HashSet::new();

    loop {
        tokio::select! {
            msg = socket.recv() => match msg {
                Some(Ok(WsMessage::Binary(frame))) => {
                    match vault.handle_frame(conn_id, &frame, &mut owned) {
                        Ok(replies) => {
                            for r in replies {
                                if socket.send(WsMessage::Binary(r.into())).await.is_err() {
                                    break;
                                }
                            }
                        }
                        Err(e) => {
                            eprintln!("conn {conn_id}: bad frame: {e:#}");
                            break;
                        }
                    }
                }
                Some(Ok(WsMessage::Close(_))) | None | Some(Err(_)) => break,
                Some(Ok(_)) => {} // ignore pings/other text
            },
            fanout = rx.recv() => match fanout {
                Ok((src, frame)) => {
                    if src != conn_id
                        && socket.send(WsMessage::Binary(frame.to_vec().into())).await.is_err()
                    {
                        break;
                    }
                }
                // Lagged means we dropped fan-out frames; close so the client
                // reconnects and repairs state via the sync handshake.
                Err(RecvError::Lagged(_)) => break,
                Err(RecvError::Closed) => break,
            },
        }
    }
    vault.drop_awareness(conn_id, &owned);
}
