#!/bin/sh
# Brightness keys: changes brightness and shows the OSD.
# Usage: apsis-brightness.sh up|down. Edit: the 5% step in the brightnessctl calls.

mkdir -p "$HOME/.cache/quickshell"
case "$1" in
    up)   brightnessctl set 5%+ -q ;;
    down) brightnessctl set 5%- -q ;;
esac
cur=$(brightnessctl get)
max=$(brightnessctl max)
pct=0
[ "$max" -gt 0 ] && pct=$(( cur * 100 / max ))
printf '%s %s\n' "$pct" "$(date +%s%N)" > "$HOME/.cache/quickshell/apsis-osd-brightness"
