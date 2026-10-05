# Installation

`setup.sh` targets a fresh Ubuntu 22.04 (jammy) or 24.04 (noble) install. It
detects the release, installs packages with `apt`, and symlinks configuration
out of this repository into `$HOME`.

## 1. Bootstrap

```bash
sudo apt update && sudo apt upgrade
mkdir -p ~/workspace
sudo apt install git curl
```

Add an SSH key for the new machine:

```bash
cd ~/.ssh && ssh-keygen
# paste ~/.ssh/id_*.pub at https://github.com/settings/keys
```

Clone the repository into `~/workspace`:

```bash
cd ~/workspace && git clone git@github.com:chipkajb/linux.git
```

## 2. Run setup

```bash
cd ~/workspace/linux
./setup.sh
```

The interactive menu lists each step; enter a number, a step name, `all`, or `0`
to exit. Every step is idempotent — re-running is safe.

Non-interactive:

```bash
./setup.sh list
./setup.sh install zsh vim neovim
./setup.sh all
```

Or via `just`:

```bash
just install i3 monitors
just all
```

## Steps

| Step | What it does |
| --- | --- |
| `links` | Symlinks `bin/*` into `/usr/local/bin` |
| `zsh` | zsh, oh-my-zsh + plugins, rustup/eza, starship, zoxide, atuin, uv |
| `vim` | vim + Vundle plugins, `libclang` |
| `neovim` | NvChad, LSP (mason), treesitter, git mergetool |
| `vscode` | VS Code from the Microsoft apt repo + extensions |
| `tmux` | tmux + TPM, OSC 52 clipboard helper |
| `i3` | i3, i3blocks, rofi (built from source), dunst, picom, GTK theme |
| `alacritty` | alacritty + color themes |
| `monitors` | Generates the i3 monitor include (see [monitors.md](monitors.md)) |
| `misc` | CLI tools, fff-mcp, Hunk, gedit vim-mode, shellcheck, pre-commit |
| `claude` | Claude Code + `~/.claude` config, shared agent skills |
| `adlc` | herdr, caveman, superpowers |

`i3` also runs `monitors` so a fresh host always has a valid display include.

## Apps installed outside setup.sh

These are installed manually (licences, proprietary builds, or app stores):

- [Slack](https://snapcraft.io/slack)
- [Cursor](https://cursor.com/)
- [MongoDB Compass](https://www.mongodb.com/try/download/compass)
- [Obsidian](https://obsidian.md/download)
- [Pithos](https://ubuntuhandbook.org/index.php/2024/03/pithos-pandora-radio-client-released-1-6-2/) — use Option 2:

  ```bash
  sudo add-apt-repository ppa:ubuntuhandbook1/apps
  sudo apt update && sudo apt install pithos
  ```

- [Blender](https://docs.blender.org/manual/en/latest/getting_started/installing/linux.html)
- [Zoom](https://zoom.us/download)
- [VLC](https://www.videolan.org/vlc/download-ubuntu.html)

## Python

`uv` replaces Anaconda and pipx:

```bash
uv python install 3.12       # managed interpreter
uv venv && source .venv/bin/activate
uv tool install ruff         # global CLI tools
```

## Agent skills

Skills live in `config/claude/skills/<name>` and are linked into
`~/.claude/skills/<name>`. A skill that both agents should read is also linked
into `~/.pi/agent/skills/<name>` from the same copy, so the two never drift —
see `SHARED_SKILLS` in `setup/claude.sh`.

`asd-ste100` ([danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill),
MIT) rewrites ambiguous English into ASD-STE100 Simplified Technical English. It
ships a stdlib-only linter:

```bash
python3 ~/.claude/skills/asd-ste100/scripts/ste-lint.py FILE [--json]
```

## Hunk diff review

[Hunk](https://github.com/modem-dev/hunk) is a terminal diff reviewer with watch
mode and inline agent rationale. It is installed by the `misc` step.

```bash
hunk-review              # working tree, live watch
hunk-review --staged     # staged changes only
hunk-review show HEAD~1  # review a commit
```

If `.hunk/agent-context.json` exists, `hunk-review` attaches it automatically, so
per-file/per-hunk notes and rationale render inline. Agents write that sidecar
with `hunk-context write` (schema in `bin/hunk-context`); `hunk-context reload`
re-reads a live session after new edits. The sidecar is gitignored — it is
per-changeset, not committed. `pi` picks up the matching `hunk-review` skill from
`config/pi/skills/hunk-review` (linked into `~/.pi/agent/skills`).

Hunk is review-only — it cannot stage or revert. Do that in Neovim with gitsigns:

```
]c / [c          next / prev hunk
<leader>ga        stage hunk (or visual range = selected lines)
<leader>gr        reset hunk (or visual range = selected lines)
<leader>gA / gR   stage / reset whole buffer
<leader>gU        undo last staged hunk
<leader>gp        preview hunk      <leader>gb  blame line
```

## CUDA

See [cuda.md](cuda.md) for the toolkit install and
[nvidia-drivers.md](nvidia-drivers.md) for a complete driver removal.
