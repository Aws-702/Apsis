#!/bin/sh
# Volume keys: changes volume and shows the OSD.
# Usage: apsis-volume.sh up|down|mute. Edit: the step of 5 in the pamixer calls.

mkdir -p "$HOME/.cache/quickshell"
case "$1" in
    up)   pamixer -i 5 ;;
    down) pamixer -d 5 ;;
    mute) pamixer -t ;;
esac
vol=$(pamixer --get-volume)
muted=$(pamixer --get-mute)
printf '%s %s %s\n' "$vol" "$muted" "$(date +%s%N)" > "$HOME/.cache/quickshell/apsis-osd-volume"
