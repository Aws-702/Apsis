#!/bin/sh
# Runs matugen on a wallpaper and refreshes the lock, notifications and login in auto palette.
# Usage: apsis-matugen.sh IMAGE. Edit: the matugen --type and --mode flags here.

command -v matugen >/dev/null 2>&1 || exit 0
[ -z "$1" ] && exit 0
[ -f "$1" ] || exit 0
matugen image "$1" --mode dark --type scheme-content --source-color-index 0 >/dev/null 2>&1 || true
cur=$(cat "$HOME/.cache/quickshell/apsis-palette" 2>/dev/null)
if [ "$cur" = "auto" ]; then
    printf 'auto' > "$HOME/.cache/quickshell/apsis-palette"
    "$HOME/.config/hypr/scripts/apsis-hyprlock.sh"
    "$HOME/.config/hypr/scripts/apsis-dunst.sh"
    "$HOME/.config/hypr/scripts/apsis-sddm-sync.sh" auto &
fi
