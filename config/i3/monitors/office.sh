# shellcheck shell=bash
# shellcheck disable=SC2034  # profile vars are consumed by bin/i3-monitors
# Monitor profile — office desk.
#
# Roles are semantic: i3 assigns workspaces to left/middle/right/bottom, so the
# same apps land on the same physical position in every setup. Only the output
# names and xrandr geometry differ between profiles.
#
# Sourced by bin/i3-monitors. Do not execute directly.

PROFILE_LABEL="Office"
OUTPUT_LEFT="DP-3"
OUTPUT_MIDDLE="HDMI-1-0"
OUTPUT_RIGHT="DP-2"
OUTPUT_BOTTOM="eDP-1"

XRANDR_ARGS=(
    --output eDP-1 --primary --mode 1920x1200 --pos 407x1890 --rotate normal
    --output DP-1 --off
    --output DP-2 --mode 2560x1440 --pos 4000x450 --rotate normal
    --output DP-3 --mode 2560x1440 --pos 0x450 --rotate normal
    --output HDMI-1-0 --mode 2560x1440 --pos 2560x0 --rotate left
    --output DP-1-0 --off
    --output DP-1-1 --off
    --output DP-1-2 --off
    --output DP-1-3 --off
)
