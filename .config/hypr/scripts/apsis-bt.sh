#!/bin/sh
# Bluetooth helper for the bar and Sys: status, device list, power, scan, connect.
# Usage: apsis-bt.sh status|list|power on|off|scan|connect MAC|disconnect MAC

TAB=$(printf '\t')
case "$1" in
    status)
        bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo on || echo off ;;
    list)
        bluetoothctl devices 2>/dev/null | while IFS= read -r line; do
            mac=$(printf '%s' "$line" | awk '{print $2}')
            name=$(printf '%s' "$line" | cut -d' ' -f3-)
            [ -z "$mac" ] && continue
            conn=no
            bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes" && conn=yes
            printf '%s%s%s%s%s\n' "$conn" "$TAB" "$mac" "$TAB" "$name"
        done ;;
    power) bluetoothctl power "$2" >/dev/null 2>&1 ;;
    scan) bluetoothctl --timeout 6 scan on >/dev/null 2>&1 ;;
    connect)
        bluetoothctl connect "$2" >/dev/null 2>&1 \
            && notify-send "Bluetooth" "Connected" \
            || notify-send -u critical "Bluetooth" "Could not connect" ;;
    disconnect)
        bluetoothctl disconnect "$2" >/dev/null 2>&1 && notify-send "Bluetooth" "Disconnected" ;;
esac
