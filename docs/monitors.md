# Monitor profiles

The desktop has three displays at the office, three at home, and one on the road.
Only the physical output names change — the *layout* is the same. `i3-monitors`
captures that difference in a profile and generates the i3 config that binds
workspaces to monitor **roles**.

## Roles

`config/i3/config` assigns every workspace to a role, not to an output:

| Role | Workspaces |
| --- | --- |
| `left` | 1 Web, 7 Music |
| `middle` | 2 Terminal, 3 Code, 8 Terminal+, 9 Code+ |
| `right` | 4 Messages, 10 Data |
| `bottom` | 5 Files, 6 Notes |

Because apps are assigned to workspaces (`assign [class="…"] $workspaceN`), they
follow the role automatically when you switch desks.

## Profiles

Profiles live in `config/i3/monitors/<name>.sh`:

| Profile | left | middle | right | bottom |
| --- | --- | --- | --- | --- |
| `office` | `DP-3` | `HDMI-1-0` | `DP-2` | `eDP-1` |
| `home` | `HDMI-1-0` | `DP-3-1` | `DP-3-2` | `eDP-1` |
| `laptop` | `eDP-1` | `eDP-1` | `eDP-1` | `eDP-1` |

## Usage

```bash
i3-monitors                 # rofi picker
i3-monitors list            # list profiles, marks the active one
i3-monitors status          # active profile + connected outputs
i3-monitors home            # apply a profile
i3-monitors auto            # detect the profile from connected outputs
i3-monitors apply           # re-apply the active profile's geometry
i3-monitors generate office # rewrite the i3 include only (no X changes)
```

Press **`Super+Shift+m`** for the rofi picker.

At i3 startup, `exec_always i3-monitors auto` re-applies the active layout and
detects a change of desk: if the connected outputs match a different profile, it
switches and restarts i3 once so the workspace assignments take effect.

## How it works

1. `i3-monitors <profile>` sources the profile, runs `xrandr`, and writes
   `~/.i3_monitors`:

   ```
   set $monitor_left HDMI-1-0
   set $monitor_middle DP-3-1
   set $monitor_right DP-3-2
   set $monitor_bottom eDP-1
   ```

2. `config/i3/config` includes that file and assigns workspaces to the resulting
   variables.
3. If the include changed, i3 is restarted (preserves the layout) so the new
   output assignments apply. If it did not change, only `xrandr` runs — no
   restart, no disruption.

The generated include is deliberately outside the repository (`~/.i3_monitors`),
so `~/.config/i3` can stay a symlink to `config/i3`.

## Adding a profile

1. Copy an existing profile:

   ```bash
   cp config/i3/monitors/home.sh config/i3/monitors/desk.sh
   ```

2. Edit `PROFILE_LABEL` and the four `OUTPUT_*` roles, then set `XRANDR_ARGS` to
   the output of `xrandr` after arranging the displays (e.g. with `arandr`).
3. If it should be auto-detected, add its name to `PROFILE_ORDER` in
   `bin/i3-monitors` (multi-monitor profiles first).
4. Apply it: `i3-monitors desk`.

## Troubleshooting

- **i3 fails to parse the config / no monitors assigned** — the include is
  missing. Run `i3-monitors generate office` (or `auto`) and reload i3.
- **Workspaces stay on the old monitor after switching** — i3 was not restarted.
  `i3-msg restart`, or re-run `i3-monitors <profile>` with `DISPLAY` set.
- **Wrong profile detected** — `i3-monitors status` shows connected outputs;
  compare with the profile's enabled outputs, then adjust `PROFILE_ORDER`.
- **`xrandr` reports the output as disconnected** — check the cable/adapter, then
  `i3-monitors status`.
