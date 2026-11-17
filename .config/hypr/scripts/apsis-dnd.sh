#!/bin/sh
# Do Not Disturb for the shell's notifications.
# Usage: apsis-dnd.sh [toggle] | on [MINUTES] | off

mkdir -p "$HOME/.cache/quickshell"
STATE="$HOME/.cache/quickshell/apsis-dnd"
UNTIL="$HOME/.cache/quickshell/apsis-dnd-until"
cur=$(cat "$STATE" 2>/dev/null)
case "${1:-toggle}" in
    on)
        printf on > "$STATE"
        if [ -n "$2" ] && [ "$2" -gt 0 ] 2>/dev/null; then
            printf '%s' $(( $(date +%s) + $2 * 60 )) > "$UNTIL"
        else
            rm -f "$UNTIL"
        fi ;;
    off) printf off > "$STATE"; rm -f "$UNTIL" ;;
    toggle)
        rm -f "$UNTIL"
        if [ "$cur" = "on" ]; then printf off > "$STATE"; else printf on > "$STATE"; fi ;;
    *) echo "usage: $0 [toggle] | on [minutes] | off" >&2; exit 2 ;;
esac
