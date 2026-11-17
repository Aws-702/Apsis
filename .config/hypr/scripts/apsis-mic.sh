#!/bin/sh
# Mic mute key: toggles the default source and shows the OSD.
# Edit: nothing visual; the OSD is osd/Osd.qml.

mkdir -p "$HOME/.cache/quickshell"
pamixer --default-source -t
muted=$(pamixer --default-source --get-mute)
printf '%s %s\n' "$muted" "$(date +%s%N)" > "$HOME/.cache/quickshell/apsis-osd-mic"
