# ai-suggest.zsh — LLM-backed inline completion for zsh.
#
# Registers an `ai` strategy for zsh-autosuggestions. It sends the current
# command line, the working directory, the git branch, and recent history to a
# Fireworks model, and shows the answer as ghost text.
#
# zsh-autosuggestions forks each strategy into a subshell and reads the reply
# through a pipe, so the model call never blocks the prompt. The fork is
# cancelled when the line changes, so stale answers are dropped.
#
# Keys are bound in config/zshrc:
#   Right        accept the whole suggestion
#   Ctrl+Right   accept one word
#
# Env:
#   FIREWORKS_API_KEY     required; the strategy is inert without it
#   AI_SUGGEST_THROTTLE   seconds between requests (default 0.7)
#   AI_SUGGEST_OFF        set to 1 to disable on this host
#
# The context goes to a third party. Neovim sends the same kind of content, so
# there is no separate rule for remote shells: set AI_SUGGEST_OFF=1 in
# ~/.zsh_local on a host where you would rather it stayed quiet.

zmodload zsh/datetime 2>/dev/null

_ai_suggest_stamp_file() {
    local dir="${XDG_CACHE_HOME:-$HOME/.cache}/ai-cli"
    [[ -d $dir ]] || mkdir -p "$dir" 2>/dev/null
    print -r -- "$dir/stamp"
}

# ponytail: no result cache. The throttle plus the plugin's request
# cancellation already stops the burst. Add a cache only if the request count
# turns into a cost problem.
#
# True when the last request is too recent to send another one.
_ai_suggest_throttled() {
    local stamp now last=0
    stamp="$(_ai_suggest_stamp_file)"
    now=${EPOCHREALTIME:-0}
    [[ -r $stamp ]] && last=$(<"$stamp" 2>/dev/null || print -r -- 0)
    if ((now - last < ${AI_SUGGEST_THROTTLE:-0.7})); then
        return 0
    fi
    print -rn -- "$now" >|"$stamp" 2>/dev/null
    return 1
}

_zsh_autosuggest_strategy_ai() {
    emulate -L zsh
    setopt extended_glob

    typeset -g suggestion=''

    [[ -n ${AI_SUGGEST_OFF:-} ]] && return 0
    [[ -n ${FIREWORKS_API_KEY:-} ]] || return 0
    (( $+commands[ai] )) || return 0

    local buffer="$1"

    # Ask when the line is empty (predict the next command) or when the cursor
    # sits where an argument or flag goes. Mid-word, the completion system and
    # history are both faster and usually right.
    if [[ -n $buffer ]]; then
        [[ $buffer == *[[:space:]-] ]] || return 0
        (( ${#buffer} >= 3 )) || return 0
    fi

    _ai_suggest_throttled && return 0

    local branch=''
    if git rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    fi

    local reply
    reply=$(
        print -rl -- "${history[1,25]}" |
            ai complete --buffer "$buffer" --cwd "$PWD" --branch "$branch" 2>/dev/null
    )

    [[ -n $reply ]] || return 0
    # one line only; a multi-line answer would corrupt the prompt
    reply=${reply%%$'\n'*}
    suggestion=$reply
}
