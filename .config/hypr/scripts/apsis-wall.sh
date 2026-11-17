#!/bin/sh
# Applies a wallpaper (image or video), remembers it and refreshes the auto palette.
# Usage: apsis-wall.sh FILE. Edit: awww transition flags and mpvpaper options here.

[ -z "$1" ] && exit 0
mkdir -p "$HOME/.cache/quickshell"
engine=$(cat "$HOME/.cache/quickshell/apsis-wall-engine" 2>/dev/null)
[ -n "$engine" ] || engine=apsis

still="$1"
case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *.mp4|*.webm|*.mkv|*.mov|*.avi|*.gif)
        if ! command -v mpvpaper >/dev/null 2>&1; then
            notify-send "Wallpaper" "Video wallpapers need mpvpaper (AUR): yay -S mpvpaper" 2>/dev/null
            exit 1
        fi
        frame="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/wall-frame.jpg"
        mkdir -p "$(dirname "$frame")"
        if command -v ffmpeg >/dev/null 2>&1 \
           && ffmpeg -loglevel error -y -ss 1 -i "$1" -frames:v 1 "$frame" </dev/null 2>/dev/null; then
            still="$frame"
        else
            still=""
        fi
        pkill -x mpvpaper 2>/dev/null
        setsid -f mpvpaper -f -o "no-audio loop panscan=1.0 hwdec=auto" ALL "$1" >/dev/null 2>&1
        ;;
    *)
        pkill -x mpvpaper 2>/dev/null ;;
esac

if [ -n "$still" ]; then
    if [ "$engine" = "apsis" ]; then
        awww img "$still" --transition-type none >/dev/null 2>&1 || awww img "$still" >/dev/null 2>&1
    else
        awww img "$still" --transition-type any --transition-fps 60 --transition-duration 1 >/dev/null 2>&1 \
            || awww img "$still" >/dev/null 2>&1
    fi
fi
printf '%s' "$1" > "$HOME/.cache/quickshell/apsis-wallpaper"
cur=$(cat "$HOME/.cache/quickshell/apsis-palette" 2>/dev/null)
if [ "$cur" = "auto" ] && [ -n "$still" ]; then
    "$HOME/.config/hypr/scripts/apsis-matugen.sh" "$still"
    cp "$HOME/.config/wofi/style-auto.css" "$HOME/.config/wofi/style.css" 2>/dev/null || true
fi
