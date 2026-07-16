//! Per-document persistence: a full-state snapshot file plus an append-only
//! update log. Updates go to the log; every COMPACT_EVERY updates (and on
//! shutdown) the doc state is snapshotted and the log truncated.
//!
//! No fsync: clients hold the same CRDT state locally and re-send any updates
//! the server is missing on the next sync handshake, so a lost tail is healed.

use sha2::{Digest, Sha256};
use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::path::PathBuf;

const COMPACT_EVERY: usize = 256;

pub struct DocStore {
    snap_path: PathBuf,
    log: File,
    log_path: PathBuf,
    log_count: usize,
}

impl DocStore {
    /// Opens storage for a doc, returning the store and the persisted updates
    /// to replay (snapshot first, then log entries).
    pub fn open(docs_dir: &std::path::Path, doc_path: &str) -> anyhow::Result<(Self, Vec<Vec<u8>>)> {
        std::fs::create_dir_all(docs_dir)?;
        let hash: String = Sha256::digest(doc_path.as_bytes())
            .iter()
            .map(|b| format!("{b:02x}"))
            .collect();
        let snap_path = docs_dir.join(format!("{hash}.bin"));
        let log_path = docs_dir.join(format!("{hash}.log"));

        let mut updates = Vec::new();
        if snap_path.exists() {
            updates.push(std::fs::read(&snap_path)?);
        }
        let mut log_count = 0;
        if log_path.exists() {
            let mut buf = Vec::new();
            File::open(&log_path)?.read_to_end(&mut buf)?;
            let mut pos = 0;
            // A partial trailing record (crash mid-write) is silently dropped.
            while pos + 4 <= buf.len() {
                let len = u32::from_le_bytes(buf[pos..pos + 4].try_into().unwrap()) as usize;
                pos += 4;
                if pos + len > buf.len() {
                    break;
                }
                updates.push(buf[pos..pos + len].to_vec());
                pos += len;
                log_count += 1;
            }
        }
        let log = OpenOptions::new().create(true).append(true).open(&log_path)?;
        Ok((
            Self {
                snap_path,
                log,
                log_path,
                log_count,
            },
            updates,
        ))
    }

    pub fn append(&mut self, update: &[u8]) -> anyhow::Result<()> {
        self.log.write_all(&(update.len() as u32).to_le_bytes())?;
        self.log.write_all(update)?;
        self.log_count += 1;
        Ok(())
    }

    pub fn should_compact(&self) -> bool {
        self.log_count >= COMPACT_EVERY
    }

    #[cfg(test)]
    pub fn log_count(&self) -> usize {
        self.log_count
    }

    pub fn compact(&mut self, full_state: &[u8]) -> anyhow::Result<()> {
        let tmp = self.snap_path.with_extension("bin.tmp");
        std::fs::write(&tmp, full_state)?;
        std::fs::rename(&tmp, &self.snap_path)?;
        // truncate is incompatible with append mode; this handle is the only
        // writer, so plain write mode appends correctly from position 0.
        self.log = OpenOptions::new()
            .create(true)
            .write(true)
            .truncate(true)
            .open(&self.log_path)?;
        self.log_count = 0;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compact_then_reload() {
        let dir = std::env::temp_dir().join(format!("oblivian-store-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);

        let (mut store, updates) = DocStore::open(&dir, "note.md").unwrap();
        assert!(updates.is_empty());
        store.append(b"u1").unwrap();
        store.append(b"u2").unwrap();
        store.compact(b"snapshot").unwrap();
        store.append(b"u3").unwrap();
        drop(store);

        let (store, updates) = DocStore::open(&dir, "note.md").unwrap();
        assert_eq!(updates, vec![b"snapshot".to_vec(), b"u3".to_vec()]);
        assert_eq!(store.log_count(), 1);

        std::fs::remove_dir_all(&dir).unwrap();
    }
}
