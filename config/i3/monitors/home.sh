# shellcheck shell=bash
# shellcheck disable=SC2034  # profile vars are consumed by bin/i3-monitors
# Monitor profile — home office.
#
# Roles are semantic: i3 assigns workspaces to left/middle/right/bottom, so the
# same apps land on the same physical position in every setup. Only the output
# names and xrandr geometry differ between profiles.
#
# Sourced by bin/i3-monitors. Do not execute directly.

PROFILE_LABEL="Home"
OUTPUT_LEFT="HDMI-1-0"
OUTPUT_MIDDLE="DP-3-1"
OUTPUT_RIGHT="DP-3-2"
OUTPUT_BOTTOM="eDP-1"

XRANDR_ARGS=(
    --output eDP-1 --primary --mode 1920x1200 --pos 0x1946 --rotate normal
    --output DP-1 --off
    --output DP-2 --off
    --output DP-3 --off
    --output DP-3-1 --mode 2560x1440 --pos 2560x0 --rotate left
    --output DP-3-2 --mode 2560x1440 --pos 4000x506 --rotate normal
    --output DP-3-3 --off
    --output HDMI-1-0 --mode 2560x1440 --pos 0x506 --rotate normal
    --output DP-1-0 --off
    --output DP-1-1 --off
    --output DP-1-2 --off
    --output DP-1-3 --off
)
