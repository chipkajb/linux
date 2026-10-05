# Contributing

This is a personal workstation repo, but the same conventions keep it
maintainable.

## Layout

- `bin/` — user-facing CLI tools, linked into `/usr/local/bin`.
- `lib/` — shared shell (`log.sh`, `common.sh`). Source, don't copy.
- `setup/` — one idempotent `step_<name>` per component.
- `config/` — dotfiles, symlinked into `$HOME`.
- `docs/` — documentation.

## Adding a setup step

1. Create `setup/<name>.sh` with a `step_<name>()` function.
2. Register it in the `STEPS` array in `setup.sh` (`name|label|function`).
3. Make it idempotent: guard clones with `clone_if_missing`, symlinks with
   `symlink_force`/`replace_with_symlink`, installs with `have <cmd>`.
4. Use `lib/log.sh` for output (`ui::step`, `ui::ok`, `ui::warn`, `ui::hint`) and
   `lib/common.sh` for helpers.

Steps run in a subshell with `set -e`; set the `PATH` you need at the top of the
function and don't rely on `cd`/exports leaking between steps.

## Shell style

- `set -euo pipefail` for standalone scripts.
- Prefer `have`, `require_cmd`, `clone_if_missing`, `symlink_force`.
- No secrets or machine-specific values in committed files — use the
  `*.example` templates.
- Add a `# shellcheck disable=SCXXXX` with a reason when a warning is intentional.

## Checks

```bash
just lint          # bash -n (+ shellcheck when installed)
pre-commit run --all-files
```

CI runs `bash -n`, `shellcheck -x`, and a CLI smoke test on every push and pull
request. Install shellcheck with `sudo apt install shellcheck` or the `misc`
setup step.
