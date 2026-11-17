#!/bin/sh
# Ultra saver: frees GPU memory by turning off effects, the wallpaper and the GPU drawn shell.
# Usage: apsis-ultra.sh on|off|toggle|status|reset|apply. Edit: what it stops in the on branch.

state="$HOME/.cache/quickshell/apsis-ultra"
was="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/ultra-was"
scripts="$HOME/.config/hypr/scripts"
mkdir -p "$(dirname "$state")" "$(dirname "$was")"

vram() { command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' '; }
ram() { free -m | awk '/^Mem:/ { print $3 }'; }

set_hypr() { hyprctl eval "(function() pcall(hl.config, $1) end)()" >/dev/null 2>&1; }

shell_restart() {
    qs kill >/dev/null 2>&1
    i=0
    while qs list 2>/dev/null | grep -q "^Instance"; do
        i=$((i + 1)); [ "$i" -gt 40 ] && break; sleep 0.1
    done
    if [ "$1" = ultra ]; then
        setsid -f env APSIS_ULTRA=1 QT_QUICK_BACKEND=software "$HOME/.config/hypr/scripts/apsis-shell.sh" start -d >/dev/null 2>&1
    else
        setsid -f "$HOME/.config/hypr/scripts/apsis-shell.sh" start -d >/dev/null 2>&1
    fi
}

report() {
    sleep 3
    v1=$(vram); r1=$(ram)
    msg=""
    if [ -n "$2" ] && [ -n "$v1" ]; then msg="GPU memory: $2 MB -> $v1 MB ($(( $2 - v1 )) MB freed)"; fi
    if [ -n "$3" ] && [ -n "$r1" ]; then
        freed=$(( $3 - r1 )); [ "$freed" -lt 0 ] && freed=0
        msg="$msg${msg:+
}RAM: $freed MB freed"
    fi
    notify-send -a Apsis "$1" "${msg:-Done}" 2>/dev/null
    printf '%s\n' "$msg"
}

apply_hypr() {
    set_hypr '{ animations = { enabled = false } }'
    set_hypr '{ decoration = { blur = { enabled = false } } }'
    set_hypr '{ decoration = { shadow = { enabled = false } } }'
    set_hypr '{ misc = { disable_hyprland_logo = true } }'
    set_hypr '{ misc = { force_default_wallpaper = 0 } }'
    set_hypr '{ misc = { disable_splash_rendering = true } }'
    set_hypr '{ misc = { background_color = 0xff101010 } }'
    set_hypr '{ misc = { vfr = true } }'
}

on() {
    [ -f "$state" ] && { echo "already on"; return 0; }
    v0=$(vram); r0=$(ram)

    : > "$was"
    pgrep -x awww-daemon >/dev/null 2>&1 && echo awww >> "$was"
    pgrep -x mpvpaper    >/dev/null 2>&1 && echo mpvpaper >> "$was"
    pgrep -x easyeffects >/dev/null 2>&1 && echo easyeffects >> "$was"
    printf on > "$state"

    apply_hypr

    pkill -x mpvpaper 2>/dev/null
    easyeffects -q >/dev/null 2>&1 || pkill -x easyeffects 2>/dev/null
    awww kill >/dev/null 2>&1 || pkill -x awww-daemon 2>/dev/null

    shell_restart ultra
    report "Ultra saver on" "$v0" "$r0"
}

off() {
    [ -f "$state" ] || { echo "already off"; return 0; }
    rm -f "$state"

    hyprctl reload >/dev/null 2>&1
    "$scripts/apsis-display.sh" restore

    [ -f "$HOME/.cache/quickshell/apsis-game" ]  && "$scripts/apsis-game.sh" apply
    [ -f "$HOME/.cache/quickshell/apsis-focus" ] && "$scripts/apsis-focus.sh" apply
    if grep -qx awww "$was" 2>/dev/null; then
        setsid -f awww-daemon >/dev/null 2>&1

        setsid -f "$scripts/apsis-wall-restore.sh" >/dev/null 2>&1
    fi
    if grep -qx easyeffects "$was" 2>/dev/null; then
        setsid -f sh -c 'easyeffects --service-mode >/dev/null 2>&1 || easyeffects --gapplication-service >/dev/null 2>&1'
    fi

    shell_restart normal
    notify-send -a Apsis "Ultra saver off" "Everything is back" 2>/dev/null
}

case "${1:-toggle}" in
    on) on ;;
    off) off ;;
    toggle) if [ -f "$state" ]; then off; else on; fi ;;
    status) [ -f "$state" ] && echo on || echo off ;;
    reset) rm -f "$state" ;;
    apply) [ -f "$state" ] && apply_hypr ;;
    *) echo "usage: $0 on | off | toggle | status | reset | apply" >&2; exit 2 ;;
esac
