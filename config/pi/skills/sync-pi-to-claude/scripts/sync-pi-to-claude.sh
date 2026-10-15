#!/usr/bin/env bash
#
# sync-pi-to-claude - mirror this machine's pi setup into Claude Code.
#
# The script links pi skills and prompt files into the Claude Code config
# directory. Pi is the source. Claude Code is the target. The script never
# overwrites a real path, and it never removes a link that it does not manage.
#
# Reads two files from the skill directory:
#   manifest.txt  pi sources and claude destinations
#   exclude.txt   names that Claude Code already provides
#
set -euo pipefail

SKILL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${SKILL_DIR}/manifest.txt"
EXCLUDE_FILE="${SKILL_DIR}/exclude.txt"

DRY_RUN=0
PRUNE=0
VERBOSE=0

MANIFEST_ENTRIES=()
SOURCE_ROOTS=()
DEST_DIRS=()
declare -A EXPECTED=()
declare -A EXCLUDED=()

log() { printf '%s\n' "$*" >&2; }
vlog() { if [[ $VERBOSE -eq 1 ]]; then printf '%s\n' "$*" >&2; fi; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Mirror this machine's pi setup into Claude Code.

Usage:
  sync-pi-to-claude.sh [options]

Options:
  -n, --dry-run   Report changes. Change nothing.
      --prune     Remove managed links that the manifest no longer lists.
  -v, --verbose   Print every path.
  -h, --help      Show this help.

The script links pi skills and prompt files into ~/.claude. It reads
manifest.txt and exclude.txt from the skill directory.
EOF
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

expand_tilde() { printf '%s' "${1/#\~/$HOME}"; }

ensure_dir() {
    [[ -d "$1" ]] && return 0
    [[ $DRY_RUN -eq 1 ]] && return 0
    mkdir -p "$1"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --dry-run) DRY_RUN=1; shift ;;
            --prune) PRUNE=1; shift ;;
            -v | --verbose) VERBOSE=1; shift ;;
            -h | --help) usage; exit 0 ;;
            *) die "unknown option: $1" ;;
        esac
    done
}

load_excludes() {
    [[ -r "$EXCLUDE_FILE" ]] || return 0
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(trim "$line")"
        [[ -z "$line" ]] && continue
        EXCLUDED["$line"]=1
    done < "$EXCLUDE_FILE"
}

read_manifest() {
    [[ -r "$MANIFEST" ]] || die "manifest not found: $MANIFEST"
    local line src dst kind
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        [[ -z "$(trim "$line")" ]] && continue
        IFS='|' read -r src dst kind <<< "$line"
        src="$(expand_tilde "$(trim "$src")")"
        dst="$(expand_tilde "$(trim "$dst")")"
        kind="$(trim "$kind")"
        [[ -n "$src" && -n "$dst" && -n "$kind" ]] || die "bad manifest line: $line"
        case "$kind" in
            skill | command) ;;
            *) die "unknown kind '$kind' in manifest line: $line" ;;
        esac
        MANIFEST_ENTRIES+=("${src%/}|${dst%/}|$kind")
        SOURCE_ROOTS+=("${src%/}")
        DEST_DIRS+=("${dst%/}")
    done < "$MANIFEST"
}

# owned <link> - true when the link target is inside a manifest source.
owned() {
    local link="$1" tgt root
    tgt="$(readlink "$link" 2>/dev/null)" || return 1
    for root in "${SOURCE_ROOTS[@]}"; do
        [[ "$tgt" == "$root"/* ]] && return 0
    done
    return 1
}

# link_one <source> <dest> - create or refresh one managed link.
link_one() {
    local src="$1" dest="$2"
    if [[ -L "$dest" ]]; then
        if [[ "$(readlink "$dest")" == "$src" ]]; then
            vlog "  ok     $dest"
            return 0
        fi
        if owned "$dest"; then
            if [[ $DRY_RUN -eq 1 ]]; then
                log "  update $dest -> $src"
            else
                ln -sfn "$src" "$dest"
                vlog "  update $dest"
            fi
            return 0
        fi
        log "  keep   $dest (link not managed by this tool)"
        return 0
    fi
    if [[ -e "$dest" ]]; then
        log "  keep   $dest (real path, not a link)"
        return 0
    fi
    if [[ $DRY_RUN -eq 1 ]]; then
        log "  add    $dest -> $src"
    else
        ln -sfn "$src" "$dest"
        vlog "  add    $dest"
    fi
}

# link_skill_dir <source dir> <dest dir> - link each skill subdirectory.
link_skill_dir() {
    local src="$1" dst="$2" entry name dest
    for entry in "$src"/*/; do
        [[ -d "$entry" ]] || continue
        entry="${entry%/}"
        [[ -f "$entry/SKILL.md" ]] || continue
        name="$(basename "$entry")"
        if [[ -n "${EXCLUDED[$name]:-}" ]]; then
            vlog "  skip   $name (excluded)"
            continue
        fi
        dest="$dst/$name"
        if [[ -n "${EXPECTED[$dest]:-}" ]]; then
            log "  clash  $dest (also provided by ${EXPECTED[$dest]})"
            continue
        fi
        EXPECTED["$dest"]="$entry"
        link_one "$entry" "$dest"
    done
}

# link_command_dir <source dir> <dest dir> - link each *.md file.
link_command_dir() {
    local src="$1" dst="$2" entry name dest
    for entry in "$src"/*.md; do
        [[ -f "$entry" ]] || continue
        name="$(basename "$entry")"
        if [[ -n "${EXCLUDED[$name]:-}" ]]; then
            vlog "  skip   $name (excluded)"
            continue
        fi
        dest="$dst/$name"
        if [[ -n "${EXPECTED[$dest]:-}" ]]; then
            log "  clash  $dest (also provided by ${EXPECTED[$dest]})"
            continue
        fi
        EXPECTED["$dest"]="$entry"
        link_one "$entry" "$dest"
    done
}

sync_entry() {
    local src="$1" dst="$2" kind="$3"
    if [[ ! -d "$src" ]]; then
        log "  skip   $src (missing)"
        return 0
    fi
    ensure_dir "$dst"
    case "$kind" in
        skill) link_skill_dir "$src" "$dst" ;;
        command) link_command_dir "$src" "$dst" ;;
    esac
}

# prune - remove managed links that the manifest no longer lists.
prune() {
    local dir link
    for dir in "${DEST_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        for link in "$dir"/*; do
            [[ -L "$link" ]] || continue
            owned "$link" || continue
            [[ -n "${EXPECTED[$link]:-}" ]] && continue
            if [[ $DRY_RUN -eq 1 ]]; then
                log "  prune  $link"
            else
                rm -f "$link"
                vlog "  prune  $link"
            fi
        done
    done
}

main() {
    parse_args "$@"
    load_excludes
    read_manifest

    local entry entry_src entry_dst entry_kind
    for entry in "${MANIFEST_ENTRIES[@]}"; do
        IFS='|' read -r entry_src entry_dst entry_kind <<< "$entry"
        sync_entry "$entry_src" "$entry_dst" "$entry_kind"
    done

    if [[ $PRUNE -eq 1 ]]; then
        prune
    fi
    log "done."
}

main "$@"
