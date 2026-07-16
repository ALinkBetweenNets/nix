// Cross-language integration check: the plugin's MuxProvider (TS/Yjs) against
// the Rust server (yrs). Run via `npm test` — it builds the server if needed.
import { spawn, execSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert";
import * as Y from "yjs";
import { MuxProvider } from "../src/provider.ts";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const PORT = 19850;
const BASE = `http://127.0.0.1:${PORT}`;

async function until(cond, what, ms = 8000) {
	const start = Date.now();
	while (!(await cond())) {
		if (Date.now() - start > ms) throw new Error(`timeout waiting for ${what}`);
		await new Promise((r) => setTimeout(r, 50));
	}
}

execSync("cargo build -q", { cwd: join(root, "server"), stdio: "inherit" });
const dataDir = mkdtempSync(join(tmpdir(), "oblivian-it-"));
const server = spawn(join(root, "server/target/debug/oblivian-server"), [], {
	env: { ...process.env, OBLIVIAN_LISTEN: `127.0.0.1:${PORT}`, OBLIVIAN_DATA_DIR: dataDir },
	stdio: "inherit",
});

try {
	await until(
		() => fetch(BASE + "/vaults", { method: "OPTIONS" }).then(() => true).catch(() => false),
		"server to listen",
	);
	const res = await fetch(BASE + "/vaults", {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify({ id: "test", password: "pw" }),
	});
	assert.equal(res.status, 201, "vault created");

	const wsUrl = `ws://127.0.0.1:${PORT}/vault/test`;
	const docA = new Y.Doc();
	docA.getText("content").insert(0, "hello");
	const a = new MuxProvider(wsUrl, "pw");
	const slotA = a.addDoc("note.md", docA);
	a.connect();
	await until(() => slotA.synced, "A synced");

	const docB = new Y.Doc();
	const b = new MuxProvider(wsUrl, "pw");
	const slotB = b.addDoc("note.md", docB);
	b.connect();
	await until(() => slotB.synced, "B synced");
	await until(() => docB.getText("content").toString() === "hello", "B received A's text");

	// Live edits in both directions.
	docA.getText("content").insert(5, " world");
	await until(() => docB.getText("content").toString() === "hello world", "live A->B");
	docB.getText("content").insert(0, ">> ");
	await until(() => docA.getText("content").toString() === ">> hello world", "live B->A");

	// Cursor presence: A's awareness state reaches B.
	slotA.awareness.setLocalStateField("user", { name: "alice", color: "#f00" });
	await until(() => {
		for (const state of slotB.awareness.getStates().values()) {
			if (state.user?.name === "alice") return true;
		}
		return false;
	}, "awareness A->B");

	// Wrong password is rejected, no retry loop.
	const evil = new MuxProvider(wsUrl, "wrong");
	evil.addDoc("note.md", new Y.Doc());
	evil.connect();
	await until(() => evil.authFailed, "auth rejection");

	a.destroy();
	b.destroy();
	console.log("integration: all checks passed");
} finally {
	const exited = new Promise((r) => server.once("exit", r));
	server.kill();
	await exited; // let shutdown compaction finish before removing its dir
	rmSync(dataDir, { recursive: true, force: true });
}
