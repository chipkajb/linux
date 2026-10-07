#!/usr/bin/env bash
# resolve i3 workspace for a notification and optionally switch to it

set -euo pipefail

# Workspace numbers only — names live in config/i3/config, so this file never
# drifts from the i3 binding list. `i3-msg workspace number N` matches by number
# regardless of the workspace's display name.
readonly WS_WEB=1
readonly WS_TERMINAL=2
readonly WS_CODE=3
readonly WS_MESSAGES=4
readonly WS_FILES=5
readonly WS_NOTES=6
readonly WS_MUSIC=7
readonly WS_DATA=10

workspace_label() {
    case "$1" in
        1) printf 'Web' ;;
        2) printf 'Terminal' ;;
        3) printf 'Code' ;;
        4) printf 'Messages' ;;
        5) printf 'Files' ;;
        6) printf 'Notes' ;;
        7) printf 'Music' ;;
        8) printf 'Terminal+' ;;
        9) printf 'Code+' ;;
        10) printf 'Data' ;;
        *) printf 'workspace %s' "$1" ;;
    esac
}

notify() {
    if [[ -x /usr/bin/notify-send ]]; then
        /usr/bin/notify-send -a i3 "$@"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -a i3 "$@"
    fi
}

parse_workspace_category() {
    local category="${1:-}"
    if [[ "$category" =~ x-workspace:([^;]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

looks_like_slack_summary() {
    local summary="$1"
    [[ "$summary" =~ ^\[[^]]+\][[:space:]]+(from|in)[[:space:]] ]]
}

resolve_notification_workspace() {
    local app="${1,,}"
    local sum="$2"
    local body="$3"
    local desktop="${4,,}"
    local text="${sum} ${body}"

    if looks_like_slack_summary "$sum"; then
        printf '%s\n' "$WS_MESSAGES"
        return 0
    fi

    if [[ -z "$app" || "$app" == "notification" ]]; then
        if [[ "$desktop" == *slack* ]]; then
            printf '%s\n' "$WS_MESSAGES"
            return 0
        fi
        if [[ "${text,,}" == *slack* ]]; then
            printf '%s\n' "$WS_MESSAGES"
            return 0
        fi
    fi

    case "$app" in
        grid-*|*grid*|*teamworks*|*slack*|*discord*|*telegram*|*signal*|*teams*|*mattermost*|*element*|*franz*|*rambox*)
            printf '%s\n' "$WS_MESSAGES"
            ;;
        *google*chrome*|*chromium*|*firefox*|*brave*|*vivaldi*|*opera*|*microsoft-edge*|*edge*)
            printf '%s\n' "$WS_WEB"
            ;;
        cursor|*cursor*|code|*vscode*|*vscodium*|*sublime*|*intellij*|*pycharm*|*webstorm*)
            printf '%s\n' "$WS_CODE"
            ;;
        herdr)
            if [[ "${text,,}" == *cursor* ]]; then
                printf '%s\n' "$WS_CODE"
            else
                printf '%s\n' "$WS_TERMINAL"
            fi
            ;;
        alacritty|*alacritty*|kitty|*kitty*|*terminator*|*xterm*|*foot*|*wezterm*)
            printf '%s\n' "$WS_TERMINAL"
            ;;
        claude|claude-desktop|*claude*|*anthropic*)
            printf '%s\n' "$WS_DATA"
            ;;
        obsidian|*obsidian*|gedit|*notion*|*logseq*)
            printf '%s\n' "$WS_NOTES"
            ;;
        *nautilus*|*thunar*|*dolphin*|files)
            printf '%s\n' "$WS_FILES"
            ;;
        pithos|*pithos*|pavucontrol|*pavucontrol*|*blueman*|*spotify*|*rhythmbox*|*clementine*)
            printf '%s\n' "$WS_MUSIC"
            ;;
        *mongodb*)
            printf '%s\n' "$WS_DATA"
            ;;
        *)
            return 1
            ;;
    esac
}

workspace_for_notification() {
    local appname="${1:-}"
    local summary="${2:-}"
    local body="${3:-}"
    local desktop_entry="${4:-}"
    local category="${5:-}"

    local workspace=""
    if workspace="$(parse_workspace_category "$category")"; then
        printf '%s\n' "$workspace"
        return 0
    fi

    resolve_notification_workspace "$appname" "$summary" "$body" "$desktop_entry"
}

goto_workspace_for_notification() {
    local appname="${1:-}"
    local summary="${2:-}"
    local body="${3:-}"
    local desktop_entry="${4:-}"
    local category="${5:-}"
    local quiet="${6:-}"

    command -v i3-msg >/dev/null 2>&1 || return 1

    local workspace=""
    if ! workspace="$(workspace_for_notification "$appname" "$summary" "$body" "$desktop_entry" "$category")"; then
        if [[ "$quiet" != "quiet" ]]; then
            local label="${appname:-unknown app}"
            notify "Notifications" "No workspace mapped for ${label}" -i dialog-warning -t 4000
        fi
        return 1
    fi

    i3-msg "workspace number $workspace" >/dev/null
    if [[ "$quiet" != "quiet" ]]; then
        notify "Notifications" "Switched to $(workspace_label "$workspace") (${appname:-app})" -i dialog-information -t 2500
    fi
}

goto_latest_history_workspace() {
    command -v dunstctl >/dev/null 2>&1 || exit 0
    command -v jq >/dev/null 2>&1 || exit 0

    local history
    history="$(dunstctl history 2>/dev/null)" || {
        notify "Notifications" "Dunst is not running" -i dialog-warning -t 3000
        exit 0
    }

    read -r appname summary body category < <(
        printf '%s' "$history" | jq -r '
            (.data[0] // [])
            | map(select(
                ((.appname.data // "") | ascii_downcase) as $app |
                $app != "i3" and $app != "notify-send" and $app != "dunst"
              ))
            | if length == 0 then empty else
                max_by(.timestamp.data) |
                [
                    (.appname.data // ""),
                    (.summary.data // ""),
                    (.body.data // ""),
                    (.category.data // "")
                ] | @tsv
              end
        '
    ) || true

    if [[ -z "${appname:-}${summary:-}${body:-}" ]]; then
        notify "Notifications" "No app notifications in dunst history" -i dialog-information -t 3000
        exit 0
    fi

    goto_workspace_for_notification "$appname" "$summary" "$body" "" "$category"
}

case "${1:-history}" in
    resolve)
        workspace_for_notification "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
        ;;
    goto)
        goto_workspace_for_notification "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}"
        ;;
    history|*)
        goto_latest_history_workspace
        ;;
esac
