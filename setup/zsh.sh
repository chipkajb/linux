#!/usr/bin/env bash
# zsh + prompt + shell tooling: rustup/eza, oh-my-zsh, starship, zoxide, atuin, uv.

install_atuin() {
    have atuin && return 0
    if have brew; then
        brew install atuin
    else
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    fi
}

install_rustup() {
    export PATH="$HOME/.cargo/bin:$PATH"
    if ! have rustup; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    fi
    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
    if ! have eza; then
        cargo install eza --locked
    fi
}

install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    local plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugins/zsh-syntax-highlighting"
    clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git "$plugins/zsh-autosuggestions"
    clone_if_missing https://github.com/zsh-users/zsh-history-substring-search.git "$plugins/zsh-history-substring-search"
    clone_if_missing https://github.com/zsh-users/zsh-completions.git "$plugins/zsh-completions"
}

step_zsh() {
    apt_update
    apt_install zsh fzf
    install_rustup
    install_oh_my_zsh

    # default shell — compare resolved paths so a symlinked zsh doesn't re-trigger
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
    fi

    replace_with_symlink "$REPO_ROOT/config/zshrc" "$HOME/.zshrc"

    # credentials stay outside the repo; seed an empty copy for zshrc to source
    if [[ ! -f "$HOME/.zsh_secrets" ]]; then
        cp "$REPO_ROOT/config/zsh_secrets.example" "$HOME/.zsh_secrets"
        chmod 600 "$HOME/.zsh_secrets"
        ui::hint "fill in ~/.zsh_secrets with real credentials"
    fi

    # host-specific shell config lives gitignored in the repo, symlinked to ~/.zsh_local
    if [[ ! -f "$REPO_ROOT/config/zsh_local" ]]; then
        if [[ -f "$HOME/.zsh_local" && ! -L "$HOME/.zsh_local" ]]; then
            cp "$HOME/.zsh_local" "$REPO_ROOT/config/zsh_local"
        else
            cp "$REPO_ROOT/config/zsh_local.example" "$REPO_ROOT/config/zsh_local"
        fi
    fi
    symlink_force "$REPO_ROOT/config/zsh_local" "$HOME/.zsh_local"

    link_bin

    if ! have starship; then
        sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
    fi
    symlink_force "$REPO_ROOT/config/starship.toml" "$HOME/.config/starship.toml"

    if ! have zoxide; then
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    fi

    install_atuin
    install_uv
}
