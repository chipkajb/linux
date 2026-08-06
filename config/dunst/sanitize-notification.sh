#!/usr/bin/env bash
# sanitize notification text and re-display (multiline limits, truncate long bodies)

set -euo pipefail

if [[ "${DUNST_CATEGORY:-}" == x-sanitized* ]]; then
    exit 0
fi

command -v dunstify >/dev/null 2>&1 || exit 0

readonly SUMMARY_MAX_LINES=2
# keep each summary line short enough to fit one visual row (toast width ~360px)
readonly SUMMARY_MAX_CHARS_PER_LINE=48
readonly BODY_MAX_LINES=3
readonly BODY_MAX_CHARS=100
readonly WS_SCRIPT="${HOME}/workspace/linux/scripts/i3-notification-workspace.sh"

appname="${DUNST_APPNAME:-${DUNST_APP_NAME:-${1:-}}}"
summary="${DUNST_SUMMARY:-${2:-}}"
body="${DUNST_BODY:-${3:-}}"
urgency="${DUNST_URGENCY:-${5:-NORMAL}}"
icon_path="${DUNST_ICON_PATH:-${4:-}}"
desktop_entry="${DUNST_DESKTOP_ENTRY:-}"

looks_like_slack_summary() {
    [[ "$1" =~ ^\[[^]]+\][[:space:]]+(from|in)[[:space:]] ]]
}

# Slack snap sends an empty appname; dunstify rejects `-a ""`.
if [[ -z "$appname" ]]; then
    if looks_like_slack_summary "$summary"; then
        appname="Slack"
    elif [[ "$desktop_entry" == *slack* ]]; then
        appname="Slack"
    fi
fi

normalize_text() {
    local text="$1"
    text="${text//$'\r\n'/$'\n'}"
    text="${text//$'\r'/$'\n'}"
    text="${text//$'\v'/$'\n'}"
    text="${text//$'\f'/$'\n'}"
    printf '%b' "$text"
}

strip_markup() {
    sed -e 's/<br[[:space:]]*\/?>/\n/gi' -e 's/<[^>]*>//g'
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

# split notification text into non-empty, whitespace-normalized lines
split_nonempty_lines() {
    awk '
        NF {
            line = $0
            gsub(/[[:space:]]+/, " ", line)
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)
            if (length(line) > 0) {
                print line
            }
        }
    '
}

read_nonempty_lines() {
    local -n _out_var="$1"
    local text="$2"
    _out_var=()
    mapfile -t _out_var < <(
        normalize_text "$text" | strip_markup | split_nonempty_lines
    )
}

truncate_line_width() {
    local max_chars="$1"
    local text="$2"
    if ((max_chars > 0 && ${#text} > max_chars)); then
        text="${text:0:max_chars}"
    fi
    printf '%s' "$text"
}

join_lines() {
    local lines=("$@")
    local joined=""
    local line
    for line in "${lines[@]}"; do
        if [[ -z "$line" ]]; then
            continue
        fi
        if [[ -n "$joined" ]]; then
            joined+=$'\n'
        fi
        joined+="$line"
    done
    printf '%s' "$joined"
}

take_lines() {
    local max_lines="$1"
    local -n _lines_var="$2"
    local -n _overflow_var="$3"
    _overflow_var=()
    if ((${#_lines_var[@]} <= max_lines)); then
        return 0
    fi
    _overflow_var=("${_lines_var[@]:max_lines}")
    _lines_var=("${_lines_var[@]:0:max_lines}")
}

build_summary_and_body() {
    local raw_summary="$1"
    local raw_body="$2"
    local summary_lines=()
    local body_lines=()
    local overflow_lines=()
    local combined_lines=()
    local i

    read_nonempty_lines summary_lines "$raw_summary"
    read_nonempty_lines body_lines "$raw_body"

    take_lines "$SUMMARY_MAX_LINES" summary_lines overflow_lines

    for ((i = 0; i < ${#summary_lines[@]}; i++)); do
        summary_lines[i]="$(truncate_line_width "$SUMMARY_MAX_CHARS_PER_LINE" "${summary_lines[i]}")"
    done

    combined_lines=("${overflow_lines[@]}" "${body_lines[@]}")
    take_lines "$BODY_MAX_LINES" combined_lines overflow_lines

    summary="$(join_lines "${summary_lines[@]}")"
    body="$(join_lines "${combined_lines[@]}")"
    body="$(truncate_chars "$BODY_MAX_CHARS" "$body")"
    body="$(trim_whitespace "$body")"
}

build_summary_and_body "$summary" "$body"

category="x-sanitized"
if [[ -x "$WS_SCRIPT" ]]; then
    workspace="$("$WS_SCRIPT" resolve "$appname" "$summary" "$body" "$desktop_entry" "" 2>/dev/null || true)"
    if [[ -n "${workspace:-}" ]]; then
        category="x-sanitized;x-workspace:${workspace}"
    fi
fi

args=(-h "string:category:${category}")
if [[ -n "$appname" ]]; then
    args+=(-a "$appname")
fi

if [[ -n "$desktop_entry" ]]; then
    args+=(-h "string:x-canonical-desktop:${desktop_entry}")
fi

case "${urgency^^}" in
    LOW) args+=(-u low) ;;
    CRITICAL) args+=(-u critical) ;;
    *) args+=(-u normal) ;;
esac

if [[ -n "$icon_path" && -e "$icon_path" ]]; then
    args+=(-i "$icon_path")
fi

display_sanitized_notification() {
    local action=""
    if [[ -n "$body" ]]; then
        action="$(dunstify "${args[@]}" -A "default,Focus workspace" -b "$summary" "$body" 2>/dev/null)" || true
    else
        action="$(dunstify "${args[@]}" -A "default,Focus workspace" -b "$summary" 2>/dev/null)" || true
    fi

    if [[ "$action" == "default" && -x "$WS_SCRIPT" ]]; then
        "$WS_SCRIPT" goto "$appname" "$summary" "$body" "$desktop_entry" "$category" quiet
    fi
}

display_sanitized_notification &
