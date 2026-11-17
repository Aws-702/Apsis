#!/bin/sh
# Writes a monitor layout for the screens connected now (native size, highest rate).
# Usage: monitors-init.sh [--force|--print]. Edit: how a mode is picked here.

file="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/monitors.lua"
force=0; print=0
for a in "$@"; do
    case "$a" in
        --force) force=1 ;;
        --print) print=1 ;;
        *) echo "usage: $0 [--force] [--print]" >&2; exit 2 ;;
    esac
done

for need in hyprctl jq; do
    command -v "$need" >/dev/null 2>&1 || { echo "monitors-init: needs $need" >&2; exit 1; }
done
json=$(hyprctl monitors -j 2>/dev/null) || { echo "monitors-init: Hyprland isn't running here, nothing to read" >&2; exit 1; }
[ -n "$json" ] || exit 1

if [ -f "$file" ] && [ "$force" -eq 0 ] && [ "$print" -eq 0 ]; then
    echo "monitors-init: $file already exists (use --force to replace it)"
    exit 0
fi

lines=$(printf '%s' "$json" | jq -r '
    .[] | select(.disabled | not) |
    . as $m |
    ([ .availableModes[] | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz$")
       | {w: (.w|tonumber), h: (.h|tonumber), r: (.r|tonumber)} ]) as $modes |
    ($modes | map(.w * .h) | max) as $area |
    ($modes | map(select(.w * .h == $area)) | max_by(.r)) as $best |
    select($best != null) |
    [ $m.name, "\($best.w)x\($best.h)@\($best.r * 1000 | round / 1000)",
      "\($m.x)x\($m.y)", ($m.scale | tostring) ] | @tsv' 2>/dev/null)

[ -n "$lines" ] || { echo "monitors-init: couldn't read any monitor modes" >&2; exit 1; }

out="-- Apsis: monitors, written for the screens connected at install (~/.config/apsis/monitors-init.sh).
-- Settings > Display keeps this file; delete a line to go back to hyprland.lua's own."
TAB=$(printf '\t')
count=0
while IFS="$TAB" read -r name mode pos scale; do
    printf '%s' "$name"  | grep -Eq '^[A-Za-z0-9_.-]{1,40}$' || continue
    printf '%s' "$mode"  | grep -Eq '^[0-9]{3,5}x[0-9]{3,5}@[0-9]{1,3}(\.[0-9]{1,3})?$' || continue
    printf '%s' "$pos"   | grep -Eq '^-?[0-9]{1,5}x-?[0-9]{1,5}$' || continue
    printf '%s' "$scale" | grep -Eq '^[0-9](\.[0-9]{1,6})?$' || continue
    out="$out
hl.monitor({ output = \"$name\", mode = \"$mode\", position = \"$pos\", scale = $scale })"
    count=$((count + 1))
done <<EOF
$lines
EOF

[ "$count" -gt 0 ] || { echo "monitors-init: nothing usable to write" >&2; exit 1; }

if [ "$print" -eq 1 ]; then
    printf '%s\n' "$out"
    exit 0
fi
mkdir -p "$(dirname "$file")"
tmp="$file.$$"
printf '%s\n' "$out" > "$tmp" && mv "$tmp" "$file"
echo "monitors-init: wrote $count monitor(s) to $file"
