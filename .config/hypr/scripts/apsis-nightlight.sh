#!/usr/bin/env bash
# Night light through hyprsunset.
# Usage: apsis-nightlight.sh [toggle|on|off|get]. Edit: APSIS_NIGHT_TEMP or temp (4000 K).

set -u

state="$HOME/.cache/quickshell/apsis-nightlight"
temp="${APSIS_NIGHT_TEMP:-4000}"
mkdir -p "$(dirname "$state")"

cur="off"
[ -f "$state" ] && cur=$(tr -d '[:space:]' < "$state")

action="${1:-toggle}"
[ "$action" = "toggle" ] && { [ "$cur" = "on" ] && action="off" || action="on"; }

ensure_daemon() {
    pgrep -x hyprsunset >/dev/null 2>&1 || { setsid -f hyprsunset >/dev/null 2>&1; sleep 0.3; }
}

case "$action" in
    on)
        ensure_daemon
        hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1
        echo on > "$state"
        ;;
    off)
        if pgrep -x hyprsunset >/dev/null 2>&1; then
            hyprctl hyprsunset identity >/dev/null 2>&1
        fi
        echo off > "$state"
        ;;
    get)
        echo "$cur"
        ;;
esac
