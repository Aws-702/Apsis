#!/bin/sh
# Game mode: animations, blur, shadows and gaps off, silence on, video wallpaper paused.
# Usage: apsis-game.sh on|off|toggle|status|reset|apply. Edit: what it turns off in the on branch.

state="$HOME/.cache/quickshell/apsis-game"
was="$HOME/.cache/apsis/game-was"
scripts="$HOME/.config/hypr/scripts"
ultra="$HOME/.cache/quickshell/apsis-ultra"
focus="$HOME/.cache/quickshell/apsis-focus"
mkdir -p "$(dirname "$state")" "$(dirname "$was")"

set_hypr() { hyprctl eval "(function() pcall(hl.config, $1) end)()" >/dev/null 2>&1; }

apply_hypr() {
    set_hypr '{ animations = { enabled = false } }'
    set_hypr '{ decoration = { blur = { enabled = false } } }'
    set_hypr '{ decoration = { shadow = { enabled = false } } }'
    set_hypr '{ decoration = { rounding = 0 } }'
    set_hypr '{ general = { gaps_in = 0, gaps_out = 0 } }'
    set_hypr '{ render = { direct_scanout = true } }'
}

on() {
    [ -f "$state" ] && { echo "already on"; return 0; }

    if [ -f "$focus" ]; then
        if [ "$(sed -n 's/^dnd=//p' "$HOME/.cache/apsis/focus-was" 2>/dev/null)" = on ]; then echo dnd-was-on > "$was"; else : > "$was"; fi
    elif [ "$(cat "$HOME/.cache/quickshell/apsis-dnd" 2>/dev/null)" = "on" ]; then
        echo dnd-was-on > "$was"
    else
        : > "$was"
    fi
    printf on > "$state"
    "$scripts/apsis-dnd.sh" on
    pkill -STOP -x mpvpaper 2>/dev/null
    apply_hypr
    notify-send -a Apsis "Game mode on" "Effects off, notifications silenced" 2>/dev/null
}

off() {
    [ -f "$state" ] || { echo "already off"; return 0; }
    rm -f "$state"
    pkill -CONT -x mpvpaper 2>/dev/null

    if [ ! -f "$ultra" ]; then
        hyprctl reload >/dev/null 2>&1
        "$scripts/apsis-display.sh" restore
        [ -f "$focus" ] && "$scripts/apsis-focus.sh" apply
    fi

    if ! grep -qx dnd-was-on "$was" 2>/dev/null && [ ! -f "$focus" ]; then
        "$scripts/apsis-dnd.sh" off
    fi
    rm -f "$was"
    notify-send -a Apsis "Game mode off" "Everything is back" 2>/dev/null
}

case "${1:-toggle}" in
    on) on ;;
    off) off ;;
    toggle) if [ -f "$state" ]; then off; else on; fi ;;
    status) [ -f "$state" ] && echo on || echo off ;;
    reset) rm -f "$state" "$was" ;;
    apply) [ -f "$state" ] && [ ! -f "$ultra" ] && apply_hypr ;;
    *) echo "usage: $0 on | off | toggle | status | reset | apply" >&2; exit 2 ;;
esac
