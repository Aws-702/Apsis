#!/bin/sh
# Sets the weather city in ~/.config/apsis/weather.conf and clears the caches.
# Usage: apsis-set-city.sh "City" or "City,CC"

conf="$HOME/.config/apsis/weather.conf"
val="$1"
[ -n "$val" ] || exit 1
mkdir -p "$(dirname "$conf")"
[ -f "$conf" ] || printf 'APIKEY=\nCITY=\nUNITS=metric\n' > "$conf"

esc=$(printf '%s' "$val" | sed 's/[&|\\]/\\&/g')
if grep -q '^CITY=' "$conf"; then
    sed -i "s|^CITY=.*|CITY=$esc|" "$conf"
else
    printf 'CITY=%s\n' "$val" >> "$conf"
fi
rm -f "$HOME/.cache/quickshell/apsis-weather.cache" \
      "$HOME/.cache/quickshell/apsis-weather-full.cache"
