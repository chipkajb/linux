#!/usr/bin/env bash
# Preflight: verify the host, cache Ubuntu version, and normalise apt sources.
# Runs in the parent shell (not a subshell) so UBUNTU_VERSION is available to
# every step.

# vscode.list (written by older versions of this script) and vscode.sources
# (written by the `code` package) point at the same repo with different Signed-By
# paths, which makes apt fail with a duplicate-source error.
fix_vscode_apt_sources() {
    local list="/etc/apt/sources.list.d/vscode.list"
    local sources="/etc/apt/sources.list.d/vscode.sources"
    if [[ -f "$list" ]] && { [[ -f "$sources" ]] || grep -q 'packages\.microsoft\.gpg' "$list" 2>/dev/null; }; then
        ui::warn "removing conflicting vscode.list"
        sudo rm -f "$list"
    fi
}

apt_update() {
    fix_vscode_apt_sources
    sudo apt-get update
}

apt_install() {
    sudo apt-get install -y "$@"
}

# uv — Python versions, venvs, and CLI tools (replaces anaconda + pipx)
install_uv() {
    if ! have uv; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    export PATH="$HOME/.local/bin:$PATH"
}

# Sets UBUNTU_VERSION / UBUNTU_CODENAME. Exits on an unsupported distribution.
detect_ubuntu() {
    if [[ ! -r /etc/os-release ]]; then
        ui::err "/etc/os-release not found; this setup targets Ubuntu 22.04 or 24.04"
        exit 1
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        ui::err "detected ID=${ID:-unknown}; expected ubuntu 22.04 or 24.04"
        exit 1
    fi
    UBUNTU_VERSION="${VERSION_ID:-}"
    UBUNTU_CODENAME="${VERSION_CODENAME:-}"
    case "$UBUNTU_VERSION" in
        22.04 | 24.04)
            ui::info "Ubuntu $(ui::bold "$UBUNTU_VERSION") ($UBUNTU_CODENAME)"
            ;;
        *)
            ui::warn "Ubuntu $UBUNTU_VERSION is untested; 22.04 and 24.04 are supported"
            ;;
    esac
    fix_vscode_apt_sources
}
