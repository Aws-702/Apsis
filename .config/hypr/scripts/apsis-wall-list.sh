#!/bin/sh
# Lists wallpapers in ~/Apsis/wallpapers with thumbnails for the wheel and Settings.
# Edit: dir for the folder.

dir="$HOME/Apsis/wallpapers"
thumbs="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/thumbs"
[ -d "$dir" ] || exit 0
mkdir -p "$thumbs"
TAB=$(printf '\t')

find "$dir" -maxdepth 1 -type f ! -name ".*" 2>/dev/null | while IFS= read -r f; do
    case "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" in
        *.jpg|*.jpeg|*.png|*.webp|*.bmp) kind=image; thumb="$f" ;;
        *.mp4|*.webm|*.mkv|*.mov|*.avi|*.gif)
            kind=video
            t="$thumbs/$(printf '%s' "$f" | md5sum | cut -c1-16).jpg"
            if [ ! -s "$t" ] && command -v ffmpeg >/dev/null 2>&1; then
                ffmpeg -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf "scale=640:-2" "$t" </dev/null 2>/dev/null \
                    || ffmpeg -loglevel error -y -i "$f" -frames:v 1 -vf "scale=640:-2" "$t" </dev/null 2>/dev/null
            fi
            [ -s "$t" ] && thumb="$t" || thumb="" ;;
        *) continue ;;
    esac
    printf '%s%s%s%s%s%s%s\n' "$(stat -c %Y "$f" 2>/dev/null || echo 0)" "$TAB" "$f" "$TAB" "$thumb" "$TAB" "$kind"
done
