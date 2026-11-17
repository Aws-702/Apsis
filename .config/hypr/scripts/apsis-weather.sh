#!/usr/bin/env bash
# Current weather as one tab separated line (cached 10 minutes).
# Edit: max_age for the cache; APIKEY, CITY and UNITS in ~/.config/apsis/weather.conf.

set -u

conf="$HOME/.config/apsis/weather.conf"
cache="$HOME/.cache/quickshell/apsis-weather.cache"
max_age=600

if [ "${1:-}" != "force" ] && [ -f "$cache" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$cache" 2>/dev/null || echo 0) ))
    if [ "$age" -lt "$max_age" ]; then cat "$cache"; exit 0; fi
fi

[ -f "$conf" ] || exit 0
# shellcheck disable=SC1090
. "$conf"
: "${APIKEY:=}"; : "${CITY:=}"; : "${UNITS:=metric}"
[ -n "$APIKEY" ] && [ -n "$CITY" ] || exit 0

base="https://api.openweathermap.org/data/2.5"
resp=$(curl -fsS --max-time 8 "$base/weather?q=${CITY}&units=${UNITS}&appid=${APIKEY}" 2>/dev/null) \
    || { [ -f "$cache" ] && cat "$cache"; exit 0; }

r() { printf '%.0f' "$1" 2>/dev/null || printf '%s' "$1"; }

if command -v jq >/dev/null 2>&1; then

    fc=$(curl -fsS --max-time 8 "$base/forecast?q=${CITY}&units=${UNITS}&appid=${APIKEY}" 2>/dev/null)

    line=$(printf '%s' "$resp" | jq -r --argjson f "${fc:-null}" '
        (($f.city.timezone) // 0) as $tz |
        (if $f == null then [] else
           ($f.list | map(select(((.dt + $tz) | strftime("%Y-%m-%d"))
                                  == ((($f.list[0].dt) + $tz) | strftime("%Y-%m-%d")))))
         end) as $today |
        ((if ($today | length) > 0 then ([$today[].main.temp_max] | max) else (.main.temp_max // 0) end) | round) as $hi |
        ((if ($today | length) > 0 then ([$today[].main.temp_min] | min) else (.main.temp_min // 0) end) | round) as $lo |
        [ ((.main.temp // 0) | round),
          (.weather[0].main // ""),
          (.weather[0].description // ""),
          ((.main.feels_like // 0) | round),
          $hi,
          $lo,
          ((.main.humidity // 0) | round),
          (.name // "") ] | @tsv')
    t=$(printf '%s' "$line" | cut -f1)
    [ -n "$t" ] || { [ -f "$cache" ] && cat "$cache"; exit 0; }
else
    temp=$(printf '%s' "$resp" | sed -n 's/.*"temp":\([0-9.-]*\).*/\1/p')
    cond=$(printf '%s' "$resp" | sed -n 's/.*"main":"\([A-Za-z]*\)".*/\1/p' | head -1)
    [ -n "$temp" ] || { [ -f "$cache" ] && cat "$cache"; exit 0; }
    line=$(printf '%s\t%s\t%s\t\t\t\t\t' "$(r "$temp")" "${cond:-}" "${cond:-}")
fi

mkdir -p "$(dirname "$cache")"
printf '%s' "$line" | tee "$cache"
