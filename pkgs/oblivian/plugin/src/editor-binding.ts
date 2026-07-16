import { App, MarkdownView } from "obsidian";
import { Compartment, Extension } from "@codemirror/state";
import type { EditorView } from "@codemirror/view";
import { yCollab } from "y-codemirror.next";
import { Engine } from "./engine";

interface Attached {
	path: string;
	ext: Extension;
}

/**
 * Attaches yCollab (live sync + remote cursors) to every markdown editor
 * showing a synced file.
 *
 * The compartment is registered globally via registerEditorExtension (done in
 * main.ts), NOT injected with StateEffect.appendConfig: Obsidian rebuilds
 * editor configs from the registered extension list on workspace
 * .updateOptions() (any plugin load / settings change), which silently drops
 * appended configs. A rebuild resets the compartment to [], so refresh() also
 * runs on an interval and re-attaches whenever the binding went missing.
 */
export class EditorBinder {
	private attached = new Map<EditorView, Attached>();

	constructor(
		private app: App,
		private engine: Engine,
		private compartment: Compartment,
		private user: { name: string; color: string; colorLight: string },
	) {}

	refresh() {
		for (const [cm] of this.attached) {
			if (!cm.dom.isConnected) this.attached.delete(cm);
		}
		for (const leaf of this.app.workspace.getLeavesOfType("markdown")) {
			const view = leaf.view as MarkdownView;
			const cm = (view.editor as unknown as { cm?: EditorView }).cm;
			if (!cm) continue;
			const path = view.file?.path ?? null;
			const record = this.attached.get(cm);
			// The binding is live only if the compartment still holds our
			// extension; a config rebuild resets it without any event.
			const live =
				record !== undefined && this.compartment.get(cm.state) === record.ext;
			const wanted =
				path !== null &&
				this.engine.isReady(path) &&
				this.engine.isAlive(path);
			if (wanted && live && record!.path === path) continue;
			if (!wanted && !live) {
				this.attached.delete(cm);
				continue;
			}
			if (live && record!.path !== path) this.clearCursor(record!.path);
			if (wanted && path) {
				this.attach(cm, path);
			} else {
				cm.dispatch({ effects: this.compartment.reconfigure([]) });
				this.attached.delete(cm);
			}
		}
	}

	isBound(path: string): boolean {
		for (const [cm, record] of this.attached) {
			if (
				record.path === path &&
				cm.dom.isConnected &&
				this.compartment.get(cm.state) === record.ext
			) {
				return true;
			}
		}
		return false;
	}

	unbindAll() {
		for (const [cm, record] of this.attached) {
			this.clearCursor(record.path);
			if (cm.dom.isConnected) {
				cm.dispatch({ effects: this.compartment.reconfigure([]) });
			}
		}
		this.attached.clear();
	}

	private attach(cm: EditorView, path: string) {
		const slot = this.engine.getSlot(path);
		if (!slot) return;
		const ytext = slot.doc.getText("content");
		slot.awareness.setLocalStateField("user", this.user);
		// yCollab assumes editor text and Y.Text are identical at attach time;
		// the Y.Doc is the source of truth.
		const content = ytext.toString();
		if (cm.state.doc.toString() !== content) {
			cm.dispatch({
				changes: { from: 0, to: cm.state.doc.length, insert: content },
			});
		}
		const ext = yCollab(ytext, slot.awareness);
		cm.dispatch({ effects: this.compartment.reconfigure(ext) });
		this.attached.set(cm, { path, ext });
	}

	private clearCursor(path: string) {
		this.engine.getSlot(path)?.awareness.setLocalStateField("cursor", null);
	}
}
