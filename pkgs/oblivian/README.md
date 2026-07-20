# Oblivian

Live collaboration for Obsidian vaults through a self-hosted sync server,
built on Yjs/yrs CRDTs. Multiple people edit the same vault's markdown files
simultaneously with visible remote cursors; edits made offline merge
losslessly when the connection returns.

Two parts:

- **`plugin/`** — the Obsidian plugin. One Y.Doc per file: markdown files are
  collaborative `Y.Text` bound to the editor via `y-codemirror.next`, every
  other file (attachments, installed plugins) is a byte blob. Persisted locally
  in IndexedDB, synced over a single multiplexed websocket per vault.
- **`server/`** — a Rust (axum + yrs) server. Hosts any number of vaults;
  each vault is created by one person (the host) with a password that gates
  access. Meant to run on a tailnet node, reachable by all collaborators.

## Server

### NixOS

Packaged in this repo: `pkgs.link.oblivian-server` (overlay) and the
`modules/services/oblivian.nix` module. Enable it on a machine with:

```nix
link.services.oblivian = {
  enable = true;
  # port = 9850;
  # expose-port = ...;  # defaults to link.service-ports-expose
};
```

State lives in `/var/lib/oblivian`. Traffic is plain HTTP/WS — the tailnet
provides transport encryption and network-level access control; the vault
password controls who can join a vault.

### Manual

```sh
cd server && cargo run   # OBLIVIAN_LISTEN=0.0.0.0:9850 OBLIVIAN_DATA_DIR=data
```

## Plugin

Build and install:

```sh
cd plugin && npm install && npm run build
mkdir -p <vault>/.obsidian/plugins/oblivian
cp main.js manifest.json styles.css <vault>/.obsidian/plugins/oblivian/
```

Enable it in Obsidian, then in the plugin settings:

1. **Host**: fill in server URL, a vault ID, and a password → *Create vault
   on server* → toggle *Enable sync*. Your vault's files seed the server.
2. **Collaborators**: get the vault ID and password from the host, fill in
   the same settings → toggle *Enable sync*. The vault's files materialize
   locally. (Joining with a pre-existing copy of the same vault works; files
   are merged, not overwritten.)

The host revokes access by rotating the password in settings.

## How data loss is avoided

- Every file is a CRDT (Yjs). Concurrent and offline edits merge
  deterministically — nothing is overwritten by "last writer wins".
- Local edits persist in IndexedDB across Obsidian restarts while offline,
  and the markdown files themselves remain on disk as usual.
- Edits made on disk while the plugin was off (other editors, git) are
  diffed into the CRDT on startup, never blindly replaced.
- Deletions are tombstones: the doc history survives on the server, and
  remote deletions move local files to the system trash.
- The server keeps a snapshot + append-only update log per doc; if the log's
  tail is lost, clients re-send missing updates on the next sync handshake.

## What syncs

All files of any extension (notes, attachments), plus the `.obsidian` config
dir so installed plugins, themes, snippets and settings travel with the vault.
Excluded: hidden files/folders outside `.obsidian` (`.trash`, `.git`, …),
per-device window layout (`workspace.json`), and — importantly — Oblivian's own
settings (`.obsidian/plugins/oblivian/`), which hold the vault password.

Markdown merges character-by-character; every other file is last-writer-wins on
its bytes. The config dir is snapshotted at startup and applied live, but local
config changes (e.g. installing a plugin) are only picked up on the next
Obsidian restart, and plugin/theme files written to disk need a restart to load.

Known limits (deliberate): undo may undo collaborators' edits (Obsidian's native
undo isn't Yjs-aware); a file deleted while a peer edits it offline resurrects
from the trash-side peer; a very large attachment travels as one Yjs update.

## Development

```sh
cd server && cargo test          # protocol, persistence, auth tests
cd plugin && npm test            # TS provider <-> Rust server integration
```
