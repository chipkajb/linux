# jmux cheat sheet

Prefix on this machine: **`Ctrl-Space`**

jmux docs default to `Ctrl-a`. This repo uses `Ctrl-Space` via `config/tmux/tmux.conf`
plus `scripts/patch-jmux.sh` (also applied from `scripts/jmux-launch`).

Related files:

- `config/jmux/config.json` — jmux app settings
- `config/tmux/tmux.conf` — tmux binds loaded by jmux
- `scripts/jmux-launch` — rofi / i3 launcher
- `scripts/patch-jmux.sh` — Ctrl-Space prefix + cursor sync; reapply after `bun update -g @jx0/jmux`

---

## Sessions

| Key | Action |
|-----|--------|
| `Ctrl-Shift-Up/Down` | Prev / next session |
| `Ctrl-Space n` | New session / worktree |
| `Ctrl-Space r` | Rename session |
| `Ctrl-Space m` | Move window to another session |
| Click / scroll sidebar | Switch / scroll sessions |

## Windows

| Key | Action |
|-----|--------|
| Click toolbar tab | Switch window |
| `Ctrl-Space c` | New window |
| `Ctrl-Left/Right` | Prev / next window |
| `Ctrl-Shift-Left/Right` | Reorder windows |
| `Alt-H` / `Alt-L` | Prev / next window *(custom)* |

## Panes

| Key | Action |
|-----|--------|
| `Ctrl-Space \|` / `-` | Split horizontal / vertical |
| `Ctrl-Space v` / `;` | Split vertical / horizontal *(custom aliases)* |
| `Shift-Arrows` | Navigate panes |
| `Ctrl-h/j/k/l` | Navigate panes *(custom)* |
| `Ctrl-Space Arrows` | Resize panes |
| `Ctrl-Space z` | Zoom pane |

## Info / diff panel

| Key | Action |
|-----|--------|
| `Ctrl-Space g` | Toggle panel |
| `Ctrl-Space Tab` | Focus tmux ↔ panel |
| `Ctrl-Space z` | Zoom panel (when focused) |
| `Shift-Right/Left` | Focus panel / back to tmux |
| `[` / `]` | Cycle tabs (Diff / Issues / MRs / Review) |
| `↑` / `↓` | Navigate items |
| `o` | Open in browser |
| `n` | Start session from issue |
| `l` | Link to current session |
| `s` | Update issue status |
| `a` | Approve MR |
| `r` | Mark MR ready |
| `g` / `G` | Cycle group / sub-group |
| `/` | Filter |
| `S` / `?` | Cycle sort / toggle order |

## Command Center

| Key | Action |
|-----|--------|
| Sidebar **Command Center** | Open / close |
| `Ctrl-Space <n>` | Jump to tab N |
| `Ctrl-Space [` / `]` | Prev / next tab |
| Palette → Pin / Unpin / Move tile… | Manage pins & tabs |

## Utilities

| Key | Action |
|-----|--------|
| `Ctrl-Space p` | Command palette |
| `Ctrl-Space i` | Settings |
| `Ctrl-Space k` | Clear pane + scrollback |
| `Ctrl-Space y` | Copy pane to clipboard |
| `Ctrl-Space [` | Copy mode *(custom)* |

## Palette favorites (`Ctrl-Space p`)

- New / Kill / Rename session
- New / Rename / Close / Move window
- Split H / V · Zoom / Close pane
- Open Claude
- Toggle / Zoom diff
- Pin to Command Center
- Link / Unlink issue or MR · New Issue
- Settings

---

## CLI

```bash
jmux [session] [-L socket] [--demo] [--install-agent-hooks]

jmux ctl session list|create|info|switch|kill|rename|attention
jmux ctl window  list|create|select|kill
jmux ctl pane    list|split|send-keys|capture|kill|pin|unpin|pinned
jmux ctl run-claude --name <n> --dir <path> [--message "..."]
jmux ctl agent   state|watch [--all]
jmux ctl issue   get|link|unlink|start
jmux ctl status
jmux ctl cc tabs
```

### Useful examples

```bash
# rename current / named session
jmux ctl session rename --target my-session --name better-name

# launch Claude in a new session
jmux ctl run-claude --name fix-auth --dir ~/workspace/playbook --message "Fix auth"

# capture another pane
jmux ctl pane capture --target %12

# send keys to a pane
jmux ctl pane send-keys --target %12 "continue" --enter
```

---

## Launch

| How | Command / binding |
|-----|-------------------|
| Shell | `jmux` or `jm` |
| i3 | `Mod+Shift+t` |
| Rofi | `jmux` desktop entry |

---

## Notes

- `windowBranches` is off in `config.json` — avoids a jmux cursor off-by-one when the toolbar is 2 rows tall.
- `scripts/patch-jmux.sh` fixes cursor drift and keeps palette / diff panel working when the
  window is under 80 cols (sidebar hidden). Re-run after `bun update -g @jx0/jmux`.
- After upgrading jmux, relaunch via `jmux-launch` (or run `scripts/patch-jmux.sh`) so local fixes stay applied.
