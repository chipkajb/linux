#!/usr/bin/env bash
# VS Code (apt repo with signed-by keyring; works on 22.04 and 24.04 where apt-key is gone).

VSCODE_EXTENSIONS=(
    Atishay-Jain.All-Autocomplete
    astral-sh.ty
    IronGeek.vscode-env
    ZainChen.json
    esbenp.prettier-vscode
    ms-python.python
    mechatroner.rainbow-csv
    tickleforce.scrolloff
    vscodevim.vim
    Ransh.ransh
    jdinhlife.gruvbox
    charliermarsh.ruff
    lucien-martijn.parquet-visualizer
    ms-python.debugpy
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
    ms-vscode-remote.remote-explorer
    tomoki1207.pdf
)

add_vscode_repo() {
    sudo rm -f /etc/apt/sources.list.d/vscode.list /etc/apt/sources.list.d/vscode.sources
    apt_install wget gpg apt-transport-https
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
    rm -f /tmp/packages.microsoft.gpg
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/packages.microsoft.gpg
EOF
}

link_vscode_config() {
    local editor_dir
    for editor_dir in "$HOME/.config/Code/User" "$HOME/.config/Cursor/User"; do
        ensure_dir "$editor_dir"
        symlink_force "$REPO_ROOT/config/vscode/settings.json" "$editor_dir/settings.json"
        symlink_force "$REPO_ROOT/config/vscode/keybindings.json" "$editor_dir/keybindings.json"
    done
}

step_vscode() {
    add_vscode_repo
    apt_update
    apt_install code

    local ext
    for ext in "${VSCODE_EXTENSIONS[@]}"; do
        code --install-extension "$ext" >/dev/null
    done

    link_vscode_config
    python3 "$REPO_ROOT/config/vscode/hide-staged-gutter-diffs.py" || ui::warn "gutter-diff patch skipped"
}
