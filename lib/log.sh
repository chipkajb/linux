#!/usr/bin/env bash
# log.sh — rich, dependency-free terminal output for setup steps and CLI tools.
#
#   . "$REPO_ROOT/lib/log.sh"
#
# Honors NO_COLOR and degrades to plain text when stdout is not a TTY, so it is
# safe to source from scripts that may be piped or run from cron/CI.

if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    _UI_COLOR=1
else
    _UI_COLOR=0
fi

_UI_RESET=$'\033[0m'

# _ui_color <sgr> <text...>
_ui_color() {
    local sgr="$1"
    shift
    if ((_UI_COLOR)); then
        printf '\033[%sm%s%s' "$sgr" "$*" "$_UI_RESET"
    else
        printf '%s' "$*"
    fi
}

# gruvbox-derived 256-color palette, matching the i3/alacritty theme
ui::bold()   { _ui_color 1 "$@"; }
ui::dim()    { _ui_color 2 "$@"; }
ui::red()    { _ui_color '38;5;203' "$@"; }
ui::green()  { _ui_color '38;5;142' "$@"; }
ui::yellow() { _ui_color '38;5;214' "$@"; }
ui::blue()   { _ui_color '38;5;109' "$@"; }
ui::purple() { _ui_color '38;5;175' "$@"; }
ui::aqua()   { _ui_color '38;5;108' "$@"; }
ui::orange() { _ui_color '38;5;208' "$@"; }
ui::gray()   { _ui_color '38;5;245' "$@"; }

ui::has_color() { ((_UI_COLOR)); }

ui::term_width() {
    local w="${COLUMNS:-0}"
    if ((w == 0)) && command -v tput >/dev/null 2>&1; then
        w="$(tput cols 2>/dev/null || printf 0)"
    fi
    if ((w >= 40 && w <= 200)); then
        printf '%s' "$w"
    else
        printf '80'
    fi
}

# A full-width dim rule, used to frame sections.
ui::rule() {
    local width
    width="$(ui::term_width)"
    ui::gray "$(printf '─%.0s' $(seq 1 "$width"))"
}

# ui::header <title> [subtitle]
ui::header() {
    local title="$1" subtitle="${2:-}"
    local width
    width="$(ui::term_width)"
    printf '\n%s\n' "$(ui::gray "$(printf '━%.0s' $(seq 1 "$width"))")"
    printf '  %s\n' "$(ui::bold "$(ui::blue "$title")")"
    [[ -n "$subtitle" ]] && printf '  %s\n' "$(ui::gray "$subtitle")"
    printf '%s\n' "$(ui::gray "$(printf '━%.0s' $(seq 1 "$width"))")"
}

ui::step() { printf '%s %s\n' "$(ui::blue '→')" "$(ui::bold "$*")"; }
ui::ok()   { printf '%s %s\n' "$(ui::green '✔')" "$*"; }
ui::warn() { printf '%s %s\n' "$(ui::yellow '▲')" "$*"; }
ui::err()  { printf '%s %s\n' "$(ui::red '✖')" "$*" >&2; }
ui::info() { printf '%s %s\n' "$(ui::gray '·')" "$*"; }
ui::done() { printf '%s %s\n' "$(ui::green '✔')" "$(ui::bold "$*")"; }

# ui::kv <key> <value> — aligned detail line under a step
ui::kv() {
    printf '   %s %s\n' "$(ui::gray "$1")" "$2"
}

# ui::hint <text> — dim, indented follow-up (paths, next commands)
ui::hint() {
    printf '   %s\n' "$(ui::gray "$*")"
}

# ui::section <title> — lighter-weight divider between menu groups
ui::section() {
    printf '\n  %s\n' "$(ui::purple "$*")"
}
