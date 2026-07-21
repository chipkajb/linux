#!/usr/bin/env bash
# Local jmux fixes (re-run after `bun update -g @jx0/jmux`):
#   1) Ctrl-Space prefix — jmux hardcodes Ctrl-a for palette / new-session / diff
#   2) Cursor sync — toolbar offset tracks toolbarRows; clear on SIGWINCH
#   3) Autowrap scroll — disable wrap while painting so the bottom-right cell
#      cannot scroll the alt screen (cursor permanently one row below text)

set -euo pipefail

JMUX_ROOT="${JMUX_ROOT:-$HOME/.bun/install/global/node_modules/@jx0/jmux}"
if [ ! -d "$JMUX_ROOT/src" ]; then
    printf 'jmux package not found at %s\n' "$JMUX_ROOT" >&2
    exit 1
fi

python3 - "$JMUX_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

def once(path: Path, marker: str, apply):
    text = path.read_text()
    if marker in text:
        print(f"already patched ({marker}) {path}")
        return text
    new = apply(text)
    if new is None:
        sys.exit(f"failed to apply {marker} in {path}")
    path.write_text(new)
    print(f"patched ({marker}) {path}")
    return new

# --- input-router.ts ---
router = root / "src" / "input-router.ts"

def patch_router(text: str):
    if 'private prefixByte = "\\x01";' not in text and "private prefixSeen = false;" in text:
        text = text.replace(
            "  private prefixSeen = false;",
            "  private prefixSeen = false;\n"
            "  // CTRL_SPACE_PREFIX_PATCH: remember which prefix byte armed the chord\n"
            '  private prefixByte = "\\x01";',
            1,
        )
    text = text.replace(
        '          if (deferred) this.opts.onPtyData("\\x01");',
        "          // CTRL_SPACE_PREFIX_PATCH\n"
        "          if (deferred) this.opts.onPtyData(this.prefixByte);",
    )
    old = '      } else if (data === "\\x01") {\n        this.prefixSeen = true;'
    new = (
        '      } else if (data === "\\x00" || data === "\\x01") {\n'
        "        // CTRL_SPACE_PREFIX_PATCH: Ctrl-Space (\\\\x00) or Ctrl-a (\\\\x01)\n"
        "        this.prefixByte = data;\n"
        "        this.prefixSeen = true;"
    )
    if old not in text:
        return None
    return text.replace(old, new, 1)

once(router, "CTRL_SPACE_PREFIX_PATCH", patch_router)

# --- main.ts ---
main = root / "src" / "main.ts"
text = main.read_text()
if 'pty.write("\\x01d")' in text:
    text = text.replace(
        'pty.write("\\x01d");',
        '// CTRL_SPACE_PREFIX_PATCH: match tmux prefix C-Space\n'
        '  pty.write("\\x00d");',
        1,
    )
    print(f"patched detach prefix in {main}")
elif 'pty.write("\\x00d")' in text:
    print(f"already patched detach prefix in {main}")
else:
    sys.exit(f"main.ts: detach write pattern not found in {main}")

if "CURSOR_RESIZE_SYNC_PATCH" not in text:
    old = "  renderFrame();\n});\n\n// --- Config file watcher ---"
    new = (
        "  // CURSOR_RESIZE_SYNC_PATCH: clear + drop row-diff cache so a shrink\n"
        "  // cannot scroll the real terminal and leave the cursor off-by-one.\n"
        '  process.stdout.write("\\x1b[H\\x1b[2J");\n'
        "  renderer.invalidate();\n"
        "  renderFrame();\n"
        "});\n\n"
        "// --- Config file watcher ---"
    )
    if old not in text:
        sys.exit(f"main.ts: SIGWINCH tail pattern not found in {main}")
    text = text.replace(old, new, 1)
    print(f"patched SIGWINCH resync in {main}")
else:
    print(f"already patched SIGWINCH resync in {main}")
main.write_text(text)

# --- command-palette.ts ---
palette = root / "src" / "command-palette.ts"

def patch_palette(text: str):
    old = '    // Ctrl-a: buffer it\n    if (data === "\\x01") {'
    new = (
        "    // CTRL_SPACE_PREFIX_PATCH: Ctrl-Space or Ctrl-a buffer for close chord\n"
        '    if (data === "\\x00" || data === "\\x01") {'
    )
    if old not in text:
        return None
    return text.replace(old, new, 1)

once(palette, "CTRL_SPACE_PREFIX_PATCH", patch_palette)

# --- renderer.ts ---
renderer = root / "src" / "renderer.ts"
text = renderer.read_text()

if "invalidate():" not in text:
    old = (
        "export class Renderer {\n"
        "  private prevAttrs: Cell | null = null;\n"
        "  private prevGrid: CellGrid | null = null;\n"
        "  private lastMouseModeTime = 0;\n"
    )
    new = (
        "export class Renderer {\n"
        "  private prevAttrs: Cell | null = null;\n"
        "  private prevGrid: CellGrid | null = null;\n"
        "  private lastMouseModeTime = 0;\n"
        "\n"
        "  // CURSOR_RESIZE_SYNC_PATCH\n"
        "  invalidate(): void {\n"
        "    this.prevGrid = null;\n"
        "    this.prevAttrs = null;\n"
        "  }\n"
    )
    if old not in text:
        sys.exit(f"renderer.ts: class header not found in {renderer}")
    text = text.replace(old, new, 1)
    print(f"patched invalidate() in {renderer}")
else:
    print(f"already patched invalidate() in {renderer}")

# Narrow-window overlays: don't drop toolbar/palette/diff when sidebar is hidden
if "NO_SIDEBAR_COMPOSITE_PATCH" not in text:
    old = (
        "): CellGrid {\n"
        "  if (!sidebar) return main;\n"
        "\n"
        "  const mainCols = toolbar ? toolbar.mainCols : main.cols;\n"
        "  let contentCols: number;\n"
        "  if (diffPanel) {\n"
        "    if (diffPanel.mode === \"split\") {\n"
        "      contentCols = mainCols + 1 + diffPanel.grid.cols; // main + divider + diff\n"
        "    } else {\n"
        "      contentCols = diffPanel.grid.cols; // full: diff replaces main\n"
        "    }\n"
        "  } else {\n"
        "    contentCols = mainCols;\n"
        "  }\n"
        "  const totalCols = sidebar.cols + 1 + contentCols;\n"
        "  const toolbarRows = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n"
        "  const totalRows = main.rows + toolbarRows;\n"
        "  const grid = createGrid(totalCols, totalRows);\n"
        "\n"
        "  for (let y = 0; y < totalRows; y++) {\n"
        "    // Copy sidebar cells\n"
        "    for (let x = 0; x < sidebar.cols && x < sidebar.cells[y]?.length; x++) {\n"
        "      grid.cells[y][x] = { ...sidebar.cells[y][x] };\n"
        "    }\n"
        "    // Border column\n"
        "    const borderCol = sidebar.cols;\n"
        "    grid.cells[y][borderCol] = {\n"
        "      ...DEFAULT_CELL,\n"
        "      char: BORDER_CHAR,\n"
        "      fg: 8,\n"
        "      fgMode: ColorMode.Palette,\n"
        "    };\n"
        "\n"
        "    if (toolbar && y < toolbarRows) {\n"
    )
    new = (
        "): CellGrid {\n"
        "  // NO_SIDEBAR_COMPOSITE_PATCH: upstream returned `main` whenever sidebar was\n"
        "  // null (window < 80 cols), which also dropped toolbar / command palette /\n"
        "  // diff panel. Keep the fast-path only when there is truly nothing to layer.\n"
        "  if (!sidebar && !toolbar && !modalOverlay && !diffPanel) return main;\n"
        "\n"
        "  const mainCols = toolbar ? toolbar.mainCols : main.cols;\n"
        "  let contentCols: number;\n"
        "  if (diffPanel) {\n"
        "    if (diffPanel.mode === \"split\") {\n"
        "      contentCols = mainCols + 1 + diffPanel.grid.cols; // main + divider + diff\n"
        "    } else {\n"
        "      contentCols = diffPanel.grid.cols; // full: diff replaces main\n"
        "    }\n"
        "  } else {\n"
        "    contentCols = mainCols;\n"
        "  }\n"
        "  const sidebarCols = sidebar?.cols ?? 0;\n"
        "  // contentOrigin: first column of main/toolbar area. Without a sidebar there\n"
        "  // is no border column; borderCol is kept as contentOrigin-1 so existing\n"
        "  // `borderCol + 1 + …` math still resolves to contentOrigin.\n"
        "  const contentOrigin = sidebar ? sidebarCols + 1 : 0;\n"
        "  const totalCols = contentOrigin + contentCols;\n"
        "  const toolbarRows = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n"
        "  const totalRows = main.rows + toolbarRows;\n"
        "  const grid = createGrid(totalCols, totalRows);\n"
        "\n"
        "  for (let y = 0; y < totalRows; y++) {\n"
        "    if (sidebar) {\n"
        "      for (let x = 0; x < sidebarCols && x < sidebar.cells[y]?.length; x++) {\n"
        "        grid.cells[y][x] = { ...sidebar.cells[y][x] };\n"
        "      }\n"
        "      grid.cells[y][sidebarCols] = {\n"
        "        ...DEFAULT_CELL,\n"
        "        char: BORDER_CHAR,\n"
        "        fg: 8,\n"
        "        fgMode: ColorMode.Palette,\n"
        "      };\n"
        "    }\n"
        "    const borderCol = contentOrigin - 1;\n"
        "\n"
        "    if (toolbar && y < toolbarRows) {\n"
    )
    if old not in text:
        sys.exit(f"renderer.ts: compositeGrids header not found in {renderer}")
    text = text.replace(old, new, 1)
    text = text.replace(
        "    const sidebarOffset = sidebar.cols + 1;\n",
        "    const sidebarOffset = contentOrigin;\n",
        1,
    )
    text = text.replace(
        "    const mainStart = sidebar.cols + 1;\n",
        "    const mainStart = contentOrigin;\n",
        1,
    )
    print(f"patched no-sidebar composite in {renderer}")
else:
    print(f"already patched no-sidebar composite in {renderer}")

# Dynamic toolbar cursor offset (upstream still hardcodes 1).
if "toolbar.toolbarRows ?? 1" not in text.split("position cursor")[-1][:500]:
    old = (
        "    // Reset attributes, position cursor\n"
        "    const cursorRowOffset = toolbar ? 1 : 0;\n"
        '    buf.push("\\x1b[0m");\n'
        "    if (modalCursor != null) {\n"
        "      // Modal cursor is in absolute grid coordinates\n"
        '      buf.push(`\\x1b[${modalCursor.row + 1};${modalCursor.col + 1}H`);\n'
        '      buf.push("\\x1b[?25h");\n'
        "    } else if (diffPanel?.focused) {\n"
        '      buf.push("\\x1b[?25l"); // hide cursor when diff panel focused\n'
        "    } else {\n"
        "      buf.push(\n"
        "        `\\x1b[${cursor.y + cursorRowOffset + 1};${cursor.x + cursorOffset + 1}H`,\n"
        "      );\n"
        '      buf.push("\\x1b[?25h");\n'
        "    }"
    )
    new = (
        "    // Reset attributes, position cursor\n"
        "    // CURSOR_RESIZE_SYNC_PATCH: match composite toolbarRows; clamp to term size.\n"
        "    // NO_SIDEBAR_COMPOSITE_PATCH: toolbar is composited even when sidebar is hidden.\n"
        "    const cursorRowOffset = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n"
        "    const termRows = process.stdout.rows || 24;\n"
        "    const termCols = process.stdout.columns || 80;\n"
        '    buf.push("\\x1b[0m");\n'
        "    if (modalCursor != null) {\n"
        "      // Modal cursor is in absolute grid coordinates\n"
        "      const mr = Math.max(0, Math.min(modalCursor.row, termRows - 1));\n"
        "      const mc = Math.max(0, Math.min(modalCursor.col, termCols - 1));\n"
        '      buf.push(`\\x1b[${mr + 1};${mc + 1}H`);\n'
        '      buf.push("\\x1b[?25h");\n'
        "    } else if (diffPanel?.focused) {\n"
        '      buf.push("\\x1b[?25l"); // hide cursor when diff panel focused\n'
        "    } else {\n"
        "      const cy = Math.max(0, Math.min(cursor.y + cursorRowOffset, termRows - 1));\n"
        "      const cx = Math.max(0, Math.min(cursor.x + cursorOffset, termCols - 1));\n"
        "      buf.push(\n"
        "        `\\x1b[${cy + 1};${cx + 1}H`,\n"
        "      );\n"
        '      buf.push("\\x1b[?25h");\n'
        "    }"
    )
    if old not in text:
        # migrate older (sidebar && toolbar) variant
        old2 = "    const cursorRowOffset = (sidebar && toolbar) ? (toolbar.toolbarRows ?? 1) : 0;\n"
        if old2 in text:
            text = text.replace(
                old2,
                "    // NO_SIDEBAR_COMPOSITE_PATCH: toolbar is composited even when sidebar is hidden.\n"
                "    const cursorRowOffset = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n",
                1,
            )
            print(f"migrated cursor offset in {renderer}")
        else:
            sys.exit(f"renderer.ts: cursor block not found in {renderer}")
    else:
        text = text.replace(old, new, 1)
        print(f"patched cursor offset in {renderer}")
else:
    # ensure we don't keep the obsolete (sidebar && toolbar) offset
    old2 = "    const cursorRowOffset = (sidebar && toolbar) ? (toolbar.toolbarRows ?? 1) : 0;\n"
    if old2 in text:
        text = text.replace(
            old2,
            "    // NO_SIDEBAR_COMPOSITE_PATCH: toolbar is composited even when sidebar is hidden.\n"
            "    const cursorRowOffset = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n",
            1,
        )
        print(f"migrated cursor offset in {renderer}")
    else:
        print(f"already patched cursor offset in {renderer}")

# Autowrap scroll fix
if "AUTOWRAP_SCROLL_PATCH" not in text:
    old = (
        "  ): void {\n"
        "    const grid = compositeGrids(main, sidebar, toolbar, modalOverlay, diffPanel);\n"
        "    const cursorOffset = sidebar ? sidebar.cols + 1 : 0;\n"
        "    const buf: string[] = [];\n"
        "\n"
        "    // Row-level diffing: skip rows whose cells are identical to the\n"
        "    // previous frame.  This dramatically reduces stdout output when\n"
        "    // the screen is static, which prevents terminal emulators' URL\n"
        "    // detection from being disrupted by constant full-screen rewrites.\n"
        "    const canDiff =\n"
        "      this.prevGrid !== null &&\n"
        "      this.prevGrid.rows === grid.rows &&\n"
        "      this.prevGrid.cols === grid.cols;\n"
        "\n"
        "    for (let y = 0; y < grid.rows; y++) {\n"
    )
    new = (
        "  ): void {\n"
        "    const grid = compositeGrids(main, sidebar, toolbar, modalOverlay, diffPanel);\n"
        "    const cursorOffset = sidebar ? sidebar.cols + 1 : 0;\n"
        "    const termRows = process.stdout.rows || 24;\n"
        "    const termCols = process.stdout.columns || 80;\n"
        "    const buf: string[] = [];\n"
        "\n"
        "    // AUTOWRAP_SCROLL_PATCH: writing the bottom-right cell with autowrap on\n"
        "    // scrolls the alt screen by one row and leaves the cursor permanently\n"
        "    // below the text — especially after resize full-redraws. Disable wrap\n"
        "    // for the paint; clear when size changes or grid would exceed the terminal.\n"
        '    buf.push("\\x1b[?7l");\n'
        "    if (\n"
        "      this.prevGrid === null ||\n"
        "      this.prevGrid.rows !== grid.rows ||\n"
        "      this.prevGrid.cols !== grid.cols ||\n"
        "      grid.rows > termRows ||\n"
        "      grid.cols > termCols\n"
        "    ) {\n"
        '      buf.push("\\x1b[H\\x1b[2J");\n'
        "      this.prevGrid = null;\n"
        "    }\n"
        "\n"
        "    // Row-level diffing: skip rows whose cells are identical to the\n"
        "    // previous frame.  This dramatically reduces stdout output when\n"
        "    // the screen is static, which prevents terminal emulators' URL\n"
        "    // detection from being disrupted by constant full-screen rewrites.\n"
        "    const canDiff =\n"
        "      this.prevGrid !== null &&\n"
        "      this.prevGrid.rows === grid.rows &&\n"
        "      this.prevGrid.cols === grid.cols;\n"
        "\n"
        "    const paintRows = Math.min(grid.rows, termRows);\n"
        "    const paintCols = Math.min(grid.cols, termCols);\n"
        "    for (let y = 0; y < paintRows; y++) {\n"
    )
    if old not in text:
        sys.exit(f"renderer.ts: render() header not found for autowrap patch in {renderer}")
    text = text.replace(old, new, 1)

    old_diff = (
        "        for (let x = 0; x < grid.cols; x++) {\n"
        "          if (!fullCellsEqual(curRow[x], prevRow[x])) {\n"
        "            rowChanged = true;\n"
        "            break;\n"
        "          }\n"
        "        }\n"
    )
    new_diff = (
        "        for (let x = 0; x < paintCols; x++) {\n"
        "          if (!fullCellsEqual(curRow[x], prevRow[x])) {\n"
        "            rowChanged = true;\n"
        "            break;\n"
        "          }\n"
        "        }\n"
    )
    if old_diff not in text:
        sys.exit(f"renderer.ts: diff x-loop not found in {renderer}")
    text = text.replace(old_diff, new_diff, 1)

    old_loop = (
        "      for (let x = 0; x < grid.cols; x++) {\n"
        "        const cell = grid.cells[y][x];\n"
        "\n"
        "        // Skip continuation cells (second half of wide characters)\n"
        "        if (cell.width === 0) continue;\n"
    )
    new_loop = (
        "      for (let x = 0; x < paintCols; x++) {\n"
        "        const cell = grid.cells[y][x];\n"
        "\n"
        "        // Skip continuation cells (second half of wide characters)\n"
        "        if (cell.width === 0) continue;\n"
    )
    if old_loop not in text:
        sys.exit(f"renderer.ts: paint x-loop not found in {renderer}")
    text = text.replace(old_loop, new_loop, 1)

    # Restore autowrap after SGR reset. Handle both patched and unpatched cursor blocks.
    if 'buf.push("\\x1b[?7h")' not in text and "buf.push(\"\\x1b[?7h\")" not in text:
        needle = '    buf.push("\\x1b[0m");\n    if (modalCursor != null) {'
        repl = (
            '    buf.push("\\x1b[0m");\n'
            '    buf.push("\\x1b[?7h"); // AUTOWRAP_SCROLL_PATCH: restore autowrap\n'
            "    if (modalCursor != null) {"
        )
        if needle not in text:
            sys.exit(f"renderer.ts: could not insert autowrap restore in {renderer}")
        text = text.replace(needle, repl, 1)

    # If cursor block still declares its own termRows, leave it — harmless if autowrap
    # block already declared them in outer scope. Prefer removing duplicate decls when present.
    text = text.replace(
        "    const cursorRowOffset = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n"
        "    const termRows = process.stdout.rows || 24;\n"
        "    const termCols = process.stdout.columns || 80;\n"
        '    buf.push("\\x1b[0m");\n'
        '    buf.push("\\x1b[?7h"); // AUTOWRAP_SCROLL_PATCH: restore autowrap\n',
        "    const cursorRowOffset = toolbar ? (toolbar.toolbarRows ?? 1) : 0;\n"
        '    buf.push("\\x1b[0m");\n'
        '    buf.push("\\x1b[?7h"); // AUTOWRAP_SCROLL_PATCH: restore autowrap\n',
        1,
    )

    print(f"patched autowrap scroll fix in {renderer}")
else:
    print(f"already patched autowrap scroll fix in {renderer}")

renderer.write_text(text)
print("jmux patches applied")
PY
