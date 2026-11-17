#!/bin/sh
# Picks a random wallpaper (never the current one) and applies it.
# Usage: apsis-wall-random.sh [image]. Edit: APSIS_WALLS for the folder.

dir="${APSIS_WALLS:-$HOME/Apsis/wallpapers}"
cur=$(cat "$HOME/.cache/quickshell/apsis-wallpaper" 2>/dev/null)
[ -d "$dir" ] || { notify-send "Wallpaper" "No wallpapers in $dir yet" 2>/dev/null; exit 1; }

case "${1:-any}" in
    image) pat='.*\.\(jpg\|jpeg\|png\|webp\|bmp\)' ;;
    *)     pat='.*\.\(jpg\|jpeg\|png\|webp\|bmp\|mp4\|webm\|mkv\|mov\|avi\|gif\)' ;;
esac
list=$(find "$dir" -maxdepth 1 -type f ! -name '.*' -iregex "$pat" 2>/dev/null)
[ -n "$list" ] || { notify-send "Wallpaper" "No wallpapers in $dir yet" 2>/dev/null; exit 1; }

count=$(printf '%s\n' "$list" | wc -l)
if [ "$count" -gt 1 ]; then
    list=$(printf '%s\n' "$list" | grep -vxF -- "$cur")
    count=$(printf '%s\n' "$list" | wc -l)
fi
pick=$(printf '%s\n' "$list" | awk -v n="$count" -v s="$(od -An -N4 -tu4 /dev/urandom | tr -d ' ')" 'BEGIN{srand(s); k=int(rand()*n)+1} NR==k{print; exit}')
[ -n "$pick" ] || exit 1
exec "$(dirname "$0")/apsis-wall.sh" "$pick"
