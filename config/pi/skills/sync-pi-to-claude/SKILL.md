---
name: sync-pi-to-claude
description: Mirror this machine's pi setup into Claude Code. Use when the user asks to sync pi skills and commands into Claude Code on this machine, or to check what Claude Code lacks.
---

# Sync pi to Claude

Mirror the pi setup into Claude Code on the same machine. The script links pi
skills and prompt files into the Claude Code config directory. Pi is the source.
Claude Code is the target.

This skill is the local counterpart of `sync-pi-setup`. That skill copies the pi
setup to a remote host. This skill mirrors it into `~/.claude`.

## Run a sync

```bash
S=~/.pi/agent/skills/sync-pi-to-claude/scripts/sync-pi-to-claude.sh
"$S" --dry-run     # report changes, change nothing
"$S"               # apply the changes
"$S" --prune       # apply, then remove stale managed links
```

Always run `--dry-run` first. Show the change list to the user. Then run the
real sync.

## Options

| Option | Effect |
|---|---|
| `-n, --dry-run` | Report changes. Change nothing. |
| `--prune` | Remove managed links that the manifest no longer lists. |
| `-v, --verbose` | Print every path. |
| `-h, --help` | Show help. |

## What syncs

The script reads `manifest.txt`. Each line has three pipe-separated fields.

| Field | Meaning |
|---|---|
| pi source | Directory on this machine. Contains skills or command files. |
| claude destination | Directory under `~/.claude`. The script creates it. |
| kind | `skill` links each subdirectory that holds `SKILL.md`. `command` links each `.md` file. |

The default manifest covers three sources.

- `~/.pi/agent/skills/` holds the pi skills, such as `hunk-review` and `sync-pi-setup`.
- `~/.agents/skills/` holds the shared agent skills, such as the caveman set.
- `~/.pi/agent/prompts/` holds the pi prompt files. The script links them as Claude Code commands.

## What stays out

Some pi state has no Claude Code equivalent. The sync skips it.

- `settings.json`, `models.json`, and `auth.json` use a pi-specific format.
- `extensions/*.ts` are pi extensions. Claude Code hooks use a different API.
- `pi-subagents` agent files use pi tool names. Claude Code agents use other names.
- `AGENTS.md` and `CLAUDE.md` differ on purpose. Each file names its own harness and workflow. The sync does not touch them.
- Skills that a Claude Code plugin already provides. See `exclude.txt`.

## Safety rules

The script never overwrites a real file or directory. It never removes a link
that it does not manage. A managed link points into a manifest source directory.

`--prune` removes a managed link when the manifest no longer lists it. It also
removes a link to a skill that you added to `exclude.txt`.

## Change the scope

Edit `manifest.txt` to add or remove a source. Add a skill name to
`exclude.txt` to skip that skill. A Claude Code plugin installs the names in
that file. A duplicate name makes Claude Code list one skill two times.

## Repo integration

The skill lives in `config/pi/skills/sync-pi-to-claude`. The `misc` setup step
links it into `~/.pi/agent/skills`. Run `just sync-claude` from the repo root.
