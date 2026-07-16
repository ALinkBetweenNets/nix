use futures_util::{SinkExt, StreamExt};
use oblivian_server::vault::{encode_frame, Vault};
use oblivian_server::{router, App};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::atomic::AtomicU64;
use std::sync::Arc;
use std::time::Duration;
use tokio::net::TcpStream;
use tokio_tungstenite::tungstenite::Message as WsMsg;
use tokio_tungstenite::{MaybeTlsStream, WebSocketStream};
use yrs::encoding::read::Read;
use yrs::sync::{Message, SyncMessage};
use yrs::updates::decoder::{Decode, DecoderV1};
use yrs::{Doc, GetString, ReadTxn, StateVector, Text, Transact, Update};

type Ws = WebSocketStream<MaybeTlsStream<TcpStream>>;

async fn start_server(data_dir: &Path) -> (SocketAddr, tokio::task::JoinHandle<()>) {
    let app = Arc::new(App {
        data_dir: data_dir.to_path_buf(),
        vaults: tokio::sync::Mutex::new(HashMap::new()),
        next_conn_id: AtomicU64::new(0),
    });
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let handle = tokio::spawn(async move {
        axum::serve(listener, router(app)).await.unwrap();
    });
    (addr, handle)
}

async fn connect(addr: SocketAddr, vault: &str, password: &str) -> Ws {
    let (mut ws, _) = tokio_tungstenite::connect_async(format!("ws://{addr}/vault/{vault}"))
        .await
        .unwrap();
    ws.send(WsMsg::Text(format!("{{\"password\":\"{password}\"}}").into()))
        .await
        .unwrap();
    match ws.next().await.unwrap().unwrap() {
        WsMsg::Text(t) if t == "ok" => ws,
        other => panic!("auth failed: {other:?}"),
    }
}

fn decode_frame(bytes: &[u8]) -> (String, Vec<Message>) {
    let mut dec = DecoderV1::from(bytes);
    let path = dec.read_string().unwrap().to_string();
    let msgs = yrs::sync::MessageReader::new(&mut dec)
        .collect::<Result<Vec<_>, _>>()
        .unwrap();
    (path, msgs)
}

/// Runs the initial sync handshake for `doc` on `path`, then keeps applying
/// incoming updates until `deadline`-style quiesce (no message for 200ms).
async fn handshake(ws: &mut Ws, path: &str, doc: &Doc) {
    let sv = doc.transact().state_vector();
    ws.send(WsMsg::Binary(
        encode_frame(path, &Message::Sync(SyncMessage::SyncStep1(sv))).into(),
    ))
    .await
    .unwrap();
    // Expect the server's SyncStep2 and SyncStep1; reply to the latter.
    let mut got_step2 = false;
    let mut got_step1 = false;
    while !(got_step1 && got_step2) {
        let msg = tokio::time::timeout(Duration::from_secs(5), ws.next())
            .await
            .expect("handshake timeout")
            .unwrap()
            .unwrap();
        let WsMsg::Binary(b) = msg else { continue };
        let (p, msgs) = decode_frame(&b);
        assert_eq!(p, path);
        for m in msgs {
            match m {
                Message::Sync(SyncMessage::SyncStep2(u)) | Message::Sync(SyncMessage::Update(u)) => {
                    doc.transact_mut()
                        .apply_update(Update::decode_v1(&u).unwrap())
                        .unwrap();
                    got_step2 = true;
                }
                Message::Sync(SyncMessage::SyncStep1(server_sv)) => {
                    let diff = doc.transact().encode_diff_v1(&server_sv);
                    ws.send(WsMsg::Binary(
                        encode_frame(path, &Message::Sync(SyncMessage::SyncStep2(diff))).into(),
                    ))
                    .await
                    .unwrap();
                    got_step1 = true;
                }
                _ => {}
            }
        }
    }
}

/// Waits for the next remote update on `path` and applies it to `doc`.
async fn recv_update(ws: &mut Ws, path: &str, doc: &Doc) {
    loop {
        let msg = tokio::time::timeout(Duration::from_secs(5), ws.next())
            .await
            .expect("update timeout")
            .unwrap()
            .unwrap();
        let WsMsg::Binary(b) = msg else { continue };
        let (p, msgs) = decode_frame(&b);
        if p != path {
            continue;
        }
        for m in msgs {
            if let Message::Sync(SyncMessage::SyncStep2(u)) | Message::Sync(SyncMessage::Update(u)) = m
            {
                doc.transact_mut()
                    .apply_update(Update::decode_v1(&u).unwrap())
                    .unwrap();
                return;
            }
        }
    }
}

async fn send_edit(ws: &mut Ws, path: &str, doc: &Doc, index: u32, content: &str) {
    let sv_before = doc.transact().state_vector();
    let text = doc.get_or_insert_text("content");
    text.insert(&mut doc.transact_mut(), index, content);
    let diff = doc.transact().encode_diff_v1(&sv_before);
    ws.send(WsMsg::Binary(
        encode_frame(path, &Message::Sync(SyncMessage::Update(diff))).into(),
    ))
    .await
    .unwrap();
}

fn text_of(doc: &Doc) -> String {
    doc.get_or_insert_text("content").get_string(&doc.transact())
}

fn tmp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("oblivian-test-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

#[tokio::test]
async fn two_clients_converge() {
    let dir = tmp_dir("converge");
    Vault::create(&dir.join("v1"), "pw").unwrap();
    let (addr, _server) = start_server(&dir).await;

    let doc_a = Doc::new();
    let text = doc_a.get_or_insert_text("content");
    text.insert(&mut doc_a.transact_mut(), 0, "hello");
    let mut a = connect(addr, "v1", "pw").await;
    handshake(&mut a, "note.md", &doc_a).await;

    // B joins with an empty doc and receives "hello" through the handshake.
    let doc_b = Doc::new();
    let mut b = connect(addr, "v1", "pw").await;
    handshake(&mut b, "note.md", &doc_b).await;
    assert_eq!(text_of(&doc_b), "hello");

    // Live edit A -> B.
    send_edit(&mut a, "note.md", &doc_a, 5, " world").await;
    recv_update(&mut b, "note.md", &doc_b).await;
    assert_eq!(text_of(&doc_b), "hello world");

    // Live edit B -> A.
    send_edit(&mut b, "note.md", &doc_b, 0, ">> ").await;
    recv_update(&mut a, "note.md", &doc_a).await;
    assert_eq!(text_of(&doc_a), ">> hello world");
    assert_eq!(text_of(&doc_a), text_of(&doc_b));
}

#[tokio::test]
async fn wrong_password_rejected() {
    let dir = tmp_dir("badpw");
    Vault::create(&dir.join("v1"), "pw").unwrap();
    let (addr, _server) = start_server(&dir).await;

    let (mut ws, _) = tokio_tungstenite::connect_async(format!("ws://{addr}/vault/v1"))
        .await
        .unwrap();
    ws.send(WsMsg::Text("{\"password\":\"nope\"}".into()))
        .await
        .unwrap();
    match ws.next().await.unwrap().unwrap() {
        WsMsg::Text(t) => assert_eq!(t.as_str(), "denied"),
        other => panic!("expected denial, got {other:?}"),
    }
}

#[tokio::test]
async fn state_survives_restart() {
    let dir = tmp_dir("restart");
    Vault::create(&dir.join("v1"), "pw").unwrap();

    let (addr, server) = start_server(&dir).await;
    let doc = Doc::new();
    let text = doc.get_or_insert_text("content");
    text.insert(&mut doc.transact_mut(), 0, "persisted!");
    let mut ws = connect(addr, "v1", "pw").await;
    handshake(&mut ws, "note.md", &doc).await;
    // Give the server a beat to write the update log, then kill it.
    tokio::time::sleep(Duration::from_millis(200)).await;
    drop(ws);
    server.abort();

    let (addr2, _server2) = start_server(&dir).await;
    let doc2 = Doc::new();
    let mut ws2 = connect(addr2, "v1", "pw").await;
    handshake(&mut ws2, "note.md", &doc2).await;
    assert_eq!(text_of(&doc2), "persisted!");
}

#[tokio::test]
async fn concurrent_offline_edits_merge() {
    let dir = tmp_dir("offline");
    Vault::create(&dir.join("v1"), "pw").unwrap();
    let (addr, _server) = start_server(&dir).await;

    // Both start from the same synced base.
    let doc_a = Doc::new();
    doc_a
        .get_or_insert_text("content")
        .insert(&mut doc_a.transact_mut(), 0, "base");
    let mut a = connect(addr, "v1", "pw").await;
    handshake(&mut a, "note.md", &doc_a).await;
    let doc_b = Doc::new();
    let mut b = connect(addr, "v1", "pw").await;
    handshake(&mut b, "note.md", &doc_b).await;

    // "Offline": both edit locally without a connection, then reconnect and
    // let the sync handshake exchange the missing updates.
    drop(a);
    drop(b);
    doc_a
        .get_or_insert_text("content")
        .insert(&mut doc_a.transact_mut(), 4, " from-a");
    doc_b
        .get_or_insert_text("content")
        .insert(&mut doc_b.transact_mut(), 0, "from-b ");

    let mut a = connect(addr, "v1", "pw").await;
    handshake(&mut a, "note.md", &doc_a).await;
    let mut b = connect(addr, "v1", "pw").await;
    handshake(&mut b, "note.md", &doc_b).await;
    // A reconnects again to pick up B's offline edit.
    let mut a2 = connect(addr, "v1", "pw").await;
    handshake(&mut a2, "note.md", &doc_a).await;

    assert_eq!(text_of(&doc_a), "from-b base from-a");
    assert_eq!(text_of(&doc_a), text_of(&doc_b));
    drop((a, b, a2));
}
