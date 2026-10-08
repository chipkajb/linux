# Keybindings

`Super` (Mod4) is the modifier. `*` means `Super+Shift`. The canonical, always-up-to-date
list is [`config/i3/i3-hotkeys.txt`](../config/i3/i3-hotkeys.txt) — press
**`Super+i`** to open it in a terminal viewer.

## Applications

| Key | Action |
| --- | --- |
| `Super+a` / `Super+Shift+a` | rofi app launcher / run command |
| `Super+w` | rofi window switcher |
| `Super+Return` | terminal (Herdr) |
| `Super+g` | Google Chrome |
| `Super+c` | Cursor |
| `Super+o` | Obsidian |
| `Super+s` | Slack |
| `Super+m` | MongoDB Compass |
| `Super+n` | Nautilus |
| `Super+b` | Bluetooth manager |
| `Super+p` | Pithos |
| `Super+Shift+o` | open work apps (Chrome, Obsidian, Slack) |
| `Super+Shift+p` | screenshot the monitor under the mouse (Flameshot) |
| `Super+Shift+s` | herdr remote host picker (`~/.ssh/config`) |

## Workspaces

| Key | Action |
| --- | --- |
| `Super+1…0` | switch to workspace 1–10 |
| `Super+Shift+1…0` | move the focused window to workspace 1–10 |
| `Super+Tab` | previous workspace |
| `Super+u` | next workspace |
| `Super+y` | move window to Code+ (9) and follow it |

| # | Workspace | Role |
| --- | --- | --- |
| 1 | 🌍 Web | left |
| 2 | ⚫ Terminal | middle |
| 3 | 💻 Code | middle |
| 4 | 💬 Messages | right |
| 5 | 📁 Files | bottom |
| 6 | 📝 Notes | bottom |
| 7 | 🎵 Music | left |
| 8 | ⚪ Terminal+ | middle |
| 9 | 🖥️ Code+ | middle |
| 10 | 🗄️ Data | right |

## Windows & layout

| Key | Action |
| --- | --- |
| `Super+h/j/k/l` (or arrows) | focus |
| `Super+Shift+h/j/k/l` (or arrows) | move window |
| `Super+;` / `Super+v` | split horizontal / vertical |
| `Super+e` | toggle split layout |
| `Super+f` | fullscreen |
| `Super+space` | toggle floating |
| `Super+r` | resize mode (`Esc`/`Enter`/`r` to exit) |
| `Super+Shift+q` | close window |

## Monitors

| Key | Action |
| --- | --- |
| `Super+Shift+m` | monitor profile picker (office / home / laptop) |
| `Super+,` / `Super+.` | move workspace to output left / right |
| `Super+=` / `Super+-` | move workspace to output up / down |

See [monitors.md](monitors.md) for profiles.

## Notifications & system

| Key | Action |
| --- | --- |
| `Super+q` | toggle notification quiet mode |
| `Super+x` | pop the last dismissed notification |
| `Super+z` | jump to the latest notification's workspace |
| `Alt+r` / `Alt+Space` | close one / all notifications |
| `Super+Shift+y` | join the clipboard into one line |
| `Super+Shift+c` | reload i3 |
| `Super+Shift+r` | restart i3 |
| `Super+Shift+e` | log out |
| `Super+Shift+x` | lock screen |
| `Super+i` | hotkey help |
| `Super+t` | Obsidian notes scratchpad (vim in vault) |

Volume and mic keys are handled by PulseAudio bindings on the media keys.
