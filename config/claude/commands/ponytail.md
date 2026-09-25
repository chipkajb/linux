---
description: Toggle ponytail (lazy-senior-engineer) mode on or off
allowed-tools: Bash(bash $HOME/.claude/hooks/ponytail-toggle.sh *)
---
Run this and report the result verbatim, nothing else:

```bash
bash "$HOME/.claude/hooks/ponytail-toggle.sh" "${ARGUMENTS:-toggle}"
```

If `${ARGUMENTS}` is empty, first read the current state with
`bash "$HOME/.claude/hooks/ponytail-toggle.sh" status`, then flip it
(on -> off, off -> on). The change takes effect next session start, since the
ruleset is injected as SessionStart context.
