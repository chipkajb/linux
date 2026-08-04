#!/usr/bin/env python3
"""Hide staged (index) gutter diffs so dirty-diff navigation only visits unstaged hunks.

Since VS Code 1.100, shift+alt+[ / ] (editor.action.dirtydiff.*) cycles every visible
quick-diff provider — including staged changes (Git Local Changes (Index)).

Close Cursor/VS Code before running so state.vscdb is not locked.
"""

import json
import sqlite3
from pathlib import Path

STORAGE_KEY = "workbench.scm.quickDiffProviders.hidden"
STAGED_PROVIDER = "git.secondaryQuickDiffProvider"


def _state_databases(home: Path) -> list[Path]:
    databases: list[Path] = []
    for app in ("Code", "Cursor"):
        user = home / ".config" / app / "User"
        databases.append(user / "globalStorage" / "state.vscdb")
        profiles = user / "profiles"
        if profiles.is_dir():
            for profile in profiles.iterdir():
                if profile.is_dir():
                    databases.append(profile / "globalStorage" / "state.vscdb")
    return databases


def hide_staged_provider(db_path: Path) -> bool:
    if not db_path.is_file():
        return False

    conn = sqlite3.connect(db_path)
    row = conn.execute(
        "SELECT value FROM ItemTable WHERE key = ?", (STORAGE_KEY,)
    ).fetchone()
    hidden = json.loads(row[0]) if row else []
    if STAGED_PROVIDER in hidden:
        conn.close()
        return False

    hidden.append(STAGED_PROVIDER)
    conn.execute(
        "INSERT OR REPLACE INTO ItemTable (key, value) VALUES (?, ?)",
        (STORAGE_KEY, json.dumps(hidden)),
    )
    conn.commit()
    conn.close()
    return True


def main() -> None:
    home = Path.home()
    updated = [
        str(path)
        for path in _state_databases(home)
        if hide_staged_provider(path)
    ]

    if updated:
        print("Hidden staged gutter diffs in:")
        for path in updated:
            print(f"  {path}")
        print("Reload Cursor/VS Code — shift+alt+[ / ] will skip staged hunks.")
    else:
        print(
            "No databases updated (already configured, or no state.vscdb found)."
        )


if __name__ == "__main__":
    main()
