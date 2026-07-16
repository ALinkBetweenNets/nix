use crate::auth;
use crate::store::DocStore;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, RwLock};
use tokio::sync::broadcast;
use yrs::sync::{Awareness, Message, SyncMessage};
use yrs::updates::decoder::{Decode, DecoderV1};
use yrs::updates::encoder::{Encode, Encoder, EncoderV1};
use yrs::{ClientID, Doc, ReadTxn, StateVector, Transact, Update};

/// A broadcast frame: (sender connection id, encoded wire frame).
pub type Frame = (u64, Arc<[u8]>);

#[derive(Serialize, Deserialize)]
struct Meta {
    password_hash: String,
}

pub struct Vault {
    dir: PathBuf,
    password_hash: RwLock<String>,
    docs: Mutex<HashMap<String, Arc<Mutex<DocEntry>>>>,
    pub tx: broadcast::Sender<Frame>,
}

pub struct DocEntry {
    pub awareness: Awareness,
    store: DocStore,
}

impl Vault {
    pub fn create(dir: &Path, password: &str) -> anyhow::Result<()> {
        std::fs::create_dir_all(dir)?;
        let meta = Meta {
            password_hash: auth::hash(password)?,
        };
        std::fs::write(dir.join("meta.json"), serde_json::to_vec(&meta)?)?;
        Ok(())
    }

    pub fn open(dir: PathBuf) -> anyhow::Result<Self> {
        let meta: Meta = serde_json::from_slice(&std::fs::read(dir.join("meta.json"))?)?;
        let (tx, _) = broadcast::channel(1024);
        Ok(Self {
            dir,
            password_hash: RwLock::new(meta.password_hash),
            docs: Mutex::new(HashMap::new()),
            tx,
        })
    }

    pub fn verify_password(&self, password: &str) -> bool {
        auth::verify(&self.password_hash.read().unwrap(), password)
    }

    pub fn set_password(&self, new_password: &str) -> anyhow::Result<()> {
        let hash = auth::hash(new_password)?;
        std::fs::write(
            self.dir.join("meta.json"),
            serde_json::to_vec(&Meta {
                password_hash: hash.clone(),
            })?,
        )?;
        *self.password_hash.write().unwrap() = hash;
        Ok(())
    }

    fn get_or_load_doc(&self, path: &str) -> anyhow::Result<Arc<Mutex<DocEntry>>> {
        let mut docs = self.docs.lock().unwrap();
        if let Some(e) = docs.get(path) {
            return Ok(e.clone());
        }
        let (store, updates) = DocStore::open(&self.dir.join("docs"), path)?;
        let doc = Doc::new();
        {
            let mut txn = doc.transact_mut();
            for u in updates {
                if let Ok(u) = Update::decode_v1(&u) {
                    let _ = txn.apply_update(u);
                }
            }
        }
        let entry = Arc::new(Mutex::new(DocEntry {
            awareness: Awareness::new(doc),
            store,
        }));
        docs.insert(path.to_string(), entry.clone());
        Ok(entry)
    }

    fn broadcast(&self, conn_id: u64, frame: Vec<u8>) {
        // send only fails when there are no subscribers, which is fine
        let _ = self.tx.send((conn_id, frame.into()));
    }

    /// Handles one incoming wire frame; returns replies to send back to the
    /// originating client. Updates are fanned out to all other clients.
    pub fn handle_frame(
        &self,
        conn_id: u64,
        frame: &[u8],
        owned_awareness: &mut HashSet<(String, ClientID)>,
    ) -> anyhow::Result<Vec<Vec<u8>>> {
        let mut decoder = DecoderV1::from(frame);
        let path = {
            use yrs::encoding::read::Read;
            decoder.read_string()?.to_string()
        };
        if path.contains("..") || path.starts_with('/') {
            anyhow::bail!("invalid doc path: {path}");
        }
        let entry = self.get_or_load_doc(&path)?;
        let mut replies = Vec::new();
        // Decode all messages first: MessageReader borrows the decoder.
        let msgs: Vec<Message> = yrs::sync::MessageReader::new(&mut decoder)
            .collect::<Result<_, _>>()?;
        for msg in msgs {
            match msg {
                Message::Sync(SyncMessage::SyncStep1(sv)) => {
                    let e = entry.lock().unwrap();
                    let txn = e.awareness.doc().transact();
                    replies.push(encode_frame(
                        &path,
                        &Message::Sync(SyncMessage::SyncStep2(txn.encode_diff_v1(&sv))),
                    ));
                    replies.push(encode_frame(
                        &path,
                        &Message::Sync(SyncMessage::SyncStep1(txn.state_vector())),
                    ));
                }
                Message::Sync(SyncMessage::SyncStep2(u)) | Message::Sync(SyncMessage::Update(u)) => {
                    if u == [0, 0] {
                        continue; // empty update (no structs, no deletions): no-op
                    }
                    let mut e = entry.lock().unwrap();
                    let update = Update::decode_v1(&u)?;
                    e.awareness.doc().transact_mut().apply_update(update)?;
                    e.store.append(&u)?;
                    if e.store.should_compact() {
                        let full = e
                            .awareness
                            .doc()
                            .transact()
                            .encode_state_as_update_v1(&StateVector::default());
                        e.store.compact(&full)?;
                    }
                    self.broadcast(conn_id, encode_frame(&path, &Message::Sync(SyncMessage::Update(u))));
                }
                Message::Awareness(u) => {
                    for &client in u.clients.keys() {
                        owned_awareness.insert((path.clone(), client));
                    }
                    let mut e = entry.lock().unwrap();
                    let _ = e.awareness.apply_update(u.clone());
                    self.broadcast(conn_id, encode_frame(&path, &Message::Awareness(u)));
                }
                Message::AwarenessQuery => {
                    let e = entry.lock().unwrap();
                    if let Ok(u) = e.awareness.update() {
                        if !u.clients.is_empty() {
                            replies.push(encode_frame(&path, &Message::Awareness(u)));
                        }
                    }
                }
                Message::Auth(_) | Message::Custom(..) => {}
            }
        }
        Ok(replies)
    }

    /// Broadcasts awareness removal for clients whose connection dropped.
    pub fn drop_awareness(&self, conn_id: u64, owned: &HashSet<(String, ClientID)>) {
        for (path, client) in owned {
            let entry = {
                let docs = self.docs.lock().unwrap();
                match docs.get(path) {
                    Some(e) => e.clone(),
                    None => continue,
                }
            };
            let mut e = entry.lock().unwrap();
            e.awareness.remove_state(*client);
            if let Ok(u) = e.awareness.update_with_clients([*client]) {
                self.broadcast(conn_id, encode_frame(path, &Message::Awareness(u)));
            }
        }
    }

    pub fn compact_all(&self) {
        for entry in self.docs.lock().unwrap().values() {
            let mut e = entry.lock().unwrap();
            let full = e
                .awareness
                .doc()
                .transact()
                .encode_state_as_update_v1(&StateVector::default());
            if let Err(err) = e.store.compact(&full) {
                eprintln!("compact: {err:#}");
            }
        }
    }
}

/// Encodes a wire frame: varstring doc path followed by one sync message.
pub fn encode_frame(path: &str, msg: &Message) -> Vec<u8> {
    use yrs::encoding::write::Write;
    let mut enc = EncoderV1::new();
    enc.write_string(path);
    msg.encode(&mut enc);
    enc.to_vec()
}
