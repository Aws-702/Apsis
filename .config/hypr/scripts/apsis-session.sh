#!/bin/sh
# Runs once at login: puts night light, keep awake, Ultra, Training and monitors back in step.
# Edit: what comes back after a reboot, one block per toggle here.

c="$HOME/.cache/quickshell"
s="$HOME/.config/hypr/scripts"
mkdir -p "$c"

if [ "$(tr -d '[:space:]' < "$c/apsis-nightlight" 2>/dev/null)" = "on" ]; then

    i=0
    while ! hyprctl version >/dev/null 2>&1; do i=$((i + 1)); [ "$i" -gt 50 ] && break; sleep 0.2; done
    "$s/apsis-nightlight.sh" on
fi

rm -f "$c/apsis-caffeine.pid"
printf off > "$c/apsis-caffeine"

"$s/apsis-ultra.sh" reset
"$s/apsis-train.sh" reset

"$s/apsis-game.sh" reset
"$s/apsis-focus.sh" reset
"$s/apsis-idle.sh" start >/dev/null 2>&1 &

"$s/apsis-display.sh" restore
