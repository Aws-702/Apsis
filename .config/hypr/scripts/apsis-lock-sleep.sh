#!/bin/sh
# Pauses the video wallpaper while locked and resumes it after.
# Usage: apsis-lock-sleep.sh on|off

c="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
case "$1" in
    on)  pkill -STOP -x mpvpaper 2>/dev/null ;;
    off)
        if [ "$(tr -d '[:space:]' < "$c/apsis-game" 2>/dev/null)" != "on" ]; then
            pkill -CONT -x mpvpaper 2>/dev/null
        fi ;;
    *) echo "usage: $0 on|off" >&2; exit 2 ;;
esac
exit 0
