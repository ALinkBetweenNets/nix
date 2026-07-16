import { App, Notice, PluginSettingTab, Setting, requestUrl } from "obsidian";
import type OblivianPlugin from "./main";

export interface OblivianSettings {
	serverUrl: string;
	vaultId: string;
	password: string;
	userName: string;
	userColor: string;
	enabled: boolean;
}

export const DEFAULT_SETTINGS: OblivianSettings = {
	serverUrl: "",
	vaultId: "",
	password: "",
	userName: "",
	userColor: "#3b82f6",
	enabled: false,
};

export class OblivianSettingTab extends PluginSettingTab {
	constructor(
		app: App,
		private plugin: OblivianPlugin,
	) {
		super(app, plugin);
	}

	display() {
		const { containerEl } = this;
		containerEl.empty();
		const s = this.plugin.settings;

		new Setting(containerEl)
			.setName("Server URL")
			.setDesc("The Oblivian server, e.g. http://myhost.tailnet.ts.net:9850")
			.addText((t) =>
				t.setValue(s.serverUrl).onChange(async (v) => {
					s.serverUrl = v.trim();
					await this.plugin.saveSettings();
				}),
			);
		new Setting(containerEl)
			.setName("Vault ID")
			.setDesc("Shared identifier of this vault on the server")
			.addText((t) =>
				t.setValue(s.vaultId).onChange(async (v) => {
					s.vaultId = v.trim();
					await this.plugin.saveSettings();
				}),
			);
		new Setting(containerEl).setName("Vault password").addText((t) => {
			t.inputEl.type = "password";
			t.setValue(s.password).onChange(async (v) => {
				s.password = v;
				await this.plugin.saveSettings();
			});
		});
		new Setting(containerEl)
			.setName("Your name")
			.setDesc("Shown at your cursor to collaborators")
			.addText((t) =>
				t.setValue(s.userName).onChange(async (v) => {
					s.userName = v;
					await this.plugin.saveSettings();
				}),
			);
		new Setting(containerEl).setName("Your cursor color").addColorPicker((c) =>
			c.setValue(s.userColor).onChange(async (v) => {
				s.userColor = v;
				await this.plugin.saveSettings();
			}),
		);

		new Setting(containerEl)
			.setName("Enable sync")
			.setDesc("Connect this vault to the server (restarts the sync engine)")
			.addToggle((t) =>
				t.setValue(s.enabled).onChange(async (v) => {
					s.enabled = v;
					await this.plugin.saveSettings();
					await this.plugin.restartSync();
				}),
			);

		new Setting(containerEl)
			.setName("Create vault on server")
			.setDesc(
				"Registers the vault ID above with the password above. Whoever creates the vault is its host: share the password to grant access, rotate it to revoke.",
			)
			.addButton((b) =>
				b.setButtonText("Create").onClick(async () => {
					try {
						const res = await requestUrl({
							url: `${s.serverUrl.replace(/\/+$/, "")}/vaults`,
							method: "POST",
							contentType: "application/json",
							body: JSON.stringify({ id: s.vaultId, password: s.password }),
							throw: false,
						});
						if (res.status === 201) new Notice("Oblivian: vault created");
						else if (res.status === 409)
							new Notice("Oblivian: vault already exists");
						else new Notice(`Oblivian: server said ${res.status}`);
					} catch (e) {
						new Notice(`Oblivian: ${e}`);
					}
				}),
			);

		new Setting(containerEl)
			.setName("Rotate password")
			.setDesc(
				"Host only: set a new password (enter it in the field below first). Cuts off everyone using the old one.",
			)
			.addText((t) => {
				t.inputEl.type = "password";
				t.setPlaceholder("new password");
				t.onChange(() => {});
				this.newPassword = t;
			})
			.addButton((b) =>
				b.setButtonText("Rotate").onClick(async () => {
					const newPassword = this.newPassword?.getValue() ?? "";
					if (!newPassword) {
						new Notice("Oblivian: enter a new password first");
						return;
					}
					try {
						const res = await requestUrl({
							url: `${s.serverUrl.replace(/\/+$/, "")}/vaults/${s.vaultId}/password`,
							method: "POST",
							contentType: "application/json",
							body: JSON.stringify({
								password: s.password,
								new_password: newPassword,
							}),
							throw: false,
						});
						if (res.status === 204) {
							s.password = newPassword;
							await this.plugin.saveSettings();
							await this.plugin.restartSync();
							new Notice("Oblivian: password rotated");
						} else new Notice(`Oblivian: server said ${res.status}`);
					} catch (e) {
						new Notice(`Oblivian: ${e}`);
					}
				}),
			);
	}

	private newPassword?: { getValue(): string };
}
