#!/usr/bin/env bash
# Neovim (NvChad), LSP tooling, treesitter parsers, and git mergetool defaults.

# tree-sitter-cli 0.26+ is required by nvim-treesitter main on Neovim 0.12.
# 24.04+ (glibc 2.39): the upstream linux-x64 zip works.
# 22.04  (glibc 2.35): the prebuilt needs GLIBC_2.39, so build from source.
install_tree_sitter_cli() {
    local version="0.26.11"
    if tree-sitter --version 2>/dev/null | grep -q "$version"; then
        ui::info "tree-sitter-cli v$version already installed"
        return 0
    fi
    ui::info "installing tree-sitter-cli v$version (Ubuntu $UBUNTU_VERSION)"
    mkdir -p "$HOME/.local/bin"

    if is_ubuntu_at_least 24.04; then
        apt_install unzip
        local tmpdir
        tmpdir="$(mktemp -d)"
        if wget -q "https://github.com/tree-sitter/tree-sitter/releases/download/v${version}/tree-sitter-cli-linux-x64.zip" \
            -O "$tmpdir/tree-sitter.zip" \
            && unzip -qo "$tmpdir/tree-sitter.zip" -d "$tmpdir" \
            && "$tmpdir/tree-sitter" --version &>/dev/null; then
            install -m 755 "$tmpdir/tree-sitter" "$HOME/.local/bin/tree-sitter"
            rm -rf "$tmpdir"
            return 0
        fi
        rm -rf "$tmpdir"
        ui::warn "prebuilt tree-sitter failed on Ubuntu $UBUNTU_VERSION; building from source"
    fi

    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
    if ! have cargo; then
        ui::err "cargo not found; run the zsh step first to install rustup"
        return 1
    fi
    cargo install tree-sitter-cli --version "$version" --root "$HOME/.local" --locked --force
}

# Sync lazy.nvim plugins and install treesitter parsers used for markdown rendering.
install_neovim_treesitter_parsers() {
    if ! have nvim; then
        ui::warn "nvim not on PATH; skipping treesitter parsers"
        return 0
    fi
    nvim --headless "+Lazy! sync" +qa
    nvim --headless "+lua require('custom.configs.treesitter').install_parsers()" +qa
}

# Install the mason LSP/tool packages declared in chadrc.
install_neovim_mason_packages() {
    if ! have nvim; then
        ui::warn "nvim not on PATH; skipping mason packages"
        return 0
    fi
    if ! have npm; then
        ui::warn "npm not on PATH; json-lsp, yaml-language-server, and typescript-language-server may fail"
    fi
    # headless: avoid :MasonInstallAll (it opens the UI)
    nvim --headless "+lua local pkgs=require('nvconfig').mason.pkgs; if #pkgs==0 then vim.cmd('qa!') else vim.cmd('MasonInstall '..table.concat(pkgs,' ')) end" +qa
}

install_nvchad() {
    if [[ -d "$HOME/.config/nvim/.git" ]]; then
        ui::info "NvChad already present"
    else
        rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim"
        git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
    fi
    replace_with_symlink "$REPO_ROOT/config/nvim/after" "$HOME/.config/nvim/after"
    replace_with_symlink "$REPO_ROOT/config/nvim/custom" "$HOME/.config/nvim/lua/custom"
    symlink_force "$REPO_ROOT/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    symlink_force "$REPO_ROOT/config/nvim/lua/configs" "$HOME/.config/nvim/lua/configs"
    symlink_force "$REPO_ROOT/config/nvim/lua/chadrc.lua" "$HOME/.config/nvim/lua/chadrc.lua"
}

uv_tool_install() {
    local tool="$1"
    if uv tool list 2>/dev/null | grep -q "^${tool} "; then
        ui::info "uv tool $tool already installed"
        return 0
    fi
    uv tool install "$tool"
}

configure_git_mergetool() {
    # fallback for tools that call `git mergetool`; prefer nvim + :DiffviewOpen (<leader>gd)
    git config --global merge.tool nvimdiff
    # shellcheck disable=SC2016  # $LOCAL/$BASE/... are expanded by git, not the shell
    git config --global mergetool.nvimdiff.cmd 'nvim -d $LOCAL $BASE $REMOTE $MERGED -c "wincmd J"'
    git config --global mergetool.nvimdiff.trustExitCode true
    git config --global mergetool.keepBackup false
    git config --global merge.conflictstyle diff3
}

step_neovim() {
    apt_update
    apt_install snapd gcc g++ make git unzip
    install_uv

    if snap list nvim &>/dev/null; then
        sudo snap refresh nvim
    else
        sudo snap install nvim --classic
    fi
    sudo mkdir -p /usr/local/bin
    sudo ln -sf /snap/bin/nvim /usr/local/bin/nvim
    sudo rm -f /usr/local/bin/vim /usr/bin/nvim-linux-x86_64.appimage
    sudo snap alias nvim.nvim vim

    install_nvchad
    apt_install ripgrep python3-venv jq

    uv_tool_install ruff
    uv_tool_install ty

    install_tree_sitter_cli
    install_neovim_treesitter_parsers
    install_neovim_mason_packages
    configure_git_mergetool
}
