#!/usr/bin/env bash
#
# sync-pi-setup - mirror this machine's Pi setup to remote hosts over rsync.
#
# Reads three files from the skill directory:
#   manifest.txt  paths to sync
#   excludes.txt  protected paths, applied to every transfer
#   targets.txt   default remote hosts
#
set -euo pipefail

SKILL_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${SKILL_DIR}/manifest.txt"
EXCLUDES="${SKILL_DIR}/excludes.txt"

# Host names stay out of the public repo. Prefer the gitignored local override.
defaults_file() {
  if [[ -r "${SKILL_DIR}/targets.local.txt" ]]; then
    printf '%s' "${SKILL_DIR}/targets.local.txt"
  else
    printf '%s' "${SKILL_DIR}/targets.txt"
  fi
}

DRY_RUN=0
VERBOSE=0
DELETE=1
POST=0
ALL_HOSTS=0
LIST_TARGETS=0
TARGETS=()

usage() {
  cat <<'EOF'
Mirror this machine's Pi setup to remote hosts over rsync.

Usage:
  sync-pi-setup.sh [options] [host ...]

Options:
  -t, --target HOST   Add a target. Repeatable. Defaults to targets.txt.
  -a, --all-hosts     Use every concrete Host alias in ~/.ssh/config.
      --list-targets  Print candidate targets and exit.
  -n, --dry-run       Report changes. Transfer nothing.
      --no-delete     Keep remote files that are missing locally.
      --post          Install the local Pi version on each target.
  -v, --verbose       Print each transferred path.
  -h, --help          Show this help.

Targets are ssh host aliases resolved by ~/.ssh/config.
EOF
}

log()  { printf '%s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

list_ssh_hosts() {
  [[ -r "$HOME/.ssh/config" ]] || return 0
  awk 'tolower($1)=="host" { for (i=2; i<=NF; i++) if ($i !~ /[*?!]/) print $i }' \
    "$HOME/.ssh/config"
}

read_defaults() {
  local line file
  file="$(defaults_file)"
  [[ -r "$file" ]] || return 0
  if [[ $VERBOSE -eq 1 ]]; then log "  targets from $file"; fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(trim "$line")"
    [[ -z "$line" ]] && continue
    TARGETS+=("$line")
  done < "$file"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--target)   [[ $# -ge 2 ]] || die "$1 needs a host"; TARGETS+=("$2"); shift 2 ;;
      -a|--all-hosts) ALL_HOSTS=1; shift ;;
      --list-targets) LIST_TARGETS=1; shift ;;
      -n|--dry-run)  DRY_RUN=1; shift ;;
      --no-delete)   DELETE=0; shift ;;
      --post)        POST=1; shift ;;
      -v|--verbose)  VERBOSE=1; shift ;;
      -h|--help)     usage; exit 0 ;;
      -*)            die "unknown option: $1" ;;
      *)             TARGETS+=("$1"); shift ;;
    esac
  done
}

preflight() {
  [[ -r "$MANIFEST" ]] || die "manifest not found: $MANIFEST"
  [[ -r "$EXCLUDES" ]] || die "excludes not found: $EXCLUDES"
  command -v rsync >/dev/null || die "rsync not installed locally"
  command -v ssh   >/dev/null || die "ssh not installed locally"
}

sync_entry() {
  local target="$1" src="$2" dst="$3" extra="$4"
  local -a flags=(-rltpDz --human-readable --mkpath
                  --exclude-from="$EXCLUDES"
                  --info=stats1)

  if [[ $DELETE -eq 1 ]]; then flags+=(--delete); fi
  if [[ $DRY_RUN -eq 1 ]]; then flags+=(--dry-run); fi
  if [[ $VERBOSE -eq 1 ]]; then flags+=(--info=name); fi
  if [[ -n "$extra" ]]; then
    # shellcheck disable=SC2206
    flags+=($extra)
  fi

  if [[ ! -e "$src" ]]; then
    log "  skip   $src (missing locally)"
    return 0
  fi

  rsync "${flags[@]}" "$src" "${target}:${dst}"
}

sync_target() {
  local target="$1" line src dst extra

  log "==> $target"
  if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$target" true 2>/dev/null; then
    log "  FAIL   cannot reach $target over ssh (check ~/.ssh/config and keys)"
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ -z "$(trim "$line")" ]] && continue
    IFS='|' read -r src dst extra <<< "$line"
    src="$(trim "$src")"; dst="$(trim "$dst")"; extra="$(trim "$extra")"
    [[ -z "$src" || -z "$dst" ]] && die "bad manifest line: $line"
    src="${src/#\~/$HOME}"
    sync_entry "$target" "$src" "$dst" "$extra"
  done < "$MANIFEST"

  if [[ $POST -eq 1 ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      log "  post   (skipped in dry-run)"
    else
      post_sync "$target"
    fi
  fi
}

local_pi_version() {
  local root pkg
  root="$(npm root -g 2>/dev/null)" || return 0
  pkg="${root}/@earendil-works/pi-coding-agent/package.json"
  [[ -r "$pkg" ]] || return 0
  node -p "require('${pkg}').version" 2>/dev/null || true
}

post_sync() {
  local target="$1" ver pkg cmd
  ver="$(local_pi_version)"
  pkg="@earendil-works/pi-coding-agent${ver:+@$ver}"
  log "  post   installing $pkg on $target"

  # $pkg expands here on purpose, so the remote shell gets a pinned version.
  cmd="export NVM_DIR=\$HOME/.nvm
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    command -v nvm >/dev/null && nvm use 22 >/dev/null 2>&1
    npm install -g $pkg"
  # shellcheck disable=SC2029  # $cmd expands locally on purpose; the remote shell runs it
  ssh "$target" "$cmd"
}

main() {
  parse_args "$@"
  preflight
  [[ ${#TARGETS[@]} -eq 0 ]] && read_defaults
  if [[ $ALL_HOSTS -eq 1 ]]; then
    while IFS= read -r h; do TARGETS+=("$h"); done < <(list_ssh_hosts)
  fi

  if [[ $LIST_TARGETS -eq 1 ]]; then
    printf 'file:     %s\n' "$(defaults_file)"
    printf 'default:  %s\n' "${TARGETS[*]:-none}"
    printf 'ssh cfg:  %s\n' "$(list_ssh_hosts | tr '\n' ' ')"
    exit 0
  fi

  [[ ${#TARGETS[@]} -gt 0 ]] || die "no targets. Pass a host or edit targets.txt"

  local failed=0
  for target in "${TARGETS[@]}"; do
    sync_target "$target" || failed=1
  done
  [[ $failed -eq 0 ]] || die "one or more targets failed"
  log "done."
}

main "$@"
