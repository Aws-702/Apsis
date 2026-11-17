#!/bin/sh
# Sets the mode (dark, darker, light) or cycles it; the shell re-derives every colour live.
# Usage: apsis-mode.sh [dark|darker|light|cycle]

mkdir -p "$HOME/.cache/quickshell"
CACHE="$HOME/.cache/quickshell/apsis-mode"
cur=$(cat "$CACHE" 2>/dev/null)
case "$1" in
    dark|darker|light) new="$1" ;;
    *)
        case "$cur" in
            dark|"") new=darker ;;
            darker)  new=light ;;
            *)       new=dark ;;
        esac
        ;;
esac
printf '%s' "$new" > "$CACHE"
