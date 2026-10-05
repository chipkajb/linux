#!/usr/bin/env bash
# Monitor profile tooling.
#
# Profiles live in config/i3/monitors/*.sh and define semantic roles
# (left/middle/right/bottom). i3-monitors generates ~/.i3_monitors, which
# config/i3/config includes, so workspaces follow the same roles everywhere.

# Ensure the generated i3 include exists (idempotent). Does not touch X.
monitors_init() {
    chmod +x "$REPO_ROOT/bin/i3-monitors"
    if [[ -f "$HOME/.i3_monitors" ]]; then
        ui::info "monitor include present ($(cat "$HOME/.config/i3-monitors/current" 2>/dev/null || printf 'unknown'))"
        return 0
    fi
    local name
    name="$("$REPO_ROOT/bin/i3-monitors" detect 2>/dev/null || true)"
    "$REPO_ROOT/bin/i3-monitors" generate "${name:-office}" >/dev/null
    ui::hint "switching layouts: i3-monitors office|home|laptop  (or Mod+Shift+m)"
}

step_monitors() {
    link_bin
    monitors_init
    ui::hint "current layout: $(cat "$HOME/.config/i3-monitors/current" 2>/dev/null || printf 'unset')"
}
