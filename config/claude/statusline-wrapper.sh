#!/bin/bash
# Status line wrapper:
#   line 1-2 -> statusline.sh
#   line 3 -> plan usage: 5-hour session + weekly limit (% used, reset time)
#
# rate_limits comes from Claude Code itself (Pro/Max only, after the first API
# response), so the line is omitted until then.

input=$(cat)

DIM='\033[90m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; RESET='\033[0m'

# --- two-line status line ------------------------------------------------------
printf '%s' "$input" | bash "$HOME/.claude/statusline.sh"

# --- plan usage line -------------------------------------------------------------
# usage <label> <window> <date fmt>: "label 24% · resets <time>", colored by %
usage() {
    local pct reset color
    pct=$(printf '%s' "$input" | jq -r ".rate_limits.$2.used_percentage // empty" | cut -d. -f1)
    reset=$(printf '%s' "$input" | jq -r ".rate_limits.$2.resets_at // empty")
    [[ "$pct" =~ ^[0-9]+$ ]] || return
    if   [ "$pct" -ge 90 ]; then color="$RED"
    elif [ "$pct" -ge 70 ]; then color="$YELLOW"
    else color="$GREEN"; fi
    printf "${DIM}%s ${RESET}${color}%s%%${RESET}" "$1" "$pct"
    [[ "$reset" =~ ^[0-9]+$ ]] && printf "${DIM} · resets %s${RESET}" "$(date -d "@$reset" +"$3")"
}

session=$(usage "⏳ session" five_hour '%-I:%M%P')
weekly=$(usage "📅 weekly" seven_day '%a %-I:%M%P')
line="$session"
[ -n "$weekly" ] && line="${line:+$line${DIM} | ${RESET}}$weekly"
if [ -n "$line" ]; then printf '%b\n' "$line"; fi
