#!/bin/sh
# Turns the screens off or on in whatever dispatch syntax this Hyprland accepts.
# Usage: apsis-screen.sh off|on

try() {
    out=$(hyprctl dispatch "$1" 2>&1)
    case "$out" in ok*|"") return 0 ;; esac
    return 1
}

case "${1:-}" in
    off) try 'hl.dsp.dpms({ action = "off" })' || try 'dpms off' ;;
    on)  try 'hl.dsp.dpms({ action = "on" })' \
            || try 'hl.dsp.dpms({ action = "enable" })' \
            || try 'dpms on' ;;
    *) echo "usage: $0 on | off" >&2; exit 2 ;;
esac
