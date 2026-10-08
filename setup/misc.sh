#!/usr/bin/env bash
# Everything that does not belong to a specific desktop component: CLI tools,
# agent MCP servers, diff review, and editor plugins.

# fff-mcp — agent file search (used by claude/cursor instead of rg/fzf)
install_fff_mcp() {
    if [[ ! -x "$HOME/.local/bin/fff-mcp" ]]; then
        curl -fsSL https://raw.githubusercontent.com/dmtrKovalenko/fff/main/install-mcp.sh | bash
    fi
    if have claude; then
        claude mcp add -s user fff -- "$HOME/.local/bin/fff-mcp" 2>/dev/null || true
    fi
}

# Hunk — terminal diff review for agent-authored changesets (watch + inline rationale)
install_hunk() {
    if ! have npm; then
        ui::warn "npm not found; skipping Hunk"
        return 0
    fi
    if ! have hunk; then
        npm install -g hunkdiff
    fi
    ensure_dir "$HOME/.config/hunk" "$HOME/.local/bin"
    symlink_force "$REPO_ROOT/config/hunk/config.toml" "$HOME/.config/hunk/config.toml"
    chmod +x "$REPO_ROOT/bin/hunk-review" "$REPO_ROOT/bin/hunk-context"
    symlink_force "$REPO_ROOT/bin/hunk-review" "$HOME/.local/bin/hunk-review"
    symlink_force "$REPO_ROOT/bin/hunk-context" "$HOME/.local/bin/hunk-context"
}

# Link every vendored pi skill (config/pi/skills/*) into ~/.pi/agent/skills.
link_pi_skills() {
    ensure_dir "$HOME/.pi/agent/skills"
    local skill
    for skill in "$REPO_ROOT"/config/pi/skills/*; do
        [[ -d "$skill" ]] || continue
        symlink_force "$skill" "$HOME/.pi/agent/skills/$(basename "$skill")"
    done
}

install_gedit_vim_mode() {
    ensure_dir "$HOME/.local/share/gedit/plugins"
    local base="https://raw.githubusercontent.com/nparkanyi/gedit3-vim-mode/master"
    if [[ ! -f "$HOME/.local/share/gedit/plugins/vim-mode.plugin" ]]; then
        wget -q "$base/vim-mode.py" -O "$HOME/.local/share/gedit/plugins/vim-mode.py"
        wget -q "$base/vim-mode.plugin" -O "$HOME/.local/share/gedit/plugins/vim-mode.plugin"
    fi
}

step_misc() {
    apt_update
    apt_install \
        python3-gi unclutter-xfixes flameshot simplescreenrecorder gnome-tweaks \
        fd-find ripgrep bat fzf htop tree jq sysstat screen shellcheck
    install_uv
    if ! uv tool list 2>/dev/null | grep -q '^pre-commit '; then
        uv tool install pre-commit
    fi
    install_fff_mcp
    install_hunk
    link_pi_skills
    install_gedit_vim_mode
}
