import { Notice, Plugin, TFile } from "obsidian";
import { Compartment } from "@codemirror/state";
import { Engine } from "./engine";
import { EditorBinder } from "./editor-binding";
import {
	DEFAULT_SETTINGS,
	OblivianSettings,
	OblivianSettingTab,
} from "./settings";

export default class OblivianPlugin extends Plugin {
	settings!: OblivianSettings;
	private engine: Engine | null = null;
	private binder: EditorBinder | null = null;
	private statusBar!: HTMLElement;
	// One compartment for all editors, registered once: Obsidian keeps it in
	// every editor config rebuild, unlike appendConfig-injected extensions.
	private editorCompartment = new Compartment();

	async onload() {
		this.settings = Object.assign({}, DEFAULT_SETTINGS, await this.loadData());
		this.addSettingTab(new OblivianSettingTab(this.app, this));
		this.registerEditorExtension(this.editorCompartment.of([]));
		this.statusBar = this.addStatusBarItem();
		this.setStatus("off");
		this.app.workspace.onLayoutReady(() => void this.startSync());
	}

	onunload() {
		this.stopSync();
	}

	async saveSettings() {
		await this.saveData(this.settings);
	}

	async restartSync() {
		this.stopSync();
		await this.startSync();
	}

	private configured(): boolean {
		const s = this.settings;
		return s.enabled && !!s.serverUrl && !!s.vaultId && !!s.password;
	}

	private async startSync() {
		if (!this.configured() || this.engine) return;
		const engine = new Engine(this.app, this.settings);
		const binder = new EditorBinder(this.app, engine, this.editorCompartment, {
			name: this.settings.userName || "anonymous",
			color: this.settings.userColor,
			colorLight: this.settings.userColor + "33",
		});
		this.engine = engine;
		this.binder = binder;
		engine.isBound = (path) => binder.isBound(path);

		engine.provider.onStatus = (s) => {
			this.setStatus(s);
			if (engine.provider.authFailed) {
				new Notice("Oblivian: server rejected the vault password");
			}
		};
		engine.onReady = () => binder.refresh();

		try {
			await engine.start();
		} catch (e) {
			console.error("oblivian: start failed", e);
			new Notice(`Oblivian: failed to start sync: ${e}`);
			this.stopSync();
			return;
		}

		// registerEvent only detaches on plugin unload; after restartSync the
		// old closures still fire, so gate them on being the current engine.
		const active = () => this.engine === engine;
		this.registerEvent(
			this.app.vault.on("create", (f) => {
				if (active() && f instanceof TFile && f.extension === "md")
					void engine.onLocalCreate(f);
			}),
		);
		this.registerEvent(
			this.app.vault.on("delete", (f) => {
				if (active() && f instanceof TFile && f.extension === "md")
					engine.onLocalDelete(f.path);
			}),
		);
		this.registerEvent(
			this.app.vault.on("rename", (f, oldPath) => {
				if (active() && f instanceof TFile) void engine.onLocalRename(f, oldPath);
			}),
		);
		this.registerEvent(
			this.app.vault.on("modify", (f) => {
				if (active() && f instanceof TFile && f.extension === "md")
					void engine.onLocalModify(f);
			}),
		);
		this.registerEvent(
			this.app.workspace.on("active-leaf-change", () => active() && binder.refresh()),
		);
		this.registerEvent(
			this.app.workspace.on("layout-change", () => active() && binder.refresh()),
		);
		this.registerEvent(
			this.app.workspace.on("file-open", () => active() && binder.refresh()),
		);
		// Self-heal: an editor config rebuild silently drops the binding and
		// fires no event we can hook, so re-check attachment periodically.
		this.registerInterval(
			window.setInterval(() => active() && binder.refresh(), 2000),
		);
		binder.refresh();
	}

	private stopSync() {
		this.binder?.unbindAll();
		this.engine?.stop();
		this.engine = null;
		this.binder = null;
		this.setStatus("off");
	}

	private setStatus(s: string) {
		const icon = { connected: "🟢", connecting: "🟡", offline: "🔴", off: "⚪" }[
			s
		];
		this.statusBar.setText(`${icon ?? ""} oblivian`);
		this.statusBar.setAttribute("aria-label", `Oblivian sync: ${s}`);
	}
}
