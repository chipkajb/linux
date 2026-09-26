---
name: hunk-review
description: Emit changeset review rationale for Hunk and optionally drive a live Hunk session. Use when reviewing agent-authored diffs, explaining a changeset, or when the user refers to hunk-review / hunk-context / a Hunk sidecar.
---

# Hunk review

Hunk is the terminal diff reviewer used for agent-authored changes. Feed it rationale
two ways.

## 1. Sidecar (preferred, viewer-neutral)

Write `.hunk/agent-context.json` through the installed helper so it is validated:

```bash
hunk-context write - <<'JSON'
{ "version": 1, "summary": "one-line intent for the whole changeset",
  "files": [
    { "path": "src/x.py", "summary": "what this file's change does",
      "annotations": [
        { "summary": "what changed here (required)",
          "rationale": "why, tradeoffs, risks",
          "newRange": [12, 20], "oldRange": [10, 14],
          "confidence": "high", "tags": ["risk"] } ] } ] }
JSON
```

- `newRange` / `oldRange` are 1-based inclusive `[start, end]`. Prefer `newRange`.
- `files[]` order sets review order — lead with the file that tells the clearest story.
- Annotate only what the reviewer would not spot themselves: intent, tradeoffs, risks,
  follow-ups. Do not annotate every hunk.
- The sidecar is gitignored and per-changeset. Re-run `hunk-context write` after edits;
  `hunk-context reload` pushes a refreshed sidecar into an already-open Hunk.
- `hunk-context show` / `clear` inspect and reset it.

The user reviews with `hunk-review` (defaults to `diff --watch` plus this sidecar).

## 2. Live session control (optional)

When the user has Hunk open and wants narration or to be steered:
`hunk session review --json`, `hunk session navigate --file X --new-line N`,
`hunk session comment add|apply`. Run `hunk skill path` and read that file for the full
live-session skill.

## 3. Read the user's inline notes and address them

The user can leave their own notes in the Hunk UI with `c`. They are session-scoped
(in-memory; gone when Hunk closes) and are NOT written to the sidecar. To read them:

```bash
hunk-context notes          # = hunk session comment list --repo . --type user --json
```

Returns entries with `filePath` / line / `summary`. Address each by editing the file,
then refresh the review with `hunk-context write` + `hunk-context reload`. This is the
review -> feedback -> fix loop; it requires Hunk to be open concurrently.

## Rules

- Never run bare `hunk diff`, `hunk show`, or `hunk patch` yourself — they open interactive
  TUIs. Use `hunk-context` and `hunk session`.
- When the user says they left notes / comments in Hunk, read them with `hunk-context notes`
  before making changes.
- Staging and reverting are out of scope for Hunk. Use git or Neovim gitsigns
  (`<leader>ga` stage hunk, `<leader>gr` reset hunk, visual range for partial lines).
