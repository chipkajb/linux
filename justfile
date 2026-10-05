# Linux dotfiles — task runner
#
#   just              list recipes
#   just setup        interactive setup menu
#   just install i3 monitors
#   just lint
#   just monitors     show the active monitor profile

set shell := ["bash", "-euo", "pipefail", "-c"]

# list available recipes
default:
    @just --list

# interactive setup menu
setup:
    ./setup.sh

# list setup steps
steps:
    ./setup.sh list

# run one or more setup steps:  just install zsh i3 monitors
install *steps:
    ./setup.sh install {{steps}}

# run every setup step
all:
    ./setup.sh all

# lint shell: syntax check + shellcheck (when installed). Discovers every shell
# file in the repo (tracked + untracked, ignoring vendored dirs) so it matches
# what pre-commit's shellcheck hook checks.
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    status=0
    mapfile -t files < <(
        {
            git ls-files --cached --others --exclude-standard -z |
                xargs -0 grep -Il -m1 -E '^#!.*(bash|/sh| sh)' 2>/dev/null || true
            git ls-files --cached --others --exclude-standard '*.sh' '*.bash'
        } | sort -u
    )
    printf '  linting %d shell files\n' "${#files[@]}"
    for file in "${files[@]}"; do
        bash -n "$file" || status=1
        if command -v shellcheck >/dev/null 2>&1; then
            shellcheck -x "$file" || status=1
        fi
    done
    exit "$status"

# format shell with shfmt (if installed)
fmt:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shfmt >/dev/null 2>&1; then
        printf 'shfmt not installed: uv tool install shfmt\n' >&2
        exit 1
    fi
    shfmt -w -i 4 -ci $(git ls-files setup.sh 'lib/*.sh' 'setup/*.sh' 'bin/*' 'config/i3/monitors/*.sh')

# show the active monitor profile and connected outputs
monitors:
    ./bin/i3-monitors status

# list monitor profiles
profiles:
    ./bin/i3-monitors list
