#!/usr/bin/env bash
# Linux dotfiles setup — interactive menu and non-interactive CLI.
#
#   ./setup.sh                 interactive menu
#   ./setup.sh list            list available steps
#   ./setup.sh all             run every step
#   ./setup.sh install <name>  run one or more steps by name
#   ./setup.sh --help
#
# Steps live in setup/*.sh and are idempotent; re-running is safe.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

# shellcheck source=lib/log.sh
. "$REPO_ROOT/lib/log.sh"
# shellcheck source=lib/common.sh
. "$REPO_ROOT/lib/common.sh"

# Modules are sourced in filename order; 00-preflight.sh must come first.
for module in "$REPO_ROOT"/setup/*.sh; do
    # shellcheck source=/dev/null
    . "$module"
done

# name|label|function
STEPS=(
    "links|Link CLI tools into /usr/local/bin|step_links"
    "zsh|zsh shell, oh-my-zsh, starship, atuin, uv|step_zsh"
    "vim|vim + Vundle plugins|step_vim"
    "neovim|Neovim (NvChad), LSP, treesitter|step_neovim"
    "vscode|VS Code + extensions|step_vscode"
    "tmux|tmux + TPM|step_tmux"
    "i3|i3, rofi, dunst, picom, GTK theme|step_i3"
    "alacritty|alacritty + themes|step_alacritty"
    "monitors|Monitor profiles (office/home/laptop)|step_monitors"
    "misc|CLI tools, fff-mcp, Hunk, gedit|step_misc"
    "claude|Claude Code + config|step_claude"
    "adlc|herdr, caveman, superpowers|step_adlc"
)

usage() {
    cat <<EOF
$(ui::bold "Linux dotfiles setup")

$(ui::bold "Usage")
  ./setup.sh                 interactive menu
  ./setup.sh list            list available steps
  ./setup.sh all             run every step
  ./setup.sh install NAME…   run one or more steps
  ./setup.sh --help

$(ui::bold "Examples")
  ./setup.sh install zsh i3 monitors
  ./setup.sh all
EOF
}

step_names() {
    local entry
    for entry in "${STEPS[@]}"; do
        printf '%s\n' "${entry%%|*}"
    done
}

step_label() {
    local entry
    for entry in "${STEPS[@]}"; do
        if [[ "${entry%%|*}" == "$1" ]]; then
            printf '%s' "$(cut -d'|' -f2 <<<"$entry")"
            return 0
        fi
    done
    return 1
}

step_fn() {
    local entry
    for entry in "${STEPS[@]}"; do
        if [[ "${entry%%|*}" == "$1" ]]; then
            printf '%s' "$(cut -d'|' -f3 <<<"$entry")"
            return 0
        fi
    done
    return 1
}

run_named() {
    local name="$1" label fn
    if ! label="$(step_label "$name")"; then
        ui::err "unknown step: $name"
        ui::hint "available: $(step_names | tr '\n' ' ')"
        return 1
    fi
    fn="$(step_fn "$name")"
    run_step "$label" "$fn"
}

run_all() {
    local name failed=0
    for name in $(step_names); do
        run_named "$name" || failed=1
    done
    return "$failed"
}

print_menu() {
    ui::header "Linux dotfiles · setup" "Ubuntu ${UBUNTU_VERSION:-?} · $(step_names | wc -l) steps · idempotent"
    local i=1 entry name label
    for entry in "${STEPS[@]}"; do
        name="${entry%%|*}"
        label="$(cut -d'|' -f2 <<<"$entry")"
        printf '  %s  %-12s %s\n' "$(ui::bold "$(printf '%2d' "$i")")" "$(ui::aqua "$name")" "$label"
        i=$((i + 1))
    done
    printf '  %s  %-12s %s\n' "$(ui::bold ' a')" "$(ui::purple 'all')" "run every step"
    printf '  %s  %-12s %s\n' "$(ui::bold ' 0')" "$(ui::purple 'exit')" "quit"
}

menu_loop() {
    while true; do
        print_menu
        printf '\n%s ' "$(ui::gray 'select>')"
        local input
        read -r input || break
        case "$input" in
            0 | q | quit | exit)
                ui::info "bye"
                return 0
                ;;
            a | all)
                run_all || true
                ;;
            '')
                ;;
            *[!0-9]*)
                run_named "$input" || true
                ;;
            *)
                local name
                name="$(step_names | sed -n "${input}p")"
                if [[ -n "$name" ]]; then
                    run_named "$name" || true
                else
                    ui::err "bad selection: $input"
                fi
                ;;
        esac
    done
}

main() {
    detect_ubuntu

    case "${1:-}" in
        -h | --help | help)
            usage
            ;;
        list)
            local name
            for name in $(step_names); do
                printf '  %-12s %s\n' "$(ui::aqua "$name")" "$(step_label "$name")"
            done
            ;;
        all)
            run_all
            ;;
        install)
            shift
            (($#)) || {
                ui::err "install requires at least one step name"
                usage
                exit 2
            }
            local rc=0 name
            for name in "$@"; do
                run_named "$name" || rc=1
            done
            exit "$rc"
            ;;
        '')
            menu_loop
            ;;
        *)
            ui::err "unknown argument: $1"
            usage
            exit 2
            ;;
    esac
}

main "$@"
