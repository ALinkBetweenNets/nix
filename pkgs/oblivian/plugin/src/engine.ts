import { App, TFile, TFolder, normalizePath } from "obsidian";
import * as Y from "yjs";
import { IndexeddbPersistence } from "y-indexeddb";
import { simpleDiffString } from "lib0/diff";
import { DocSlot, MuxProvider } from "./provider";
import type { OblivianSettings } from "./settings";

export const INDEX_DOC = "__index__";
const LOCAL_INDEX = "local-index"; // txn origin for our own index edits
const DISK = "disk"; // txn origin for disk->ydoc reconciliation

interface IndexEntry {
	deleted: boolean;
}

interface Managed {
	slot: DocSlot;
	idb: IndexeddbPersistence;
}

/**
 * Owns one Y.Doc per markdown file plus the vault-level index doc that
 * replicates file create/delete/rename. Bridges Y.Docs to disk for files not
 * open in an editor, and reconciles disk edits made while the plugin was off.
 */
export class Engine {
	readonly provider: MuxProvider;
	/** Fires after a doc becomes safe to bind to an editor. */
	onReady: (path: string) => void = () => {};

	private docs = new Map<string, Managed>();
	private index!: Y.Map<IndexEntry>;
	/**
	 * Locally-originated docs that have never completed a server sync. Their
	 * disk content is the source of truth: we must not bind editors or write
	 * ydoc state to disk until the first sync merges the two (otherwise a
	 * joiner's pre-existing files would be clobbered by server state, or
	 * duplicated into it).
	 */
	private pendingSeed = new Set<string>();
	/** Paths with programmatic vault operations in flight (event echo guard). */
	private suppressed = new Set<string>();
	private writeTimers = new Map<string, ReturnType<typeof setTimeout>>();

	constructor(
		private app: App,
		private settings: OblivianSettings,
	) {
		const base = settings.serverUrl.replace(/^http/, "ws").replace(/\/+$/, "");
		this.provider = new MuxProvider(
			`${base}/vault/${settings.vaultId}`,
			settings.password,
		);
	}

	async start() {
		const indexDoc = new Y.Doc();
		this.index = indexDoc.getMap<IndexEntry>("files");
		await this.manage(INDEX_DOC, indexDoc);

		for (const file of this.app.vault.getMarkdownFiles()) {
			await this.openFileDoc(file.path);
		}
		// Merge edits made on disk while the plugin was off (only for docs
		// with prior local history; fresh docs seed on first sync instead).
		for (const [path] of this.docs) {
			if (path !== INDEX_DOC && !this.pendingSeed.has(path)) {
				await this.reconcileFromDisk(path);
			}
		}

		this.index.observe((event, txn) => {
			if (txn.origin === LOCAL_INDEX) return;
			void this.onRemoteIndexChange([...event.keysChanged]);
		});
		this.provider.onSynced = (path) => void this.onDocSynced(path);
		this.provider.connect();
	}

	stop() {
		this.provider.destroy();
		for (const t of this.writeTimers.values()) clearTimeout(t);
		for (const { slot, idb } of this.docs.values()) {
			void idb.destroy(); // closes the db handle, persisted data remains
			slot.doc.destroy();
		}
		this.docs.clear();
	}

	getSlot(path: string): DocSlot | undefined {
		return this.docs.get(path)?.slot;
	}

	/** A doc may be bound to an editor once its disk content can't be lost. */
	isReady(path: string): boolean {
		return this.docs.has(path) && !this.pendingSeed.has(path);
	}

	isAlive(path: string): boolean {
		const entry = this.index.get(path);
		return entry !== undefined && !entry.deleted;
	}

	// ---- local vault events (wired up in main.ts) ----

	async onLocalCreate(file: TFile) {
		if (this.suppressed.has(file.path) || this.docs.has(file.path)) return;
		await this.openFileDoc(file.path);
		this.setIndex(file.path, { deleted: false });
	}

	onLocalDelete(path: string) {
		if (this.suppressed.has(path) || !this.docs.has(path)) return;
		this.setIndex(path, { deleted: true });
		// The doc (and its history) stays managed: deletion is a tombstone, so
		// the content survives for undo/resurrection on every peer.
		this.pendingSeed.delete(path);
	}

	async onLocalRename(file: TFile, oldPath: string) {
		this.onLocalDelete(oldPath);
		if (file.extension !== "md") return;
		await this.openFileDoc(file.path);
		this.setIndex(file.path, { deleted: false });
		if (!this.pendingSeed.has(file.path)) {
			// Renamed back onto an existing doc: merge current disk content.
			await this.reconcileFromDisk(file.path);
		}
	}

	async onLocalModify(file: TFile) {
		if (!this.docs.has(file.path) || this.pendingSeed.has(file.path)) return;
		await this.reconcileFromDisk(file.path);
	}

	// ---- internals ----

	private async manage(path: string, doc: Y.Doc): Promise<Managed> {
		const idb = new IndexeddbPersistence(
			`oblivian/${this.settings.vaultId}/${path}`,
			doc,
		);
		await idb.whenSynced;
		const slot = this.provider.addDoc(path, doc);
		const managed = { slot, idb };
		this.docs.set(path, managed);
		return managed;
	}

	private async openFileDoc(path: string): Promise<Managed> {
		const existing = this.docs.get(path);
		if (existing) return existing;
		const doc = new Y.Doc();
		const managed = await this.manage(path, doc);
		const ytext = doc.getText("content");
		if (ytext.length === 0) this.pendingSeed.add(path);
		ytext.observe((_event, txn) => {
			if (txn.origin !== DISK) this.scheduleDiskWrite(path);
		});
		return managed;
	}

	private setIndex(path: string, entry: IndexEntry) {
		this.index.doc!.transact(() => this.index.set(path, entry), LOCAL_INDEX);
	}

	private async onDocSynced(path: string) {
		if (path === INDEX_DOC) {
			await this.onIndexSynced();
			return;
		}
		if (this.pendingSeed.has(path)) {
			this.pendingSeed.delete(path);
			// Merge what was on disk (possibly edited offline) into the now
			// server-backed doc, then mirror the merged state back to disk.
			await this.reconcileFromDisk(path);
			this.scheduleDiskWrite(path);
		}
		this.onReady(path);
	}

	private async onIndexSynced() {
		// Announce local files the server doesn't know about.
		for (const file of this.app.vault.getMarkdownFiles()) {
			if (!this.index.has(file.path)) {
				if (!this.docs.has(file.path)) await this.openFileDoc(file.path);
				this.setIndex(file.path, { deleted: false });
			}
		}
		// Materialize/apply everything the server knows.
		await this.onRemoteIndexChange([...this.index.keys()]);
	}

	private async onRemoteIndexChange(paths: string[]) {
		for (const path of paths) {
			const entry = this.index.get(path);
			if (!entry) continue;
			const file = this.app.vault.getAbstractFileByPath(normalizePath(path));
			if (!entry.deleted) {
				if (!this.docs.has(path)) await this.openFileDoc(path);
				if (!(file instanceof TFile)) await this.createFileAt(path, "");
			} else if (file instanceof TFile && this.docs.has(path)) {
				this.suppressed.add(path);
				try {
					// System trash, so a remote deletion is always recoverable.
					await this.app.vault.trash(file, true);
				} finally {
					this.suppressed.delete(path);
				}
			}
		}
	}

	private async reconcileFromDisk(path: string) {
		const managed = this.docs.get(path);
		const file = this.app.vault.getAbstractFileByPath(normalizePath(path));
		if (!managed || !(file instanceof TFile)) return;
		const diskContent = await this.app.vault.cachedRead(file);
		const ytext = managed.slot.doc.getText("content");
		if (ytext.toString() === diskContent) return;
		const d = simpleDiffString(ytext.toString(), diskContent);
		managed.slot.doc.transact(() => {
			ytext.delete(d.index, d.remove);
			ytext.insert(d.index, d.insert);
		}, DISK);
	}

	private scheduleDiskWrite(path: string) {
		const prev = this.writeTimers.get(path);
		if (prev) clearTimeout(prev);
		this.writeTimers.set(
			path,
			setTimeout(() => {
				this.writeTimers.delete(path);
				void this.writeToDisk(path);
			}, 400),
		);
	}

	private async writeToDisk(path: string) {
		const managed = this.docs.get(path);
		if (!managed || this.pendingSeed.has(path)) return;
		// Tombstoned docs still receive updates but must not reappear on disk,
		// and files open in an editor are written by the editor binding.
		if (!this.isAlive(path) || this.isFileOpen(path)) return;
		const content = managed.slot.doc.getText("content").toString();
		const file = this.app.vault.getAbstractFileByPath(normalizePath(path));
		if (file instanceof TFile) {
			await this.app.vault.process(file, (data) =>
				data === content ? data : content,
			);
		} else {
			await this.createFileAt(path, content);
		}
	}

	private async createFileAt(path: string, content: string) {
		this.suppressed.add(path);
		try {
			const parts = path.split("/").slice(0, -1);
			for (let i = 1; i <= parts.length; i++) {
				const dir = parts.slice(0, i).join("/");
				if (!(this.app.vault.getAbstractFileByPath(dir) instanceof TFolder)) {
					await this.app.vault.createFolder(dir).catch(() => {});
				}
			}
			await this.app.vault.create(path, content);
		} catch (e) {
			console.error(`oblivian: create ${path}:`, e);
		} finally {
			this.suppressed.delete(path);
		}
	}

	private isFileOpen(path: string): boolean {
		let open = false;
		this.app.workspace.iterateAllLeaves((leaf) => {
			const viewFile = (leaf.view as { file?: TFile }).file;
			if (viewFile?.path === path) open = true;
		});
		return open;
	}
}
