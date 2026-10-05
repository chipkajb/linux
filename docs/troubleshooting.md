# Troubleshooting

## Setup

**`apt` complains about duplicate VS Code sources.**
An old `vscode.list` and the `code` package's `vscode.sources` point at the same
repo with different keyrings. `setup.sh` removes the stale list on every run
(`fix_vscode_apt_sources`); to fix it manually:

```bash
sudo rm -f /etc/apt/sources.list.d/vscode.list
```

**rofi build fails.**
The build needs the XCB/glib/pango dev packages installed by the `i3` step. Run
`./setup.sh install i3` first. rofi is built into `~/software/rofi-1.7.5` and
skipped when the same version is already installed.

**`tree-sitter` fails on Ubuntu 22.04.**
The upstream binary needs glibc 2.39. The installer falls back to building from
source with `cargo`; install the `zsh` step first so rustup is present.

**A step reports `unknown step`.**
Run `./setup.sh list` for the valid names.

## Monitors

**i3 starts with an error about `~/.i3_monitors`.**
The generated include is missing. Run `i3-monitors auto` (or
`i3-monitors generate office`), then reload i3 (`Super+Shift+c`).

**Switching profiles doesn't move my windows.**
The include changed but i3 was not restarted. Run `i3-msg restart`, or re-run
`i3-monitors <profile>` with `DISPLAY` set. If it still fails, check that
`~/.i3_monitors` contains the expected output names.

**The wrong profile is auto-detected.**
`i3-monitors status` prints the connected outputs. Compare them with the
`OUTPUT_*` values in `config/i3/monitors/*.sh` and adjust `PROFILE_ORDER` in
`bin/i3-monitors` if needed.

## Desktop

**Notifications open the wrong workspace.**
`bin/i3-notification-workspace.sh` maps apps to workspace *numbers*, and the
names live in `config/i3/config`. If you rename a workspace, only the config
needs to change.

**`i3-monitors: command not found`.**
Run `./setup.sh install links` (or `zsh`/`i3`) to symlink `bin/*` into
`/usr/local/bin`.

**Terminal apps can't paste from the system clipboard over SSH/Herdr.**
`bin/osc52-copy` writes OSC 52 to the focused pane. Ensure it is on `PATH`
(`link_bin`) and that the terminal supports OSC 52.

## Development

**`just lint` fails on a shell file.**
Install shellcheck (`sudo apt install shellcheck` or the `misc` step) to see the
same warnings as CI:

```bash
uv tool run --from shellcheck-py shellcheck -x setup.sh lib/*.sh setup/*.sh bin/*
```

**Hunk sidecar is stale.**
`hunk-context clear` removes `.hunk/agent-context.json`; it is regenerated per
changeset.
