#!/bin/sh
# Lists and rewrites keyboard binds in hyprland.lua, apsis-keys.lua and custom.lua for Settings.
# Usage: apsis-keybind.sh list | set ID COMBO | restore. Edit: the label rules in the list awk.

DIR="$HOME/.config/hypr"
LAST="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/keybind-last"
[ -f "$DIR/hyprland.lua" ] || exit 1

file_of() {
    case "$1" in
        hyprland) echo "$DIR/hyprland.lua" ;;
        keys)     echo "$DIR/apsis-keys.lua" ;;
        custom)   echo "$DIR/custom.lua" ;;
        *)        return 1 ;;
    esac
}

list_file() {
    [ -f "$2" ] || return 0
    awk -v tag="$1" '
    BEGIN { inloop = 0 }
    {
        if ($0 ~ /^[[:space:]]*for[[:space:]]/) { inloop = 1; next }
        if (inloop) { if ($0 ~ /^[[:space:]]*end/) inloop = 0; next }
        if ($0 !~ /hl\.bind\(/) next

        s = $0
        sub(/^.*hl\.bind\(/, "", s)
        ks = s; sub(/,.*$/, "", ks)        # keyspec = up to first comma
        act = s; sub(/^[^,]*,/, "", act)   # action  = after first comma

        combo = ks
        gsub(/mod/, "SUPER", combo)
        gsub(/\.\./, " ", combo)
        gsub(/"/, "", combo)
        gsub(/[[:space:]]+/, " ", combo)
        sub(/^ /, "", combo); sub(/ $/, "", combo)
        if (combo ~ /mouse/) next

        label = act
        if      (act ~ /exec_cmd\(term\)/)        label = "Terminal"
        else if (act ~ /exec_cmd\(files\)/)       label = "File manager"
        else if (act ~ /exec_cmd\(browser\)/)     label = "Browser"
        else if (act ~ /exec_cmd\(editor\)/)      label = "Editor"
        else if (act ~ /apsis-launcher/)          label = "Apps (phone)"
        else if (act ~ /apsis-centre/)            label = "Quick panel (phone)"
        else if (act ~ /apsis-powermenu/)         label = "Power menu"
        else if (act ~ /apsis-palette/)           label = "Toggle palette"
        else if (act ~ /apsis-mode/)              label = "Cycle dark / darker / light"
        else if (act ~ /phone open settings/)     label = "Settings"
        else if (act ~ /edit toggle/)             label = "Edit desktop"
        else if (act ~ /dock toggle/)             label = "Show / hide dock"
        else if (act ~ /overview toggle/)         label = "Overview"
        else if (act ~ /cheatsheet toggle/)       label = "Shortcut cheat sheet"
        else if (act ~ /wallpaper toggle/)        label = "Wallpaper wheel"
        else if (act ~ /phone search ">"/)        label = "Clipboard history"
        else if (act ~ /phone search ":"/)        label = "Emoji"
        else if (act ~ /toggle notifications/)    label = "Notifications (phone)"
        else if (act ~ /apsis-ultra/)             label = "Ultra saver (free GPU memory)"
        else if (act ~ /apsis-record.sh toggle region/) label = "Record a region (again to stop)"
        else if (act ~ /apsis-record.sh toggle screen/) label = "Record the screen (again to stop)"
        else if (act ~ /apsis-game/)              label = "Game mode"
        else if (act ~ /apsis-focus/)             label = "Focus mode"
        else if (act ~ /apsis-wall-random/)       label = "Random wallpaper"
        else if (act ~ /apsis-train/)             label = "Training mode (Ultra saver and tmux)"
        else if (act ~ /hyprpicker/)              label = "Color picker"
        else if (act ~ /hyprlock|apsis-lock/)     label = "Lock screen"
        else if (act ~ /hl\.dsp\.exit/)          label = "Exit Hyprland"
        else if (act ~ /window\.close/)           label = "Close window"
        else if (act ~ /window\.float/)           label = "Toggle floating"
        else if (act ~ /window\.fullscreen/)      label = "Fullscreen"
        else if (act ~ /group\.toggle/)           label = "Toggle group"
        else if (act ~ /group\.prev/)             label = "Previous in group"
        else if (act ~ /group\.next/)             label = "Next in group"
        else if (act ~ /layout\(/)                label = "Toggle split"
        else if (act ~ /direction = "left"/)      label = "Focus left"
        else if (act ~ /direction = "right"/)     label = "Focus right"
        else if (act ~ /direction = "up"/)        label = "Focus up"
        else if (act ~ /direction = "down"/)      label = "Focus down"
        else if (act ~ /toggle_special/)          label = "Scratchpad"
        else if (act ~ /special:magic/)           label = "Move to scratchpad"
        else if (act ~ /grimblast.*area/)         label = "Screenshot area"
        else if (act ~ /grimblast.*screen/)       label = "Screenshot screen"
        else if (act ~ /grimblast.*output/)       label = "Screenshot monitor"
        else if (act ~ /apsis-volume.sh up/)      label = "Volume up"
        else if (act ~ /apsis-volume.sh down/)    label = "Volume down"
        else if (act ~ /apsis-volume.sh mute/)    label = "Volume mute"
        else if (act ~ /apsis-mic/)               label = "Mic mute"
        else if (act ~ /apsis-brightness.sh up/)  label = "Brightness up"
        else if (act ~ /apsis-brightness.sh down/) label = "Brightness down"
        else if (act ~ /playerctl play-pause/)    label = "Play / pause"
        else if (act ~ /playerctl next/)          label = "Next track"
        else if (act ~ /playerctl previous/)      label = "Previous track"
        else {
            if (act ~ /exec_cmd\("/) { sub(/^.*exec_cmd\("/, "", label); sub(/".*$/, "", label) }
            gsub(/[[:space:]]+/, " ", label); sub(/^ /, "", label); sub(/ $/, "", label)
        }
        printf "%s:%d\t%s\t%s\n", tag, NR, combo, label
    }' "$2"
}

case "${1:-list}" in
list)
    list_file hyprland "$DIR/hyprland.lua"
    list_file keys "$DIR/apsis-keys.lua"
    list_file custom "$DIR/custom.lua"
    ;;
set)
    ref="$2"; combo="$3"
    [ -n "$ref" ] && [ -n "$combo" ] || exit 2
    case "$ref" in *:*) ;; *) ref="hyprland:$ref" ;; esac
    LUA=$(file_of "${ref%%:*}") || exit 2
    id="${ref#*:}"
    case "$id" in ''|*[!0-9]*) exit 2 ;; esac
    [ -f "$LUA" ] || exit 1
    tl=$(sed -n "${id}p" "$LUA")
    echo "$tl" | grep -q 'hl\.bind(' || exit 3
    echo "$tl" | grep -q 'mouse' && exit 4
    echo "$tl" | grep -q '\.\. key' && exit 5
    cp -f "$LUA" "$LUA.bak"
    mkdir -p "$(dirname "$LAST")"; echo "${ref%%:*}" > "$LAST"
    sed -i "${id}s|hl\.bind([^,]*,|hl.bind(\"${combo}\",|" "$LUA"
    command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
    ;;
restore)
    name=$(cat "$LAST" 2>/dev/null || echo hyprland)
    LUA=$(file_of "$name") || exit 1
    [ -f "$LUA.bak" ] || exit 1
    cp -f "$LUA.bak" "$LUA"
    command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
    ;;
esac
