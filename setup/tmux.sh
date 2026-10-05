#!/usr/bin/env bash
# tmux + TPM plugins, with the OSC 52 clipboard helper.

step_tmux() {
    apt_update
    # remove any distro/pip tmux before building against a known libevent
    sudo apt-get remove -y tmux 2>/dev/null || true
    sudo apt-get purge -y tmux 2>/dev/null || true
    apt_install tmux libevent-dev xclip ncurses-dev

    clone_if_missing https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

    replace_with_symlink "$REPO_ROOT/config/tmux" "$HOME/.config/tmux"
    symlink_force "$REPO_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf"

    ensure_dir "$HOME/.local/bin"
    chmod +x "$REPO_ROOT/bin/osc52-copy"
    symlink_force "$REPO_ROOT/bin/osc52-copy" "$HOME/.local/bin/osc52-copy"
}
