#!/usr/bin/env bash
# sanitize notification text and re-display (strip blank lines, truncate long bodies)

set -euo pipefail

if [[ "${DUNST_CATEGORY:-}" == "x-sanitized" ]]; then
    exit 0
fi

command -v dunstify >/dev/null 2>&1 || exit 0

appname="${DUNST_APPNAME:-${DUNST_APP_NAME:-${1:-notification}}}"
summary="${DUNST_SUMMARY:-${2:-}}"
body="${DUNST_BODY:-${3:-}}"
urgency="${DUNST_URGENCY:-${5:-NORMAL}}"
icon_path="${DUNST_ICON_PATH:-${4:-}}"

BODY_MAX_CHARS=100

normalize_text() {
    local text="$1"
    text="${text//$'\r\n'/$'\n'}"
    text="${text//$'\r'/$'\n'}"
    printf '%b' "$text"
}

strip_markup() {
    sed -e 's/<br[[:space:]]*\/?>/ /gi' -e 's/<[^>]*>//g'
}

strip_empty_lines() {
    awk '
        NF {
            if (n++) {
                printf " "
            }
            printf "%s", $0
        }
    '
}

collapse_whitespace() {
    tr '\n\r\t' '   ' | awk '{$1=$1; print}'
}

trim_whitespace() {
    local text="$1"
    text="${text#"${text%%[![:space:]]*}"}"
    text="${text%"${text##*[![:space:]]}"}"
    printf '%s' "$text"
}

truncate_chars() {
    local max="$1"
    local text="$2"
    if ((${#text} > max)); then
        text="${text:0:max}"
    fi
    printf '%s' "$text"
}

sanitize_field() {
    local max_chars="$1"
    local text="$2"
    text="$(normalize_text "$text")"
    text="$(printf '%s' "$text" | strip_markup)"
    text="$(printf '%s\n' "$text" | strip_empty_lines)"
    text="$(printf '%s' "$text" | collapse_whitespace)"
    text="$(trim_whitespace "$text")"
    if ((max_chars > 0)); then
        text="$(truncate_chars "$max_chars" "$text")"
    fi
    trim_whitespace "$text"
}

summary="$(sanitize_field 0 "$summary")"
body="$(sanitize_field "$BODY_MAX_CHARS" "$body")"

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
