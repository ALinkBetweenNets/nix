use oblivian_server::{router, App};
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::atomic::AtomicU64;
use std::sync::Arc;
use tokio::sync::Mutex;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let listen = std::env::var("OBLIVIAN_LISTEN").unwrap_or_else(|_| "0.0.0.0:9850".into());
    let data_dir: PathBuf = std::env::var("OBLIVIAN_DATA_DIR")
        .unwrap_or_else(|_| "data".into())
        .into();
    std::fs::create_dir_all(&data_dir)?;

    let app = Arc::new(App {
        data_dir,
        vaults: Mutex::new(HashMap::new()),
        next_conn_id: AtomicU64::new(0),
    });

    let listener = tokio::net::TcpListener::bind(&listen).await?;
    eprintln!("oblivian listening on {listen}");

    let shutdown_app = app.clone();
    axum::serve(listener, router(app))
        .with_graceful_shutdown(async move {
            let mut term =
                tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
                    .expect("install SIGTERM handler");
            tokio::select! {
                _ = tokio::signal::ctrl_c() => {}
                _ = term.recv() => {}
            }
            // Compact all loaded docs so restart doesn't replay long logs.
            for vault in shutdown_app.vaults.lock().await.values() {
                vault.compact_all();
            }
        })
        .await?;
    Ok(())
}
