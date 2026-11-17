#!/bin/sh
# Sets the palette (cherry, navy, auto) or toggles cherry and navy, and refreshes the outside apps.
# Usage: apsis-palette.sh [cherry|navy|auto|toggle]

mkdir -p "$HOME/.cache/quickshell"
CACHE="$HOME/.cache/quickshell/apsis-palette"
SCRIPTS="$HOME/.config/hypr/scripts"
cur=$(cat "$CACHE" 2>/dev/null)
case "$1" in
    cherry|navy|auto) new="$1" ;;
    *) if [ "$cur" = "cherry" ]; then new="navy"; else new="cherry"; fi ;;
esac
printf '%s' "$new" > "$CACHE"
if [ "$new" = "auto" ]; then
    w=$(cat "$HOME/.cache/quickshell/apsis-wallpaper" 2>/dev/null)
    [ -n "$w" ] && "$SCRIPTS/apsis-matugen.sh" "$w"
    cp "$HOME/.config/wofi/style-auto.css" "$HOME/.config/wofi/style.css" 2>/dev/null || true
else
    cp "$HOME/.config/wofi/style-$new.css" "$HOME/.config/wofi/style.css" 2>/dev/null || true
fi
"$SCRIPTS/apsis-hyprlock.sh"
"$SCRIPTS/apsis-gtk.sh" &
"$SCRIPTS/apsis-dunst.sh"
"$SCRIPTS/apsis-sddm-sync.sh" "$new" &
