#!/usr/bin/env bash
# alacritty terminal + color themes.

step_alacritty() {
    apt_update
    sudo add-apt-repository ppa:aslatter/ppa -y
    apt_install alacritty

    # register as the default terminal without the interactive --config picker
    if have alacritty; then
        sudo update-alternatives --set x-terminal-emulator "$(command -v alacritty)" 2>/dev/null || true
    fi

    replace_with_symlink "$REPO_ROOT/config/alacritty" "$HOME/.config/alacritty"
    ensure_dir "$HOME/.config/alacritty/themes"
    clone_if_missing https://github.com/alacritty/alacritty-theme "$HOME/.config/alacritty/themes"
}
