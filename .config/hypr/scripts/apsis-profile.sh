#!/bin/sh
# Power profile through asusctl, power-profiles-daemon or the kernel: quiet, balanced, performance.
# Usage: apsis-profile.sh get | set PROFILE

norm() {

    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E '
        s/.*(quiet|low-power|power-saver|powersave).*/quiet/;
        s/.*(balanced|balance).*/balanced/;
        s/.*(performance|perf).*/performance/' | head -1
}

get() {
    if command -v asusctl >/dev/null 2>&1; then
        out=$(asusctl profile -p 2>/dev/null); [ -z "$out" ] && out=$(asusctl profile --profile-get 2>/dev/null)
        r=$(norm "$out"); [ -n "$r" ] && { echo "$r"; return; }
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        r=$(norm "$(powerprofilesctl get 2>/dev/null)"); [ -n "$r" ] && { echo "$r"; return; }
    fi
    if [ -r /sys/firmware/acpi/platform_profile ]; then
        r=$(norm "$(cat /sys/firmware/acpi/platform_profile 2>/dev/null)"); [ -n "$r" ] && { echo "$r"; return; }
    fi
}

set_profile() {
    want=$(norm "$1")
    [ -n "$want" ] || exit 1

    if command -v asusctl >/dev/null 2>&1; then
        case "$want" in
            quiet)       a=Quiet ;;
            balanced)    a=Balanced ;;
            performance) a=Performance ;;
        esac
        asusctl profile -P "$a" >/dev/null 2>&1 && exit 0
    fi
    if command -v powerprofilesctl >/dev/null 2>&1; then
        case "$want" in
            quiet)       p=power-saver ;;
            balanced)    p=balanced ;;
            performance) p=performance ;;
        esac
        powerprofilesctl set "$p" >/dev/null 2>&1 && exit 0
    fi
    if [ -w /sys/firmware/acpi/platform_profile ]; then
        case "$want" in
            quiet)       s=low-power ;;
            balanced)    s=balanced ;;
            performance) s=performance ;;
        esac
        echo "$s" > /sys/firmware/acpi/platform_profile 2>/dev/null && exit 0
    fi
    exit 1
}

case "$1" in
    get) get ;;
    set) set_profile "$2" ;;
    *)   echo "usage: $0 get|set <profile>" >&2; exit 2 ;;
esac
