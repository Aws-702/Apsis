#!/bin/sh
# Focus mode: bar hidden, silence on, other windows dimmed, optional timer.
# Usage: apsis-focus.sh on [MINUTES]|off|toggle|status|reset|apply. Edit: the dim amount here.

state="$HOME/.cache/quickshell/apsis-focus"
was="$HOME/.cache/apsis/focus-was"
timer="$HOME/.cache/apsis/focus-timer.pid"
scripts="$HOME/.config/hypr/scripts"
ultra="$HOME/.cache/quickshell/apsis-ultra"
game="$HOME/.cache/quickshell/apsis-game"
mkdir -p "$(dirname "$state")" "$(dirname "$was")"

set_hypr() { hyprctl eval "(function() pcall(hl.config, $1) end)()" >/dev/null 2>&1; }
apply_hypr() {
    set_hypr '{ decoration = { dim_inactive = true, dim_strength = 0.35 } }'
}

stop_timer() {
    if [ -f "$timer" ]; then kill -- "-$(cat "$timer" 2>/dev/null)" 2>/dev/null; fi
    rm -f "$timer"
}

on() {
    mins="$1"
    case "$mins" in ''|*[!0-9]*) mins=0 ;; esac
    if [ -f "$state" ]; then

        if [ "$mins" -gt 0 ]; then start_timer "$mins"; echo "timer set to $mins minutes"; else echo "already on"; fi
        return 0
    fi

    if [ -f "$game" ]; then
        if grep -qx dnd-was-on "$HOME/.cache/apsis/game-was" 2>/dev/null; then prior=on; else prior=off; fi
    else
        prior=$(cat "$HOME/.cache/quickshell/apsis-dnd" 2>/dev/null)
    fi
    {
        printf 'bar=%s\n' "$(cat "$HOME/.cache/quickshell/apsis-bar" 2>/dev/null)"
        printf 'dnd=%s\n' "$prior"
    } > "$was"
    printf on > "$state"
    "$scripts/apsis-bar.sh" hide
    "$scripts/apsis-dnd.sh" on
    [ -f "$ultra" ] || apply_hypr
    [ "$mins" -gt 0 ] && start_timer "$mins"
    notify-send -a Apsis "Focus mode on" "${mins:+$mins minutes, }notifications silenced" 2>/dev/null
}

start_timer() {
    stop_timer
    secs=$(($1 * 60))

    setsid -f sh -c "echo \$\$ > '$timer'; sleep $secs; exec '$0' end" >/dev/null 2>&1
}

restore() {
    rm -f "$state"
    stop_timer
    prior_bar=$(sed -n 's/^bar=//p' "$was" 2>/dev/null)
    prior_dnd=$(sed -n 's/^dnd=//p' "$was" 2>/dev/null)
    [ "$prior_bar" = hide ] || "$scripts/apsis-bar.sh" show
    if [ ! -f "$ultra" ]; then
        hyprctl reload >/dev/null 2>&1
        "$scripts/apsis-display.sh" restore
        [ -f "$game" ] && "$scripts/apsis-game.sh" apply
    fi

    if [ "$prior_dnd" != on ] && [ ! -f "$game" ]; then "$scripts/apsis-dnd.sh" off; fi
    rm -f "$was"
    [ "$1" = loud ] && notify-send -a Apsis "Focus session over" "Everything is back" 2>/dev/null
    return 0
}

off() {
    [ -f "$state" ] || { echo "already off"; return 0; }
    restore quiet
    notify-send -a Apsis "Focus mode off" "Everything is back" 2>/dev/null
}

case "${1:-toggle}" in
    on) on "$2" ;;
    off) off ;;
    end) [ -f "$state" ] && restore loud ;;
    toggle) if [ -f "$state" ]; then off; else on "$2"; fi ;;
    status) [ -f "$state" ] && echo on || echo off ;;
    reset) rm -f "$state" "$was" "$timer" ;;
    apply) [ -f "$state" ] && [ ! -f "$ultra" ] && apply_hypr ;;
    *) echo "usage: $0 on [MINUTES] | off | toggle | status | reset | apply" >&2; exit 2 ;;
esac
