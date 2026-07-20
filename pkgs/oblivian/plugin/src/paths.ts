// Which vault-relative paths Oblivian syncs, and how. Kept free of obsidian
// imports so test/integration.mjs can import it directly under node.

/** The config dir (`.obsidian`) and everything under it. */
export function isConfig(path: string, configDir: string): boolean {
	return path === configDir || path.startsWith(`${configDir}/`);
}

/** Collaborative text (CRDT-merged, editor-bound). Everything else is a blob. */
export function isText(path: string, configDir: string): boolean {
	return !isConfig(path, configDir) && path.endsWith(".md");
}

/**
 * Whether a path participates in sync at all. Any file extension syncs, so
 * attachments work; hidden files/folders don't, except the config dir. The
 * config dir carries installed plugins/themes/snippets/settings — but never
 * Oblivian's own settings (they hold the vault password and are per-user) nor
 * per-device window layout.
 */
export function shouldSync(path: string, configDir: string): boolean {
	if (isConfig(path, configDir)) {
		if (path.startsWith(`${configDir}/plugins/oblivian/`)) return false;
		if (path === `${configDir}/workspace.json`) return false;
		if (path === `${configDir}/workspace-mobile.json`) return false;
		return true;
	}
	return !path.split("/").some((seg) => seg.startsWith("."));
}
