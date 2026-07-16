import * as Y from "yjs";
import * as encoding from "lib0/encoding";
import * as decoding from "lib0/decoding";
import * as syncProtocol from "y-protocols/sync";
import * as awarenessProtocol from "y-protocols/awareness";

// Wire message tags, matching yrs::sync on the server.
const MSG_SYNC = 0;
const MSG_AWARENESS = 1;
const MSG_QUERY_AWARENESS = 3;

export type Status = "offline" | "connecting" | "connected";

export interface DocSlot {
	doc: Y.Doc;
	awareness: awarenessProtocol.Awareness;
	synced: boolean;
}

/**
 * Multiplexed Yjs websocket provider: every doc of one vault shares a single
 * connection. Each binary frame is `varString(docPath)` followed by standard
 * y-protocols sync/awareness messages. The connection opens with a JSON
 * password handshake answered by "ok" or "denied".
 */
export class MuxProvider {
	readonly docs = new Map<string, DocSlot>();
	status: Status = "offline";
	authFailed = false;
	onStatus: (s: Status) => void = () => {};
	onSynced: (path: string) => void = () => {};

	private ws: WebSocket | null = null;
	private stopped = false;
	private retryMs = 1000;
	private retryTimer: ReturnType<typeof setTimeout> | null = null;
	private url: string;
	private password: string;

	// plain field assignment: parameter properties break node's type stripping,
	// which test/integration.mjs relies on to import this file directly
	constructor(url: string, password: string) {
		this.url = url;
		this.password = password;
	}

	addDoc(path: string, doc: Y.Doc): DocSlot {
		const existing = this.docs.get(path);
		if (existing) return existing;
		const awareness = new awarenessProtocol.Awareness(doc);
		const slot: DocSlot = { doc, awareness, synced: false };
		this.docs.set(path, slot);

		doc.on("update", (update: Uint8Array, origin: unknown) => {
			if (origin === this) return;
			const enc = encoding.createEncoder();
			encoding.writeVarString(enc, path);
			encoding.writeVarUint(enc, MSG_SYNC);
			syncProtocol.writeUpdate(enc, update);
			this.send(encoding.toUint8Array(enc));
		});
		awareness.on(
			"update",
			(
				changes: { added: number[]; updated: number[]; removed: number[] },
				origin: unknown,
			) => {
				if (origin !== "local") return;
				const changed = changes.added.concat(changes.updated, changes.removed);
				const enc = encoding.createEncoder();
				encoding.writeVarString(enc, path);
				encoding.writeVarUint(enc, MSG_AWARENESS);
				encoding.writeVarUint8Array(
					enc,
					awarenessProtocol.encodeAwarenessUpdate(awareness, changed),
				);
				this.send(encoding.toUint8Array(enc));
			},
		);

		if (this.status === "connected") this.syncDoc(path, slot);
		return slot;
	}

	connect() {
		if (this.stopped || this.ws) return;
		this.setStatus("connecting");
		const ws = new WebSocket(this.url);
		ws.binaryType = "arraybuffer";
		this.ws = ws;

		ws.onopen = () => ws.send(JSON.stringify({ password: this.password }));
		ws.onmessage = (ev: MessageEvent) => {
			if (typeof ev.data === "string") {
				if (ev.data === "ok") {
					this.retryMs = 1000;
					this.setStatus("connected");
					for (const [path, slot] of this.docs) this.syncDoc(path, slot);
				} else {
					// Wrong password: retrying won't help, stop until reconfigured.
					this.authFailed = true;
					this.destroy();
				}
				return;
			}
			this.handleFrame(new Uint8Array(ev.data as ArrayBuffer));
		};
		ws.onclose = () => {
			if (this.ws !== ws) return;
			this.ws = null;
			for (const slot of this.docs.values()) {
				slot.synced = false;
				const remote = [...slot.awareness.getStates().keys()].filter(
					(c) => c !== slot.doc.clientID,
				);
				awarenessProtocol.removeAwarenessStates(slot.awareness, remote, this);
			}
			this.setStatus("offline");
			if (!this.stopped) {
				this.retryTimer = setTimeout(() => this.connect(), this.retryMs);
				this.retryMs = Math.min(this.retryMs * 2, 30_000);
			}
		};
		ws.onerror = () => ws.close();
	}

	destroy() {
		this.stopped = true;
		if (this.retryTimer) clearTimeout(this.retryTimer);
		const ws = this.ws;
		this.ws = null;
		ws?.close();
		for (const slot of this.docs.values()) slot.awareness.destroy();
		this.setStatus("offline");
	}

	private setStatus(s: Status) {
		if (this.status === s) return;
		this.status = s;
		this.onStatus(s);
	}

	private send(frame: Uint8Array) {
		// Dropped frames while offline are fine: the sync handshake on
		// reconnect exchanges exactly the missing updates.
		if (this.status === "connected" && this.ws?.readyState === WebSocket.OPEN) {
			this.ws.send(frame as Uint8Array<ArrayBuffer>);
		}
	}

	private syncDoc(path: string, slot: DocSlot) {
		const enc = encoding.createEncoder();
		encoding.writeVarString(enc, path);
		encoding.writeVarUint(enc, MSG_SYNC);
		syncProtocol.writeSyncStep1(enc, slot.doc);
		this.send(encoding.toUint8Array(enc));

		const query = encoding.createEncoder();
		encoding.writeVarString(query, path);
		encoding.writeVarUint(query, MSG_QUERY_AWARENESS);
		this.send(encoding.toUint8Array(query));

		if (slot.awareness.getLocalState() !== null) {
			const aw = encoding.createEncoder();
			encoding.writeVarString(aw, path);
			encoding.writeVarUint(aw, MSG_AWARENESS);
			encoding.writeVarUint8Array(
				aw,
				awarenessProtocol.encodeAwarenessUpdate(slot.awareness, [
					slot.doc.clientID,
				]),
			);
			this.send(encoding.toUint8Array(aw));
		}
	}

	private handleFrame(frame: Uint8Array) {
		const dec = decoding.createDecoder(frame);
		const path = decoding.readVarString(dec);
		const slot = this.docs.get(path);
		// Frames for docs we don't track yet: the index doc will tell us about
		// them and the doc then syncs from scratch, so dropping is safe.
		if (!slot) return;
		while (decoding.hasContent(dec)) {
			const type = decoding.readVarUint(dec);
			switch (type) {
				case MSG_SYNC: {
					const reply = encoding.createEncoder();
					encoding.writeVarString(reply, path);
					encoding.writeVarUint(reply, MSG_SYNC);
					const emptyLen = encoding.length(reply);
					const msgType = syncProtocol.readSyncMessage(dec, reply, slot.doc, this);
					if (encoding.length(reply) > emptyLen) {
						this.send(encoding.toUint8Array(reply));
					}
					if (
						msgType === syncProtocol.messageYjsSyncStep2 &&
						!slot.synced
					) {
						slot.synced = true;
						this.onSynced(path);
					}
					break;
				}
				case MSG_AWARENESS:
					awarenessProtocol.applyAwarenessUpdate(
						slot.awareness,
						decoding.readVarUint8Array(dec),
						this,
					);
					break;
				default:
					return; // unknown message, drop rest of frame
			}
		}
	}
}
