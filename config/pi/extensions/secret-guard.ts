/**
 * secret-guard bridge for Pi.
 * Blocks tool calls that would print a secret, using the same guard script as the
 * Claude Code PreToolUse hook (`~/.local/bin/secret-guard`, from bin/ in this repo).
 * Fails closed: if the guard script is missing or crashes, the call is blocked.
 * The user's own `!` commands (user_bash) are not checked.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const GUARD = join(homedir(), ".local", "bin", "secret-guard");
const PATH_TOOLS = new Set(["read", "edit", "write", "grep", "find", "ls"]);

function check(mode: "bash" | "path", input: string): string | undefined {
	try {
		execFileSync(GUARD, [mode], { input, stdio: ["pipe", "ignore", "pipe"], timeout: 5000 });
		return undefined;
	} catch (err: any) {
		const reason = err?.stderr?.toString().trim();
		if (err?.status === 2 && reason) return reason;
		return `secret-guard: blocked because the guard script failed (${GUARD}). Fix it before continuing.`;
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event) => {
		const input = (event.input ?? {}) as Record<string, unknown>;
		let reason: string | undefined;
		if (event.toolName === "bash" && typeof input.command === "string") {
			reason = check("bash", input.command);
		} else if (PATH_TOOLS.has(event.toolName) && typeof input.path === "string") {
			reason = check("path", input.path);
		}
		return reason ? { block: true, reason } : undefined;
	});
}
