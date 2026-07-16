import { App, MarkdownView } from "obsidian";
import { Compartment, StateEffect } from "@codemirror/state";
import type { EditorView } from "@codemirror/view";
import { yCollab } from "y-codemirror.next";
import { Engine } from "./engine";

interface Binding {
	path: string | null;
	compartment: Compartment;
}

/**
 * Attaches yCollab (live sync + remote cursors) to every markdown editor
 * showing a synced file. Obsidian has no per-file extension hook, so we
 * inject a Compartment into each editor once and reconfigure it as the
 * displayed file changes.
 */
export class EditorBinder {
	private bindings = new Map<EditorView, Binding>();

	constructor(
		private app: App,
		private engine: Engine,
		private user: { name: string; color: string; colorLight: string },
	) {}

	refresh() {
		for (const [cm] of this.bindings) {
			if (!cm.dom.isConnected) this.bindings.delete(cm);
		}
		for (const leaf of this.app.workspace.getLeavesOfType("markdown")) {
			const view = leaf.view as MarkdownView;
			const cm = (view.editor as unknown as { cm?: EditorView }).cm;
			if (!cm) continue;
			const path = view.file?.path ?? null;
			const binding = this.bindings.get(cm);
			if (binding?.path === path) continue;
			if (binding?.path) this.detach(cm, binding);
			if (path && this.engine.isReady(path) && this.engine.isAlive(path)) {
				this.attach(cm, path);
			}
		}
	}

	unbindAll() {
		for (const [cm, binding] of this.bindings) {
			if (binding.path && cm.dom.isConnected) this.detach(cm, binding);
		}
		this.bindings.clear();
	}

	private getBinding(cm: EditorView): Binding {
		let binding = this.bindings.get(cm);
		if (!binding) {
			binding = { path: null, compartment: new Compartment() };
			cm.dispatch({
				effects: StateEffect.appendConfig.of(binding.compartment.of([])),
			});
			this.bindings.set(cm, binding);
		}
		return binding;
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
		const binding = this.getBinding(cm);
		binding.path = path;
		cm.dispatch({
			effects: binding.compartment.reconfigure(yCollab(ytext, slot.awareness)),
		});
	}

	private detach(cm: EditorView, binding: Binding) {
		if (binding.path) {
			this.engine
				.getSlot(binding.path)
				?.awareness.setLocalStateField("cursor", null);
		}
		binding.path = null;
		cm.dispatch({ effects: binding.compartment.reconfigure([]) });
	}
}
