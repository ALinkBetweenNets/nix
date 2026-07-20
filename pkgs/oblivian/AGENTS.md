# AGENTS.md

Oblivian is live collaboration for Obsidian vaults, built on Yjs/yrs CRDTs.
See `README.md` for user/operator setup; this file is for editing the code.

Two halves that share a wire protocol:

- **`plugin/`** — Obsidian plugin (TypeScript, bundled to `main.js` by esbuild).
- **`server/`** — Rust axum + yrs sync server (`oblivian-server`).

## Layout

Plugin (`plugin/src/`):
- `main.ts` — entry point. Wires vault/workspace events to the Engine, owns the global editor `Compartment` and status bar.
- `engine.ts` — one `Y.Doc` per synced file, plus an `__index__` doc replicating create/delete/rename. IndexedDB persistence and disk⇄ydoc reconciliation.
- `paths.ts` — pure path policy: `shouldSync`, `isConfig`, `isText`. No `obsidian` import (so the node test can import it). This is the security boundary — it's what excludes Oblivian's own settings.
- `provider.ts` — `MuxProvider`: one websocket per vault, all docs multiplexed over it; password handshake; reconnect/backoff.
- `editor-binding.ts` — `EditorBinder`: attaches `yCollab` (live sync + remote cursors) to CodeMirror. Markdown only.
- `settings.ts` — settings tab; `POST /vaults` (create) and `POST /vaults/{id}/password` (rotate) HTTP calls.

Server (`server/src/`):
- `lib.rs` — `App`, `router`. Routes: `POST /vaults`, `POST /vaults/{id}/password`, `ANY /vault/{id}` (ws). `valid_id` gates vault ids.
- `ws.rs` — per-connection password handshake, `select!` loop, broadcast fan-out, awareness cleanup on disconnect.
- `vault.rs` — `Vault`/`DocEntry`, `handle_frame` (the protocol core), broadcast channel, `encode_frame`.
- `store.rs` — `DocStore`: snapshot `.bin` + append-only `.log`, compaction every 256 updates, no fsync.
- `auth.rs` — argon2 password hash/verify.

## Build / test / run

Plugin (`cd plugin`):
- `npm install`
- `npm run build` — `tsc -noEmit` typecheck + esbuild production bundle → `main.js`
- `npm run dev` — esbuild watch
- `npm test` — `test/integration.mjs`: builds and spawns the real Rust server, drives `MuxProvider` against it (cross-language check)

Server (`cd server`):
- `cargo test` — unit test in `store.rs` + `tests/sync.rs` (two clients converge, wrong password rejected, state survives restart, offline edits merge)
- `cargo run` — env: `OBLIVIAN_LISTEN` (default `0.0.0.0:9850`), `OBLIVIAN_DATA_DIR` (default `data`)

Nix: package `pkgs.link.oblivian-server` (`default.nix`); module `modules/services/oblivian.nix`, enabled via `link.services.oblivian.enable`.

## Architecture

Every synced file is its own `Y.Doc`. A `.md` file uses a `content` `Y.Text`
(collaborative, character-merged); every other file uses a `blob` `Y.Map` with
a single `data: Uint8Array` (last-writer-wins on the whole byte string). The
plugin keeps docs in IndexedDB and, when a file isn't open in an editor, mirrors
the doc to disk; when a `.md` file *is* open, `yCollab` binds the editor's
CodeMirror to the doc directly. An `__index__` doc (a `Y.Map`) replicates the
file list so create/delete/rename propagate. The server holds each doc in
memory, persists a snapshot + update log per doc, and fans out every update to
the other clients — it is **content-agnostic**, so blob support needed zero
server changes.

Two IO backends by path (`paths.ts`): normal vault files (any extension) go
through the vault API + vault events; config-dir files (`.obsidian/**`) have no
TFile and fire no vault events, so they go through `app.vault.adapter`
(`list`/`readBinary`/`writeBinary`) and are enumerated once at startup — there
is no polling. Remote config updates still apply live; only *local* config
changes wait for the next Obsidian restart.

## Wire protocol (keep TS and Rust in lockstep)

- Each binary frame is `varString(docPath)` followed by one or more y-protocols messages.
- Message tags: `0` sync, `1` awareness, `3` query-awareness. `provider.ts` `MSG_*` constants must match `yrs::sync` handling in `vault.rs`.
- The connection opens with a JSON text message `{"password": ...}`; the server replies with the text `"ok"` or `"denied"`.
- Path safety: the server rejects doc paths containing `..` or starting with `/`; `valid_id` restricts vault ids to `[A-Za-z0-9_-]`, ≤64 chars.

## Invariants — read before touching sync code

These are the failure modes the design exists to prevent. Breaking one loses
user data silently.

- **`pendingSeed` (engine.ts).** A locally-created doc's *disk* content is the source of truth until the first server sync merges the two. Don't bind an editor or write ydoc→disk while a path is in `pendingSeed`, or a joiner's pre-existing files get clobbered by server state (or duplicated into it).
- **Editor binding lives in one global `Compartment`** registered via `registerEditorExtension` (main.ts), *not* `StateEffect.appendConfig`. Obsidian rebuilds editor configs on `updateOptions()` (any plugin load / settings change) and silently drops appended configs, resetting the compartment to `[]`. `binder.refresh()` therefore runs on workspace events *and* a 2s interval to re-attach after a silent rebuild. (This was the fix in commit 6e961cb8 — don't regress it.)
- **`onLocalModify` skip rule (engine.ts).** Do not reconcile-from-disk a file that's open in an editor while it's bound or the provider is connected. Open files are mirrored by the editor, and their autosaved disk copy lags remote content that was never written to disk; diffing that disk copy would delete collaborators' edits ("host overwrites collaborators").
- **Deletions are tombstones.** The doc and its history stay managed after delete; remote deletions move the local file to system trash (recoverable), never a hard delete.
- **Post-`restartSync` closure gating.** `registerEvent` callbacks only detach on plugin unload, so old-engine closures still fire after a restart. They're gated by `active()` checking `this.engine === engine`.
- **No fsync in `store.rs` is deliberate.** Clients hold the same CRDT state and re-send missing updates on the reconnect handshake, so a lost log tail self-heals. Compaction happens every 256 updates and on graceful shutdown.
- **esbuild externals.** `obsidian` and all `@codemirror/*` must stay `external` (esbuild.config.mjs) so `yCollab` shares the app's own CodeMirror instances — bundling a second copy breaks CodeMirror facets.
- **`shouldSync` is the security boundary (paths.ts).** It must exclude `.obsidian/plugins/oblivian/` (that dir holds the vault password in `data.json`, and syncing it would loop settings between users) and hidden files outside `.obsidian`. Keep it obsidian-import-free so `test/integration.mjs` can assert it under node. Changing what syncs = changing this one function.
- **Blob seeding / `blob` map key.** A blob doc is `pendingSeed` until its `Y.Map("blob")` has a `data` key. Don't rename the `"blob"`/`"data"` keys without a migration — they identify a doc's shape across the network and IndexedDB. Blob reconciliation reads/writes bytes via `app.vault.adapter` uniformly (works for both normal and config files); the `docs.has(path)` guard on the resulting vault event prevents write→event→write loops.

## Conventions

- Comments explain *why* — the invariant or failure mode being guarded against — and cluster densely at the tricky spots. Match that; don't strip them.
- Rust: edition 2024, `anyhow` for errors, `eprintln!` for server-side logging.
- Deliberate limits (not bugs): non-`.md` files are last-writer-wins, not merged; config-dir changes are captured only at startup; Obsidian's native undo isn't Yjs-aware so it can undo collaborators' edits.
