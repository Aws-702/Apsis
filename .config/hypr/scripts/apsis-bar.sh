#!/bin/sh
# Shows, hides or toggles the bar (the shell reads ~/.cache/quickshell/apsis-bar).
# Usage: apsis-bar.sh [show|hide] (no argument toggles)

mkdir -p "$HOME/.cache/quickshell"
CACHE="$HOME/.cache/quickshell/apsis-bar"
cur=$(cat "$CACHE" 2>/dev/null)
case "$1" in
    show) new=show ;;
    hide) new=hide ;;
    *) if [ "$cur" = "hide" ]; then new=show; else new=hide; fi ;;
esac
printf '%s' "$new" > "$CACHE"
