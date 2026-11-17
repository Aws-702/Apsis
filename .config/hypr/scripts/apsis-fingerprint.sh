#!/bin/sh
# Fingerprint helper for the lockscreen: status, enroll, ready.
# Usage: apsis-fingerprint.sh status|enroll|ready

user="${USER:-$(id -un)}"

have_fprintd() { command -v fprintd-list >/dev/null 2>&1; }
listing() { fprintd-list "$user" 2>/dev/null; }

case "$1" in
status)
    if ! have_fprintd; then echo "fprintd is not installed (sudo pacman -S fprintd)"; exit 0; fi
    out=$(listing)
    case "$out" in
        *"No devices"*|"") echo "No fingerprint reader found" ;;
        *) n=$(printf '%s\n' "$out" | grep -c '^ *- #')
           if printf '%s' "$out" | grep -qi 'no fingers enrolled'; then
               echo "Reader found, but no finger enrolled yet"
           else
               echo "Ready: $((n > 0 ? n : 1)) finger(s) enrolled"
           fi ;;
    esac ;;
ready)
    have_fprintd && listing | grep -qi 'finger' && ! listing | grep -qi 'no fingers enrolled' ;;
enroll)
    have_fprintd || { echo "fprintd is not installed" >&2; exit 1; }
    for t in kitty foot alacritty wezterm ghostty konsole gnome-terminal xterm; do
        if command -v "$t" >/dev/null 2>&1; then
            case "$t" in
                gnome-terminal) exec "$t" -- sh -c 'fprintd-enroll; printf "\nPress Enter to close"; read -r _' ;;
                *)              exec "$t" -e sh -c 'fprintd-enroll; printf "\nPress Enter to close"; read -r _' ;;
            esac
        fi
    done
    echo "no terminal found; run fprintd-enroll yourself" >&2; exit 1 ;;
*) echo "usage: $0 status|enroll|ready" >&2; exit 2 ;;
esac
