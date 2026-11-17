#!/bin/sh
# Restores the last wallpaper at login once awww-daemon is up.
# Edit: the wait loop here.

i=0
while ! awww query >/dev/null 2>&1; do
    i=$((i + 1)); [ "$i" -gt 20 ] && break; sleep 0.2
done
w=$(cat "$HOME/.cache/quickshell/apsis-wallpaper" 2>/dev/null)
[ -n "$w" ] && [ -f "$w" ] || exit 0
case "$(printf '%s' "$w" | tr '[:upper:]' '[:lower:]')" in

    *.mp4|*.webm|*.mkv|*.mov|*.avi|*.gif) "$HOME/.config/hypr/scripts/apsis-wall.sh" "$w" ;;
    *) awww img "$w" >/dev/null 2>&1 ;;
esac
