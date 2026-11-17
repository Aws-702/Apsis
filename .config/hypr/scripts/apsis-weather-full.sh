#!/usr/bin/env bash
# Current weather plus the 5 day forecast as JSON for the forecast widget (cached 30 minutes).
# Usage: apsis-weather-full.sh [force]. Edit: max_age for the cache; key and city in weather.conf.

set -u

conf="$HOME/.config/apsis/weather.conf"
cache="$HOME/.cache/quickshell/apsis-weather-full.cache"
max_age=1800

if [ "${1:-}" != "force" ] && [ -f "$cache" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
    [ "$age" -lt "$max_age" ] && { cat "$cache"; exit 0; }
fi

[ -f "$conf" ] || exit 0
# shellcheck disable=SC1090
. "$conf"
: "${APIKEY:=}"; : "${CITY:=}"; : "${UNITS:=metric}"
[ -n "$APIKEY" ] && [ -n "$CITY" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

base="https://api.openweathermap.org/data/2.5"
cur=$(curl -fsS --max-time 8 "$base/weather?q=${CITY}&units=${UNITS}&appid=${APIKEY}" 2>/dev/null) \
    || { [ -f "$cache" ] && cat "$cache"; exit 0; }
fc=$(curl -fsS --max-time 8 "$base/forecast?q=${CITY}&units=${UNITS}&appid=${APIKEY}" 2>/dev/null) \
    || { [ -f "$cache" ] && cat "$cache"; exit 0; }

out=$(jq -n --argjson c "$cur" --argjson f "$fc" '
  (($f.city.timezone) // 0) as $tz |
  {
    city:     ($c.name // ""),
    country:  ($c.sys.country // ""),
    temp:     (($c.main.temp // 0) | round),
    feels:    (($c.main.feels_like // 0) | round),
    cond:     ($c.weather[0].main // ""),
    desc:     ($c.weather[0].description // ""),
    hi:       (($c.main.temp_max // 0) | round),
    lo:       (($c.main.temp_min // 0) | round),
    humidity: (($c.main.humidity // 0) | round),
    wind:     (($c.wind.speed // 0)),
    sunrise:  ((($c.sys.sunrise // 0) + $tz) | strftime("%-I:%M %p")),
    sunset:   ((($c.sys.sunset  // 0) + $tz) | strftime("%-I:%M %p")),
    hourly:   ([{ t: "Now",
                  temp: ($c.main.temp | round),
                  cond: ($c.weather[0].description // ""),
                  pop:  ((($f.list[0].pop // 0) * 100) | round) }]
               + ($f.list[0:7] | map({
                   t:    ((.dt + $tz) | strftime("%-I %p")),
                   temp: (.main.temp | round),
                   cond: (.weather[0].description),
                   pop:  (((.pop // 0) * 100) | round)
                 }))),
    daily:    ($f.list
               | group_by((.dt + $tz) | strftime("%Y-%m-%d"))
               | map({
                   d:    ((.[0].dt + $tz) | strftime("%a")),
                   hi:   ([.[].main.temp_max] | max | round),
                   lo:   ([.[].main.temp_min] | min | round),
                   cond: (((map(select(((.dt + $tz) | strftime("%H")) == "12")))[0] // .[0]).weather[0].description)
                 })
               | .[0:6])
  }')

[ -n "$out" ] || { [ -f "$cache" ] && cat "$cache"; exit 0; }
mkdir -p "$(dirname "$cache")"
printf '%s' "$out" | tee "$cache"
