#!/usr/bin/env bash
# vim + Vundle plugins.

step_vim() {
    apt_update
    apt_install libclang-dev vim

    rm -f "$HOME/.viminfo"
    replace_with_symlink "$REPO_ROOT/config/vim" "$HOME/.vim"
    replace_with_symlink "$REPO_ROOT/config/vimrc" "$HOME/.vimrc"

    clone_if_missing https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"

    ui::info "installing vim plugins (this can take a few minutes)"
    vim -Nu "$HOME/.vimrc" -n -Es +PluginInstall +qall

    # clang_complete hard-codes a libclang path; surface the correct one.
    local configured found
    configured="$(grep -o '/[^ ]*libclang[^ ]*\.so[^ ]*' "$HOME/.vimrc" | head -n 1 || true)"
    found="$(find /usr/lib -iname 'libclang.so*' 2>/dev/null | head -n 1 || true)"
    if [[ -n "$found" && "$configured" != "$found" ]]; then
        ui::warn "vimrc libclang path may be stale"
        ui::kv "vimrc:" "$configured"
        ui::kv "found:" "$found"
    fi
}
