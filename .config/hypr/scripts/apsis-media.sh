#!/bin/sh
# MPRIS front end: picks the active player and prints its status, or controls it.
# Usage: apsis-media.sh status | play-pause | next | previous

pick() {
    pls=$(playerctl -l 2>/dev/null)
    [ -z "$pls" ] && return 1
    first=""; paused=""
    for p in $pls; do
        [ -z "$first" ] && first="$p"
        st=$(playerctl -p "$p" status 2>/dev/null)
        [ "$st" = "Playing" ] && { echo "$p"; return 0; }
        [ "$st" = "Paused" ] && [ -z "$paused" ] && paused="$p"
    done
    [ -n "$paused" ] && { echo "$paused"; return 0; }
    echo "$first"
}

p=$(pick) || exit 0
[ -n "$p" ] || exit 0

case "${1:-status}" in
    status)
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
            "$(playerctl -p "$p" status 2>/dev/null)" \
            "$(playerctl -p "$p" metadata title 2>/dev/null)" \
            "$(playerctl -p "$p" metadata artist 2>/dev/null)" \
            "$(playerctl -p "$p" metadata mpris:artUrl 2>/dev/null)" \
            "$(playerctl -p "$p" position 2>/dev/null)" \
            "$(playerctl -p "$p" metadata mpris:length 2>/dev/null)" \
            "$(playerctl -p "$p" metadata album 2>/dev/null)" \
            "$(playerctl -p "$p" metadata xesam:url 2>/dev/null)"
        ;;
    play-pause|next|previous)
        playerctl -p "$p" "$1" >/dev/null 2>&1
        ;;
esac
