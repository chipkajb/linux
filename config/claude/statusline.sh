#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
TOK_IN=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0' | cut -d. -f1)
TOK_OUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty' | cut -d. -f1)
TOK_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // 0' | cut -d. -f1)
[[ "$PCT" =~ ^[0-9]+$ ]] || PCT=0
[[ "$TOK_IN" =~ ^[0-9]+$ ]] || TOK_IN=0
[[ "$TOK_MAX" =~ ^[0-9]+$ ]] || TOK_MAX=0

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; BLUE='\033[34m'; DIM='\033[90m'; UNDERLINE='\033[4m'; RESET='\033[0m'

# compact token count: 847, 12.3k, 1.2M
fmt_tokens() {
    local n="${1:-0}"
    [[ "$n" =~ ^[0-9]+$ ]] || { printf '—'; return; }
    local whole frac unit div
    if (( n >= 1000000 )); then
        div=1000000; unit=M
    elif (( n >= 1000 )); then
        div=1000; unit=k
    else
        printf '%d' "$n"
        return
    fi
    whole=$((n / div))
    frac=$(( (n % div) * 10 / div ))
    if (( frac == 0 )); then
        printf '%d%s' "$whole" "$unit"
    else
        printf '%d.%d%s' "$whole" "$frac" "$unit"
    fi
}

# Pick bar color based on context usage
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 10)); EMPTY=$((10 - FILLED))
printf -v FILL "%${FILLED}s"; printf -v PAD "%${EMPTY}s"
BAR="${FILL// /█}${PAD// /░}"

TOK_IN_FMT=$(fmt_tokens "$TOK_IN")
TOK_MAX_FMT=$(fmt_tokens "$TOK_MAX")
if [[ "$TOK_OUT" =~ ^[0-9]+$ ]] && [ "$TOK_OUT" -gt 0 ]; then
    TOK_OUT_FMT=$(fmt_tokens "$TOK_OUT")
    TOKENS="${BAR_COLOR}${TOK_IN_FMT}↓${RESET} ${CYAN}${TOK_OUT_FMT}↑${RESET}${DIM} / ${TOK_MAX_FMT}${RESET}"
elif [ "$TOK_MAX" -gt 0 ]; then
    TOKENS="${BAR_COLOR}${TOK_IN_FMT}${RESET}${DIM} / ${TOK_MAX_FMT}${RESET}"
else
    TOKENS="${BAR_COLOR}${TOK_IN_FMT}${RESET}"
fi

MINS=$((DURATION_MS / 60000)); SECS=$(((DURATION_MS % 60000) / 1000))

# Convert git SSH URL (github.com, gitlab.com, self-hosted GitLab, etc.) to HTTPS
REMOTE=$(git -C "$DIR" remote get-url origin 2>/dev/null | sed -E 's#git@([^:]+):#https://\1/#' | sed 's/\.git$//')

if [ -n "$REMOTE" ]; then
    REPO_NAME=$(basename "$REMOTE")
    # OSC 8 format: \e]8;;URL\a then TEXT then \e]8;;\a; blue+underline makes it read as a link
    REPO="\e]8;;${REMOTE}\a${BLUE}${UNDERLINE}${REPO_NAME}${RESET}\e]8;;\a"
    REPO_ICON="🌳"
else
    REPO="${DIR##*/}"
    REPO_ICON="📁"
fi

BRANCH=""
if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH_NAME=$(git -C "$DIR" branch --show-current 2>/dev/null)
    if [ -n "$BRANCH_NAME" ]; then
        if [ -n "$REMOTE" ]; then
            # GitLab uses /-/tree/<branch>, GitHub (and most others) use /tree/<branch>
            case "$REMOTE" in
                *gitlab*) BRANCH_URL="${REMOTE}/-/tree/${BRANCH_NAME}" ;;
                *) BRANCH_URL="${REMOTE}/tree/${BRANCH_NAME}" ;;
            esac
            BRANCH_LINK="\e]8;;${BRANCH_URL}\a${BLUE}${UNDERLINE}${BRANCH_NAME}${RESET}\e]8;;\a"
        else
            BRANCH_LINK="$BRANCH_NAME"
        fi
        BRANCH=" | 🌿 $BRANCH_LINK"
    fi
fi

echo -e "${CYAN}[$MODEL]${RESET} ${REPO_ICON} $REPO$BRANCH"
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}% · ${TOKENS} | 🕒 ${MINS}m ${SECS}s"
