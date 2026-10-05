#!/usr/bin/env bash
# Claude Code + versioned config (config/claude -> ~/.claude).
# Only curated files are linked; ~/.claude also holds credentials, history, and caches.

CLAUDE_LINKS=(
    CLAUDE.md
    settings.json
    statusline.sh
    statusline-wrapper.sh
    hooks
    commands
    skills/graphify
)

step_claude() {
    export PATH="$HOME/.local/bin:$PATH"
    if ! have claude; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    apt_install jq nodejs

    ensure_dir "$HOME/.claude/skills"
    local item target
    for item in "${CLAUDE_LINKS[@]}"; do
        target="$HOME/.claude/$item"
        # keep a real (non-repo) copy rather than clobbering it
        if [[ -e "$target" && ! -L "$target" ]]; then
            mv "$target" "$target.bak-$(date +%F)"
        fi
        symlink_force "$REPO_ROOT/config/claude/$item" "$target"
    done
}
