#!/usr/bin/env bash
#
# Install the git clean filter that keeps machine-local ssh host aliases out of
# config/vscode/settings.json. Run once per machine. See README.md.
#
set -euo pipefail

# Drop every entry inside the remote.SSH.remotePlatform object. The object stays
# in place and empty, so the file remains valid.
#
# Host aliases are local state, not config. They live in ~/.ssh/config, which
# this repo does not track. A host-name list here would need an edit per server.
clean=$(cat <<'CMD'
awk '/"remote\.SSH\.remotePlatform"[[:space:]]*:[[:space:]]*\{/ {print; inb=1; next} inb && /^[[:space:]]*\}/ {inb=0; print; next} inb {next} {print}'
CMD
)

git config --global filter.strip-local-hosts.clean "$clean"
git config --global filter.strip-local-hosts.smudge cat

printf 'installed clean filter "strip-local-hosts" in ~/.gitconfig\n'
