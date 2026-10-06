---
name: sync-pi-setup
description: Mirror this machine's Pi setup to a remote server over rsync. Use when the user asks to sync or copy their Pi configuration to another host, or to add a mirror target.
---

# Sync Pi setup

Mirror `~/.pi` and its companion paths to remote hosts. The transfer uses rsync over SSH.

## Run a sync

```bash
S=~/.pi/agent/skills/sync-pi-setup/scripts/sync-pi-setup.sh
"$S" --dry-run          # report changes, transfer nothing
"$S"                    # sync the default targets
"$S" myhost --post      # one host, then install Pi there
"$S" --list-targets     # show the target file and candidate hosts
```

Always run `--dry-run` first on a new host. Show the change list to the user. Then run the real sync.

## Options

| Option | Effect |
|---|---|
| `-t, --target HOST` | Add a target. Repeatable. |
| `-a, --all-hosts` | Use every concrete `Host` alias in `~/.ssh/config`. |
| `--list-targets` | Print the target file, its hosts, and all ssh hosts. |
| `-n, --dry-run` | Report changes. Transfer nothing. |
| `--no-delete` | Keep remote files that are missing locally. |
| `--post` | Install the local Pi version on each target with npm. |
| `-v, --verbose` | Print each transferred path. |

Targets are ssh host aliases. The host must exist in `~/.ssh/config`. Pass a host on the command line for a one-off sync.

## Add a target

Add the host alias to `targets.local.txt`. Nothing else changes.

This skill lives in a public repo. Real host names belong in `targets.local.txt`, which git ignores. Keep `targets.txt` free of real names.

## Change what syncs

Edit `manifest.txt`. Each line has three pipe-separated fields.

| Field | Meaning |
|---|---|
| local path | Absolute path, or `~/...` on this machine |
| remote path | Path relative to the remote home directory |
| extra flags | Optional rsync flags, for example `-L` |

Directories need a trailing slash. Add patterns to `excludes.txt` for state that must not transfer.

| File | Purpose |
|---|---|
| `manifest.txt` | Paths to sync. Tracked in git. |
| `excludes.txt` | Protected paths. Tracked in git. |
| `targets.txt` | Example hosts only. Tracked in git. |
| `targets.local.txt` | Your real hosts. Gitignored. |

## What syncs

- Pi config: `settings.json`, `AGENTS.md`, `models.json`, `auth.json`, MCP config, `trust.json`
- Pi content: `extensions/`, `prompts/`, `skills/`, `pi-subagents/`, `npm/` packages
- Companion paths that `settings.json` references: `~/.agents/skills/`, `~/workspace/adlc/plugins/`

## What stays local

Sessions, missions, run history, caches, and `backup.*` directories. The `excludes.txt` file protects them from transfer and from `--delete`.

## Notes

- `auth.json` holds credentials. The file keeps mode 600 after transfer.
- The `~/.pi/agent/` entry uses `-L`. Remote hosts get real skill files. They do not need `~/workspace/linux`.
- `--delete` removes remote files that no longer exist locally. It removes stale files from older Pi versions, for example a legacy `mcp.json`.
- `--post` reads the local Pi version and installs that exact version on the target.
- The sync does not carry `~/workspace/linux` or `~/.claude`. Add a manifest row if a target needs them.
- The script reads `targets.local.txt` when that file exists. Otherwise it reads `targets.txt`. Command-line hosts always work.
