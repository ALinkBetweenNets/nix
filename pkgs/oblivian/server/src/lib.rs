pub mod auth;
pub mod store;
pub mod vault;
pub mod ws;

use axum::extract::{Path, State};
use axum::http::StatusCode;
use axum::routing::{any, post};
use axum::{Json, Router};
use serde::Deserialize;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::atomic::AtomicU64;
use std::sync::Arc;
use tokio::sync::Mutex;
use vault::Vault;

pub struct App {
    pub data_dir: PathBuf,
    pub vaults: Mutex<HashMap<String, Arc<Vault>>>,
    pub next_conn_id: AtomicU64,
}

impl App {
    /// Returns the vault, loading it from disk on first access. None if it was never created.
    pub async fn open_vault(&self, id: &str) -> anyhow::Result<Option<Arc<Vault>>> {
        if !valid_id(id) {
            return Ok(None);
        }
        let mut vaults = self.vaults.lock().await;
        if let Some(v) = vaults.get(id) {
            return Ok(Some(v.clone()));
        }
        let dir = self.data_dir.join(id);
        if !dir.join("meta.json").exists() {
            return Ok(None);
        }
        let v = Arc::new(Vault::open(dir)?);
        vaults.insert(id.to_string(), v.clone());
        Ok(Some(v))
    }
}

fn valid_id(id: &str) -> bool {
    !id.is_empty()
        && id.len() <= 64
        && id
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_')
}

#[derive(Deserialize)]
struct CreateVault {
    id: String,
    password: String,
}

async fn create_vault(State(app): State<Arc<App>>, Json(req): Json<CreateVault>) -> StatusCode {
    if !valid_id(&req.id) || req.password.is_empty() {
        return StatusCode::BAD_REQUEST;
    }
    let dir = app.data_dir.join(&req.id);
    if dir.join("meta.json").exists() {
        return StatusCode::CONFLICT;
    }
    match Vault::create(&dir, &req.password) {
        Ok(()) => StatusCode::CREATED,
        Err(e) => {
            eprintln!("create vault {}: {e:#}", req.id);
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

#[derive(Deserialize)]
struct RotatePassword {
    password: String,
    new_password: String,
}

async fn rotate_password(
    Path(id): Path<String>,
    State(app): State<Arc<App>>,
    Json(req): Json<RotatePassword>,
) -> StatusCode {
    let vault = match app.open_vault(&id).await {
        Ok(Some(v)) => v,
        Ok(None) => return StatusCode::NOT_FOUND,
        Err(e) => {
            eprintln!("open vault {id}: {e:#}");
            return StatusCode::INTERNAL_SERVER_ERROR;
        }
    };
    if req.new_password.is_empty() || !vault.verify_password(&req.password) {
        return StatusCode::UNAUTHORIZED;
    }
    match vault.set_password(&req.new_password) {
        Ok(()) => StatusCode::NO_CONTENT,
        Err(e) => {
            eprintln!("rotate password {id}: {e:#}");
            StatusCode::INTERNAL_SERVER_ERROR
        }
    }
}

pub fn router(app: Arc<App>) -> Router {
    Router::new()
        .route("/vaults", post(create_vault))
        .route("/vaults/{id}/password", post(rotate_password))
        .route("/vault/{id}", any(ws::ws_handler))
        .with_state(app)
}
