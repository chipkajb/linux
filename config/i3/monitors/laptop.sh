# shellcheck shell=bash
# shellcheck disable=SC2034  # profile vars are consumed by bin/i3-monitors
# Monitor profile — laptop only.
#
# All four roles collapse onto the internal display; i3 keeps every workspace on
# eDP-1. Used when travelling or when no external monitor is attached.

PROFILE_LABEL="Laptop"
OUTPUT_LEFT="eDP-1"
OUTPUT_MIDDLE="eDP-1"
OUTPUT_RIGHT="eDP-1"
OUTPUT_BOTTOM="eDP-1"

XRANDR_ARGS=(
    --output eDP-1 --primary --mode 1920x1200 --pos 0x0 --rotate normal
    --output DP-1 --off
    --output DP-2 --off
    --output DP-3 --off
    --output HDMI-1-0 --off
    --output DP-1-0 --off
    --output DP-1-1 --off
    --output DP-1-2 --off
    --output DP-1-3 --off
)
