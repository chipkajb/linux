# linux

[![lint](https://github.com/chipkajb/linux/actions/workflows/lint.yml/badge.svg)](https://github.com/chipkajb/linux/actions/workflows/lint.yml)

Personal Ubuntu workstation setup — i3 desktop, dotfiles, CLI tooling, and agent
configuration. Everything is installed by an idempotent, modular `setup.sh` and
symlinked out of this repository, so a step can be re-run at any time without
breaking an existing machine.

- **Ubuntu 22.04 (jammy) and 24.04 (noble)** are supported and detected at runtime.
- **Idempotent**: every step guards its clones, installs, and symlinks.
- **Modular**: each component is a small step in `setup/` with a name you can run
  on its own.
- **Role-based monitors**: the same apps land on the same physical monitor in
  every setup — office, home, or laptop-only.

## Quick start

```bash
git clone git@github.com:chipkajb/linux.git ~/workspace/linux
cd ~/workspace/linux
./setup.sh                 # interactive menu
```

Prefer the CLI:

```bash
./setup.sh list                 # list steps
./setup.sh install zsh i3       # run specific steps
./setup.sh all                  # run everything
./setup.sh install monitors     # just the display profiles
```

With [`just`](https://github.com/casey/just):

```bash
just                       # list recipes
just install i3 monitors
just lint
just monitors
```

## What's included

| Area | Steps |
| --- | --- |
| Shell | `zsh` — oh-my-zsh, starship, zoxide, atuin, uv, eza |
| Editors | `vim` (Vundle), `neovim` (NvChad + LSP/treesitter), `vscode` |
| Terminal | `alacritty`, `tmux` + TPM, OSC 52 clipboard |
| Desktop | `i3` — rofi, dunst, picom, i3blocks, GTK dark theme |
| Displays | `monitors` — office / home / laptop profiles |
| Agent tooling | `claude`, `adlc` (herdr, caveman, superpowers), `misc` (Hunk, fff-mcp) |

## Monitor profiles

The i3 config binds each workspace to a semantic **role** — `left`, `middle`,
`right`, `bottom` — instead of a physical output. `i3-monitors` writes those role
mappings for the active profile, so switching between desks keeps the same apps
on the same monitors.

```bash
i3-monitors                 # pick a profile with rofi
i3-monitors list            # list profiles
i3-monitors status          # active profile + connected outputs
i3-monitors home            # switch profile
i3-monitors auto            # detect from connected outputs
```

Or press **`Super+Shift+m`**. Add your own profile by dropping a file in
`config/i3/monitors/` — see [docs/monitors.md](docs/monitors.md).

## Repository layout

```
.
├── setup.sh              # entrypoint: interactive menu + CLI
├── justfile              # dev tasks (lint, fmt, setup, monitors)
├── bin/                  # CLI tools, linked into /usr/local/bin
├── lib/                  # shared shell: log.sh (output), common.sh (helpers)
├── setup/                # one module per component, idempotent
├── config/               # dotfiles, symlinked into $HOME
│   └── i3/monitors/      # office.sh, home.sh, laptop.sh
├── assets/               # background, fonts, icons
└── docs/                 # installation, monitors, keybindings, …
```

## Documentation

- [Installation](docs/installation.md) — prerequisites, per-step detail, apps
  installed outside `setup.sh`
- [Monitor profiles](docs/monitors.md) — roles, adding a desk, troubleshooting
- [Keybindings](docs/keybindings.md) — i3 reference (also `Super+i`)
- [Architecture](docs/architecture.md) — how the repo, symlinks, and steps fit
- [Troubleshooting](docs/troubleshooting.md)
- [CUDA toolkit](docs/cuda.md) · [NVIDIA driver removal](docs/nvidia-drivers.md)

## Development

```bash
just lint                 # bash -n + shellcheck
uv tool install pre-commit && pre-commit install
```

CI runs shellcheck and a CLI smoke test on every push and pull request.

## Notes

- Machine-specific config is gitignored: `config/zsh_local` (→ `~/.zsh_local`),
  `config/i3/config.local` (→ `~/.i3_local`), and credentials in
  `~/.zsh_secrets`. Templates are committed as `*.example`.
- `config/vscode/settings.json` is symlinked into the editor's user settings, so
  the editor writes back to it. A clean filter drops the ssh host alias map
  before content reaches git, because those aliases are local state and not
  config. Run `config/vscode/setup-git-filter.sh` once per machine. Without the
  filter, `git add` commits your host aliases.
