#!/bin/sh
# Prints CPU percent, RAM percent and temperature for the bar and widgets.
# Edit: the temperature sensor it reads here.

read -r _ a b c d e f g h _ < /proc/stat
idle1=$d; total1=$((a+b+c+d+e+f+g+h))
sleep 0.4
read -r _ a b c d e f g h _ < /proc/stat
idle2=$d; total2=$((a+b+c+d+e+f+g+h))
didle=$((idle2-idle1)); dtotal=$((total2-total1))
cpu=0; [ "$dtotal" -gt 0 ] && cpu=$(( (100*(dtotal-didle))/dtotal ))

ram=$(free | awk '/^Mem:/{printf "%d", ($3/$2)*100}')

temp=0
for z in /sys/class/thermal/thermal_zone*/temp; do
    v=$(cat "$z" 2>/dev/null)
    [ -n "$v" ] && [ "$v" -gt 0 ] && temp=$((v / 1000)) && break
done

printf '%s %s %s' "$cpu" "$ram" "$temp"
