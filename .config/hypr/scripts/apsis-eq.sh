#!/bin/sh
# The phone's equalizer through EasyEffects: writes the "Apsis" preset and loads it.
# Usage: apsis-eq.sh status | apply on|off PREAMP G1..G10. Edit: the band frequencies here.

has_lsp() {
    for d in $(printf '%s' "${LV2_PATH:-}" | tr ':' ' ') "$HOME/.lv2" /usr/lib/lv2 /usr/lib64/lv2 /usr/local/lib/lv2; do
        [ -d "$d/lsp-plugins.lv2" ] && return 0
    done
    ls -d /usr/lib*/lv2/lsp-plugins*.lv2 >/dev/null 2>&1
}

case "$1" in
    status)
        command -v easyeffects >/dev/null 2>&1 || { echo missing; exit 0; }
        has_lsp || { echo nolsp; exit 0; }
        pgrep -x easyeffects >/dev/null 2>&1 && echo ok || echo notrunning
        exit 0 ;;
    apply) ;;
    *) echo "usage: $0 status | apply <on|off> <preamp> <g1..g10>" >&2; exit 2 ;;
esac

command -v easyeffects >/dev/null 2>&1 || exit 1
on="$2"; pre="$3"; shift 3
[ $# -eq 10 ] || { echo "need 10 gains" >&2; exit 2; }

data="${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects/output"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/output"
if [ -d "$data" ]; then dir="$data"
elif [ -d "$conf" ]; then dir="$conf"
else
    major=$(easyeffects --version 2>/dev/null | grep -oE '[0-9]+' | head -1)
    if [ "${major:-8}" -ge 8 ]; then dir="$data"; else dir="$conf"; fi
fi
mkdir -p "$dir"

num() { printf '%s' "$1" | grep -qE '^-?[0-9]+(\.[0-9]+)?$' && printf '%s' "$1" || printf '0'; }
bypass=false; [ "$on" = "on" ] || bypass=true

bands=""
i=0
for f in 32 64 125 250 500 1000 2000 4000 8000 16000; do
    g=$(num "$1"); shift
    [ $i -gt 0 ] && bands="$bands,"
    bands="$bands
        \"band$i\": { \"frequency\": $f.0, \"gain\": $g, \"mode\": \"RLC (BT)\", \"mute\": false, \"q\": 1.41, \"slope\": \"x1\", \"solo\": false, \"type\": \"Bell\", \"width\": 4.0 }"
    i=$((i + 1))
done

tmp="$dir/.Apsis.json.$$"
if ! has_lsp; then
    printf '{\n    "output": {\n        "blocklist": [],\n        "plugins_order": []\n    }\n}\n' > "$tmp"
    mv "$tmp" "$dir/Apsis.json"
    easyeffects -l Apsis >/dev/null 2>&1
    exit 0
fi
cat > "$tmp" <<EOF
{
    "output": {
        "blocklist": [],
        "equalizer#0": {
            "balance": 0.0,
            "bypass": $bypass,
            "input-gain": 0.0,
            "output-gain": $(num "$pre"),
            "mode": "IIR",
            "num-bands": 10,
            "pitch-left": 0.0,
            "pitch-right": 0.0,
            "split-channels": false,
            "left": {$bands
            },
            "right": {$bands
            }
        },
        "plugins_order": [ "equalizer#0" ]
    }
}
EOF
mv "$tmp" "$dir/Apsis.json"
easyeffects -l Apsis >/dev/null 2>&1

[ "$on" = "on" ] && easyeffects -b 2 >/dev/null 2>&1
exit 0
