#!/usr/bin/env bash
# common.sh — shared helpers for setup steps and CLI tools.
#
#   . "$REPO_ROOT/lib/common.sh"
#
# Expects lib/log.sh to have been sourced first.

# Resolve the repository root from this file's location, independent of $PWD.
: "${REPO_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export REPO_ROOT

# have <cmd> — silent test
have() { command -v "$1" >/dev/null 2>&1; }

# require_cmd <cmd> [install hint]
require_cmd() {
    local cmd="$1" hint="${2:-}"
    if ! have "$cmd"; then
        ui::err "missing dependency: ${cmd}"
        [[ -n "$hint" ]] && ui::hint "$hint"
        return 1
    fi
}

# ensure_dir <dir>
ensure_dir() { mkdir -p "$1"; }

# symlink_force <target> <link>
symlink_force() { ln -sfn "$1" "$2"; }

# replace_with_symlink <target> <link> — link a dotfile path, replacing a real
# file/dir left over from a previous manual setup. Only use for known config
# targets that this repo owns.
replace_with_symlink() {
    local src="$1" dest="$2"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
        rm -rf "$dest"
    fi
    ln -sfn "$src" "$dest"
}

# git_pull_ff <repo> — fast-forward an existing checkout, never destructive
git_pull_ff() {
    local repo="$1"
    [[ -d "$repo/.git" ]] || return 0
    git -C "$repo" pull --ff-only --quiet 2>/dev/null || ui::warn "could not fast-forward $(basename "$repo") (local changes?)"
}

# clone_if_missing <url> <dest> [git clone args...]
clone_if_missing() {
    local url="$1" dest="$2"
    shift 2
    if [[ -d "$dest/.git" ]]; then
        ui::info "already cloned: $(basename "$dest")"
        return 0
    fi
    git clone "$@" "$url" "$dest"
}

# run_step <label> <fn> [args...]
#
# Runs the step in a subshell with `set -e` so a failure aborts that step but
# not the whole program. The subshell isolates `cd`/exports between steps; each
# step is expected to set the PATH it needs.
run_step() {
    local label="$1"
    shift
    ui::step "$label"
    local rc=0
    ( set -euo pipefail; "$@" ) || rc=$?
    if ((rc == 0)); then
        ui::ok "$label"
    else
        ui::err "${label} failed (exit ${rc})"
    fi
    return "$rc"
}

# link_bin — publish every bin/ tool into /usr/local/bin (system PATH, so i3,
# dunst, and rofi see them regardless of the user's shell PATH).
link_bin() {
    local src_dir="$REPO_ROOT/bin" dest="/usr/local/bin"
    [[ -d "$src_dir" ]] || return 0
    # prune dangling links from the pre-bin/ layout (scripts/ -> bin/)
    sudo find "$dest" -maxdepth 1 -type l -lname "$REPO_ROOT/scripts/*" -delete 2>/dev/null || true
    local file name
    for file in "$src_dir"/*; do
        [[ -f "$file" ]] || continue
        name="$(basename "$file")"
        sudo ln -sfn "$file" "$dest/$name"
    done
}

# is_ubuntu_at_least <version> — true when the running Ubuntu is >= version
is_ubuntu_at_least() {
    [[ -n "${UBUNTU_VERSION:-}" ]] || return 1
    [[ "$(printf '%s\n%s\n' "$1" "$UBUNTU_VERSION" | sort -V | head -n 1)" == "$1" ]]
}

# confirm <prompt> [default: y|n] — interactive only; false when non-interactive
confirm() {
    local prompt="$1" default="${2:-n}" reply
    [[ -t 0 ]] || return 1
    if [[ "$default" == "y" ]]; then
        printf '%s [Y/n] ' "$prompt"
    else
        printf '%s [y/N] ' "$prompt"
    fi
    read -r reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}
