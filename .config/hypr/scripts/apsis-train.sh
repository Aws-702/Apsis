#!/bin/sh
# Training mode: Ultra saver plus a tmux session (apsis-train) for your run.
# Usage: apsis-train.sh start|stop|toggle|attach|status|reset. Edit: session for the tmux name.

session="apsis-train"
state="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/train"
scripts="$HOME/.config/hypr/scripts"
mkdir -p "$(dirname "$state")"

term() {
    for t in kitty foot alacritty wezterm; do
        command -v "$t" >/dev/null 2>&1 && { echo "$t"; return; }
    done
}
alive() { command -v tmux >/dev/null 2>&1 && tmux has-session -t "$session" 2>/dev/null; }

attach() {
    if ! command -v tmux >/dev/null 2>&1; then
        notify-send -a Apsis "Training mode" "tmux isn't installed (sudo pacman -S tmux). Ultra saver is on without it." 2>/dev/null
        return 1
    fi
    t=$(term)
    [ -n "$t" ] || { echo "no terminal found" >&2; return 1; }
    case "$t" in
        kitty)     setsid -f kitty --class apsis-train --title "Training" tmux new-session -A -s "$session" >/dev/null 2>&1 ;;
        wezterm)   setsid -f wezterm start -- tmux new-session -A -s "$session" >/dev/null 2>&1 ;;
        *)         setsid -f "$t" -e tmux new-session -A -s "$session" >/dev/null 2>&1 ;;
    esac
}

start() {
    [ -f "$state" ] || date +%s > "$state"
    [ "$("$scripts/apsis-ultra.sh" status)" = on ] || "$scripts/apsis-ultra.sh" on >/dev/null
    attach
}

stop() {
    rm -f "$state"
    [ "$("$scripts/apsis-ultra.sh" status)" = on ] && "$scripts/apsis-ultra.sh" off >/dev/null
    if alive; then
        notify-send -a Apsis "Training mode off" "Your tmux session \"$session\" is still running (tmux attach -t $session)." 2>/dev/null
    fi
}

status() {

    if [ -f "$state" ] && [ "$("$scripts/apsis-ultra.sh" status)" != on ]; then rm -f "$state"; fi
    on=off; [ -f "$state" ] && on=on
    a=no; alive && a=yes
    printf '%s\t%s\t%s\n' "$on" "$a" "$(cat "$state" 2>/dev/null)"
}

case "${1:-toggle}" in
    start) start ;;
    stop) stop ;;
    toggle) if [ -f "$state" ]; then stop; else start; fi ;;
    attach) attach ;;
    status) status ;;
    reset) rm -f "$state" ;;
    *) echo "usage: $0 start | stop | toggle | attach | status | reset" >&2; exit 2 ;;
esac
