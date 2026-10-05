# Architecture

This repository is a *source of truth* for dotfiles and a *set of installers*.
Nothing is copied into place that can be symlinked, and nothing is symlinked that
holds secrets or machine-specific state.

## Layout

```
setup.sh            entrypoint: menu + CLI, sources everything below
justfile            dev tasks (lint, fmt, setup, monitors)
bin/                CLI tools, linked into /usr/local/bin
lib/
  log.sh            colored output (honors NO_COLOR, non-TTY)
  common.sh         shared helpers (run_step, link_bin, symlink helpers)
setup/
  00-preflight.sh   Ubuntu detection, apt helpers, install_uv
  10-links.sh       link bin/* into /usr/local/bin
  <component>.sh    one idempotent step per component
config/             dotfiles, symlinked into $HOME
  i3/monitors/      monitor profiles (office, home, laptop)
assets/             background, fonts, icons
docs/               documentation
```

## The symlink model

`config/<app>` is symlinked to `~/.config/<app>` (or the appropriate dotfile
path). The repository is never modified by a running application. Two categories
of state stay outside the repo:

- **Secrets** — `~/.zsh_secrets` (template `config/zsh_secrets.example`).
- **Host-specific config** — `config/zsh_local` → `~/.zsh_local`,
  `config/i3/config.local` → `~/.i3_local`. These are gitignored; only
  `*.example` templates are committed.

`~/.i3_monitors` is *generated* by `bin/i3-monitors` and also lives outside the
repo, so `~/.config/i3` can remain a clean symlink to `config/i3`.

## Setup steps

Each file in `setup/` defines a `step_<name>` function. `setup.sh` registers the
steps in `STEPS` (`name|label|function`) and dispatches to them by name,
number, or via `all`.

`run_step` executes a step in a subshell with `set -e`:

```bash
run_step() {
    local label="$1"; shift
    ui::step "$label"
    local rc=0
    ( set -euo pipefail; "$@" ) || rc=$?
    ...
}
```

The subshell gives two properties:

1. A failure aborts the step but not the program, so one broken component does
   not block the rest.
2. `cd` and `export` are isolated between steps. Every step sets the `PATH` it
   needs (`$HOME/.cargo/bin`, `$HOME/.local/bin`), which also makes steps
   independent and re-runnable.

## Monitor role indirection

i3 assigns workspaces to roles (`$monitor_left`, …). `i3-monitors` writes those
variables for the active profile and restarts i3 only when the generated include
actually changes. See [monitors.md](monitors.md).

## Adding a component

1. Add `setup/<component>.sh` with a `step_<component>` function.
2. Register it in the `STEPS` array in `setup.sh`.
3. If it installs CLI tools, put them in `bin/` — `link_bin` publishes them.
4. Run `just lint`.
