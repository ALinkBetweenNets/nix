# Oblivian

Live collaboration for Obsidian vaults through a self-hosted sync server,
built on Yjs/yrs CRDTs. Multiple people edit the same vault's markdown files
simultaneously with visible remote cursors; edits made offline merge
losslessly when the connection returns.

Two parts:

- **`plugin/`** — the Obsidian plugin. One Y.Doc per markdown file, bound to
  the editor via `y-codemirror.next`, persisted locally in IndexedDB, synced
  over a single multiplexed websocket per vault.
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

Known limits (deliberate): only `.md` files sync (no attachments); undo may
undo collaborators' edits (Obsidian's native undo isn't Yjs-aware); a file
deleted while a peer edits it offline resurrects from the trash-side peer.

## Development

```sh
cd server && cargo test          # protocol, persistence, auth tests
cd plugin && npm test            # TS provider <-> Rust server integration
```
