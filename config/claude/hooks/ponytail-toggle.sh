#!/usr/bin/env bash
# Toggle ponytail mode outside a session: ponytail-toggle.sh on|off|status
set -euo pipefail
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.ponytail-active"
case "${1:-status}" in
  on)     printf 'on\n' > "$FLAG"; echo "ponytail ON" ;;
  off)    rm -f "$FLAG";           echo "ponytail OFF" ;;
  status) [[ "$(cat "$FLAG" 2>/dev/null)" == "on" ]] && echo "ponytail ON" || echo "ponytail OFF" ;;
  *)      echo "usage: $(basename "$0") on|off|status" >&2; exit 2 ;;
esac
