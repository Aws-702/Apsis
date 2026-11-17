#!/bin/sh
# Migration 001: makes the folders Apsis uses and a custom.lua stub; safe to run twice.
# Edit: the stub text here.

mkdir -p "$HOME/.cache/apsis" "$HOME/.cache/quickshell" \
         "${XDG_STATE_HOME:-$HOME/.local/state}/apsis" "$HOME/.config/hypr"

stub="$HOME/.config/hypr/custom.lua"
if [ ! -e "$stub" ]; then
    cat > "$stub" <<'LUA'
-- Your own Hyprland settings. Apsis loads this last, so anything here wins, and
-- an update never touches this file. Examples:
--
--   hl.bind("SUPER + C", hl.dsp.exec_cmd("kitty --class calc -e python3"))
--   hl.config({ general = { gaps_out = 16 } })
LUA
fi
exit 0
