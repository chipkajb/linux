#!/usr/bin/env bash
# ADLC agent tooling: herdr (terminal orchestration), caveman, and superpowers.

install_herdr() {
    export PATH="$HOME/.local/bin:$PATH"
    if ! have herdr; then
        curl -fsSL https://herdr.dev/install.sh | sh
    fi
}

install_herdr_config() {
    ensure_dir "$HOME/.config/herdr"
    symlink_force "$REPO_ROOT/config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
    if have herdr; then
        herdr config check || true
        # a server started before the symlink keeps default keys (prefix ctrl+b)
        herdr server reload-config &>/dev/null || true
    fi
}

install_herdr_launchers() {
    ensure_dir "$HOME/.local/bin" "$HOME/.local/share/applications"
    chmod +x "$REPO_ROOT/bin/herdr-launch" "$REPO_ROOT/bin/herdr-reset"
    symlink_force "$REPO_ROOT/bin/herdr-launch" "$HOME/.local/bin/herdr-launch"
    symlink_force "$REPO_ROOT/bin/herdr-reset" "$HOME/.local/bin/herdr-reset"
    symlink_force "$REPO_ROOT/config/applications/herdr.desktop" "$HOME/.local/share/applications/herdr.desktop"
}

install_app_icons() {
    local size_dir size icon
    for size_dir in "$REPO_ROOT"/assets/icons/hicolor/*/apps; do
        [[ -d "$size_dir" ]] || continue
        size="$(basename "$(dirname "$size_dir")")"
        ensure_dir "$HOME/.local/share/icons/hicolor/$size/apps"
        for icon in "$size_dir"/*.png; do
            [[ -f "$icon" ]] || continue
            symlink_force "$icon" "$HOME/.local/share/icons/hicolor/$size/apps/$(basename "$icon")"
        done
    done

    # Cursor ships only in pixmaps; alias into hicolor for dunst's icon lookup
    if [[ -f /usr/share/pixmaps/co.anysphere.cursor.png ]]; then
        local s
        for s in 48x48 128x128 256x256; do
            ensure_dir "$HOME/.local/share/icons/hicolor/$s/apps"
            symlink_force /usr/share/pixmaps/co.anysphere.cursor.png \
                "$HOME/.local/share/icons/hicolor/$s/apps/co.anysphere.cursor.png"
            symlink_force /usr/share/pixmaps/co.anysphere.cursor.png \
                "$HOME/.local/share/icons/hicolor/$s/apps/cursor.png"
        done
    fi

    if have gtk-update-icon-cache; then
        gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
    fi
    if have update-desktop-database; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi
}

install_caveman() {
    curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash || true
}

install_superpowers() {
    if have claude; then
        claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
        claude plugin install superpowers@claude-plugins-official -s user 2>/dev/null \
            || claude plugin install superpowers@superpowers-marketplace -s user 2>/dev/null \
            || true
    else
        ui::warn "claude not on PATH; skipping Claude Code superpowers"
    fi
    if have npx; then
        npx --yes skills add JuliusBrussee/caveman -a cursor 2>/dev/null || true
    fi
}

step_adlc() {
    export PATH="$HOME/.local/bin:$PATH"
    apt_update
    apt_install xclip

    install_herdr
    install_herdr_config
    install_herdr_launchers
    install_app_icons
    install_caveman
    install_superpowers

    ui::kv "herdr:" "$(command -v herdr || printf '%s' "$HOME/.local/bin/herdr")"
    ui::hint "launch from rofi (Mod+d) as herdr, or i3 Mod+Shift+t"
    ui::hint "prefix is Ctrl-Space (config/herdr/config.toml)"
}
