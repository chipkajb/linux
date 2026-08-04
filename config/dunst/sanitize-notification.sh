#!/usr/bin/env bash
# sanitize notification text and re-display (avoids empty lines + long bodies)

set -euo pipefail

if [[ "${DUNST_CATEGORY:-}" == "x-sanitized" ]]; then
    exit 0
fi

command -v dunstify >/dev/null 2>&1 || exit 0

appname="${DUNST_APPNAME:-${DUNST_APP_NAME:-notification}}"
summary="${DUNST_SUMMARY:-}"
body="${DUNST_BODY:-}"
urgency="${DUNST_URGENCY:-NORMAL}"
icon_path="${DUNST_ICON_PATH:-}"

limit_lines() {
    local max_lines="$1"
    awk -v max="$max_lines" '
        NF {
            print
            count++
        }
        count >= max {
            exit
        }
    '
}

summary="$(printf '%s\n' "$summary" | limit_lines 2)"
body="$(printf '%s\n' "$body" | limit_lines 3)"

args=(
    -a "$appname"
    -h "string:category:x-sanitized"
)

case "${urgency^^}" in
    LOW) args+=(-u low) ;;
    CRITICAL) args+=(-u critical) ;;
    *) args+=(-u normal) ;;
esac

if [[ -n "$icon_path" && -e "$icon_path" ]]; then
    args+=(-i "$icon_path")
fi

if [[ -n "$body" ]]; then
    dunstify "${args[@]}" "$summary" "$body"
else
    dunstify "${args[@]}" "$summary"
fi
