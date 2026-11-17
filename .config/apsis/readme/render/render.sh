#!/bin/sh
# Renders the README screenshots from the shell's own QML with demo data (no live desktop, no personal data) into ../shots.
# Edit: the shot list below (name, scene, palette, wallpaper, crop); what the scenes show lives in scenes/ and demo.json.
# Usage: render.sh [shot ...]   (no argument renders them all)

set -eu
here=$(cd "$(dirname "$0")" && pwd)
src=${APSIS_QS:-$(cd "$here/../../.." && pwd)/quickshell}
out=$(cd "$here/.." && pwd)/shots
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

missing=""
python3 -c 'import PySide6' 2>/dev/null || missing="$missing pyside6"
command -v xvfb-run >/dev/null 2>&1 || missing="$missing xorg-server-xvfb"
command -v faketime >/dev/null 2>&1 || missing="$missing libfaketime"
command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1 || missing="$missing imagemagick"
if [ -n "$missing" ]; then
    echo "needs:$missing"
    echo "  sudo pacman -S --needed$missing"
    exit 1
fi
im() { if command -v magick >/dev/null 2>&1; then magick "$@"; else convert "$@"; fi; }

SHOTS="desktop:desktop
phone:phone
edit:edit
updates:updates:::420x790+770+290"

mkdir -p "$out"
printf '%s\n' "$SHOTS" | while IFS=: read -r name scene palette wall crop; do
    if [ $# -gt 0 ]; then
        hit=0
        for w in "$@"; do [ "$w" = "$name" ] && hit=1; done
        [ $hit = 1 ] || continue
    fi
    printf '%-11s' "$name"
    FAKETIME_DONT_FAKE_MONOTONIC=1 SHOT_PALETTE=${palette:-cherry} SHOT_WALL=${wall:-dusk} \
        faketime -f "@${APSIS_SHOT_TIME:-2026-11-16 09:41:00}" \
        xvfb-run -a -s "-screen 0 1920x1080x24" \
        python3 "$here/shot.py" "$src" "$scene" "$tmp/$name.png" "${APSIS_SHOT_WAIT:-4500}" >"$tmp/$name.log" 2>&1 \
        || { echo "failed, see the log below"; cat "$tmp/$name.log"; exit 1; }
    if [ -n "$crop" ]; then
        im "$tmp/$name.png" -crop "$crop" +repage -strip -quality 90 "$out/$name.jpg"
    else
        im "$tmp/$name.png" -resize 1600x -strip -quality 86 "$out/$name.jpg"
    fi
    echo "-> $out/$name.jpg"
done
