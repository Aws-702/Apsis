#!/bin/sh
# Wi-Fi through nmcli for the phone's Wi-Fi screen.
# Usage: apsis-wifi.sh list|rescan|status|connect SSID [PASSWORD]|disconnect|forget SSID

TAB=$(printf '\t')
case "$1" in
    list)
        saved=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep ':802-11-wireless$' | sed 's/:802-11-wireless$//')
        nmcli -t -f ACTIVE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | while IFS= read -r line; do
            active=${line%%:*}; rest=${line#*:}
            signal=${rest%%:*}; rest=${rest#*:}
            sec=${rest%%:*}; ssid=${rest#*:}
            ssid=$(printf '%s' "$ssid" | sed 's/\\:/:/g')
            [ -z "$ssid" ] && continue
            known=no
            printf '%s\n' "$saved" | grep -Fxq -- "$ssid" && known=yes
            printf '%s%s%s%s%s%s%s%s%s\n' "$active" "$TAB" "$signal" "$TAB" "$sec" "$TAB" "$ssid" "$TAB" "$known"
        done | awk -F"$TAB" '{ if (!($4 in sig) || $2+0 > sig[$4]+0) { sig[$4]=$2; line[$4]=$0 } } END { for (k in line) print line[k] }'
        ;;
    rescan)
        nmcli dev wifi rescan 2>/dev/null
        ;;
    status)
        line=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -v ':loopback' | grep -vi ':lo$' | head -1)
        name=$(printf '%s' "$line" | cut -d: -f1)
        type=$(printf '%s' "$line" | cut -d: -f2)
        dev=$(printf '%s' "$line" | cut -d: -f3)
        case "$type" in
            *ethernet*) label="$name (Ethernet)" ;;
            *) label="$name" ;;
        esac
        ip=$(nmcli -g IP4.ADDRESS device show "$dev" 2>/dev/null | head -1 | cut -d/ -f1)
        printf '%s%s%s' "$label" "$TAB" "$ip"
        ;;
    connect)
        ssid="$2"; pass="$3"
        if [ -n "$pass" ]; then

            nmcli connection delete id "$ssid" >/dev/null 2>&1
            nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1
        else
            nmcli dev wifi connect "$ssid" >/dev/null 2>&1
        fi
        rc=$?
        if [ $rc -eq 0 ]; then
            notify-send "Wi-Fi" "Connected to $ssid"
        else

            [ -n "$pass" ] && nmcli connection delete id "$ssid" >/dev/null 2>&1
            notify-send -u critical "Wi-Fi" "Could not connect to $ssid"
        fi
        exit $rc
        ;;
    disconnect)
        dev=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | grep ':wifi:connected$' | head -1 | cut -d: -f1)
        [ -n "$dev" ] && nmcli device disconnect "$dev" >/dev/null 2>&1
        ;;
    forget)
        nmcli connection delete id "$2" >/dev/null 2>&1
        ;;
esac
