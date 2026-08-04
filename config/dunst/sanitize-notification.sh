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

# approximate chars per wrapped line at width=360 with icon + padding
FOLD_WIDTH=50

normalize_text() {
    local text="$1"
    text="${text//$'\r\n'/$'\n'}"
    text="${text//$'\r'/$'\n'}"
    printf '%b' "$text"
}

# strip blank lines, fold overlong lines, then cap line count
limit_content() {
    local max_lines="$1"
    local fold_width="${2:-$FOLD_WIDTH}"
    fold -s -w "$fold_width" | awk -v max="$max_lines" '
        NF {
            print
            count++
        }
        count >= max {
            exit
        }
    '
}

summary="$(normalize_text "$summary" | limit_content 2)"
body="$(normalize_text "$body" | limit_content 3)"

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
