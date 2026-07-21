#!/usr/bin/env bash
# Back-compat wrapper — see patch-jmux.sh
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/patch-jmux.sh" "$@"
