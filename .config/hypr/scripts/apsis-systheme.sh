#!/bin/sh
# Colours apps outside the shell: Qt5 and Qt6 schemes, KDE, kitty, foot and alacritty.
# Usage: apsis-systheme.sh [status]. Edit: the file each part writes here.

cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
json="$cache/apsis-theme.json"
settings="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/settings.json"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
data="${XDG_DATA_HOME:-$HOME/.local/share}"

command -v jq >/dev/null 2>&1 || { echo "systheme: needs jq" >&2; exit 1; }

on() {
    [ -f "$settings" ] || return 0
    [ "$(jq -r --arg k "$1" 'if has($k) then .[$k] else true end' "$settings" 2>/dev/null)" != "false" ]
}

if [ "$1" = status ]; then
    for f in "$cfg/qt5ct/colors/apsis.conf" "$cfg/qt6ct/colors/apsis.conf" "$data/color-schemes/Apsis.colors" \
             "$cfg/apsis/terminal/kitty.conf" "$cfg/apsis/terminal/foot.ini" "$cfg/apsis/terminal/alacritty.toml"; do
        [ -f "$f" ] && echo "ok       $f" || echo "missing  $f"
    done
    exit 0
fi

[ -s "$json" ] || { echo "systheme: no $json yet (the shell writes it)" >&2; exit 0; }
g() { jq -r --arg k "$1" '.[$k] // empty' "$json"; }
bgMain=$(g bgMain); bgCard=$(g bgCard); bgItem=$(g bgItem); bgHover=$(g bgHover)
fg=$(g textPrimary); fg2=$(g textSecondary)
accent=$(g accent); hot=$(g accentHot); cyan=$(g cyan); warn=$(g warn); danger=$(g danger); onAccent=$(g onAccent)
for v in "$bgMain" "$bgCard" "$bgItem" "$bgHover" "$fg" "$fg2" "$accent" "$hot" "$cyan" "$warn" "$danger" "$onAccent"; do
    printf '%s' "$v" | grep -Eq '^#[0-9A-Fa-f]{6}$' || { echo "systheme: $json has a bad colour ($v)" >&2; exit 1; }
done

mix() {
    a=${1#\#}; b=${2#\#}; p=$3
    out="#"
    for i in 1 3 5; do
        ca=$(printf '%d' "0x$(printf '%s' "$a" | cut -c"$i-$((i + 1))")")
        cb=$(printf '%d' "0x$(printf '%s' "$b" | cut -c"$i-$((i + 1))")")
        out="$out$(printf '%02x' $(( (ca * (100 - p) + cb * p) / 100 )))"
    done
    printf '%s' "$out"
}
rgb() { a=${1#\#}; printf '%d,%d,%d' "0x$(printf '%s' "$a" | cut -c1-2)" "0x$(printf '%s' "$a" | cut -c3-4)" "0x$(printf '%s' "$a" | cut -c5-6)"; }
argb() { printf '#ff%s' "${1#\#}"; }

mkdir -p "$cache"

qt_scheme() {
    light=$(mix "$bgItem" "#ffffff" 20)
    dark=$(mix "$bgMain" "#000000" 35)
    mid=$(mix "$bgHover" "$bgMain" 40)
    active="$(argb "$fg"), $(argb "$bgItem"), $(argb "$light"), $(argb "$bgHover"), $(argb "$dark"), $(argb "$mid"), $(argb "$fg"), #ffffffff, $(argb "$fg"), $(argb "$bgCard"), $(argb "$bgMain"), #ff000000, $(argb "$accent"), $(argb "$onAccent"), $(argb "$cyan"), $(argb "$hot"), $(argb "$bgItem"), #ff000000, $(argb "$bgCard"), $(argb "$fg"), $(argb "$fg2")"
    disabled="$(argb "$fg2"), $(argb "$bgItem"), $(argb "$light"), $(argb "$bgHover"), $(argb "$dark"), $(argb "$mid"), $(argb "$fg2"), #ffffffff, $(argb "$fg2"), $(argb "$bgCard"), $(argb "$bgMain"), #ff000000, $(argb "$bgHover"), $(argb "$fg2"), $(argb "$cyan"), $(argb "$hot"), $(argb "$bgItem"), #ff000000, $(argb "$bgCard"), $(argb "$fg2"), $(argb "$fg2")"
    for q in qt5ct qt6ct; do
        d="$cfg/$q"; mkdir -p "$d/colors"
        printf '[ColorScheme]\nactive_colors=%s\ninactive_colors=%s\ndisabled_colors=%s\n' "$active" "$active" "$disabled" > "$d/colors/apsis.conf"
        conf="$d/$q.conf"
        scheme="$d/colors/apsis.conf"
        if [ ! -f "$conf" ]; then
            printf '[Appearance]\ncolor_scheme_path=%s\ncustom_palette=true\nstyle=Fusion\n' "$scheme" > "$conf"
        else
            ini_set "$conf" Appearance color_scheme_path "$scheme"
            ini_set "$conf" Appearance custom_palette true
        fi
    done
}

ini_set() {
    f="$1"; sec="$2"; key="$3"; val="$4"
    tmp="$f.$$"
    awk -v sec="$sec" -v key="$key" -v val="$val" '
        BEGIN { insec = 0; done = 0; seen = 0 }
        /^\[/ {
            if (insec && !done) { print key "=" val; done = 1 }
            insec = ($0 == "[" sec "]"); if (insec) seen = 1
            print; next
        }
        insec && $0 ~ "^" key "=" { print key "=" val; done = 1; next }
        { print }
        END {
            if (insec && !done) print key "=" val
            else if (!seen) { print ""; print "[" sec "]"; print key "=" val }
        }' "$f" > "$tmp" && mv "$tmp" "$f"
}

kde_scheme() {
    mkdir -p "$data/color-schemes"
    sel=$(rgb "$accent"); selfg=$(rgb "$onAccent")
    set_block() {

        printf '[Colors:%s]\nBackgroundNormal=%s\nBackgroundAlternate=%s\nForegroundNormal=%s\nForegroundInactive=%s\nForegroundActive=%s\nForegroundLink=%s\nForegroundVisited=%s\nForegroundNegative=%s\nForegroundNeutral=%s\nForegroundPositive=%s\nDecorationFocus=%s\nDecorationHover=%s\n\n' \
            "$1" "$(rgb "$2")" "$(rgb "$3")" "$(rgb "$fg")" "$(rgb "$fg2")" "$sel" "$(rgb "$cyan")" "$(rgb "$hot")" "$(rgb "$danger")" "$(rgb "$warn")" "$(rgb "$(mix "$accent" "#80ff80" 50)")" "$sel" "$sel"
    }
    {
        printf '[General]\nName=Apsis\nColorScheme=Apsis\n\n'
        set_block View "$bgCard" "$bgItem"
        set_block Window "$bgMain" "$bgCard"
        set_block Button "$bgItem" "$bgHover"
        set_block Tooltip "$bgCard" "$bgItem"
        set_block Complementary "$bgMain" "$bgCard"
        printf '[Colors:Selection]\nBackgroundNormal=%s\nBackgroundAlternate=%s\nForegroundNormal=%s\nForegroundInactive=%s\nForegroundActive=%s\nForegroundLink=%s\nForegroundVisited=%s\nForegroundNegative=%s\nForegroundNeutral=%s\nForegroundPositive=%s\nDecorationFocus=%s\nDecorationHover=%s\n\n' \
            "$sel" "$(rgb "$(mix "$accent" "$bgMain" 20)")" "$selfg" "$selfg" "$selfg" "$selfg" "$selfg" "$selfg" "$selfg" "$selfg" "$sel" "$sel"
    } > "$data/color-schemes/Apsis.colors"
    if command -v kwriteconfig6 >/dev/null 2>&1; then
        kwriteconfig6 --file kdeglobals --group General --key ColorScheme Apsis
    elif command -v kwriteconfig5 >/dev/null 2>&1; then
        kwriteconfig5 --file kdeglobals --group General --key ColorScheme Apsis
    else
        [ -f "$cfg/kdeglobals" ] || : > "$cfg/kdeglobals"
        ini_set "$cfg/kdeglobals" General ColorScheme Apsis
    fi
}

terminal_files() {
    d="$cfg/apsis/terminal"; mkdir -p "$d"
    green=$(mix "#7fd98a" "$accent" 18)
    blue=$(mix "$cyan" "$bgMain" 35)
    bright() { mix "$1" "#ffffff" 25; }
    cat > "$d/kitty.conf" <<K
# written by apsis-systheme.sh; changes are overwritten
foreground $fg
background $bgMain
selection_foreground $onAccent
selection_background $accent
cursor $accent
cursor_text_color $onAccent
url_color $cyan
active_border_color $accent
inactive_border_color $bgHover
color0 $bgItem
color1 $danger
color2 $green
color3 $warn
color4 $blue
color5 $hot
color6 $cyan
color7 $fg2
color8 $bgHover
color9 $(bright "$danger")
color10 $(bright "$green")
color11 $(bright "$warn")
color12 $(bright "$blue")
color13 $(bright "$hot")
color14 $(bright "$cyan")
color15 $fg
K
    strip() { printf '%s' "${1#\#}"; }
    cat > "$d/foot.ini" <<F
# written by apsis-systheme.sh; use it with: include=~/.config/apsis/terminal/foot.ini
[colors]
foreground=$(strip "$fg")
background=$(strip "$bgMain")
selection-foreground=$(strip "$onAccent")
selection-background=$(strip "$accent")
regular0=$(strip "$bgItem")
regular1=$(strip "$danger")
regular2=$(strip "$green")
regular3=$(strip "$warn")
regular4=$(strip "$blue")
regular5=$(strip "$hot")
regular6=$(strip "$cyan")
regular7=$(strip "$fg2")
bright0=$(strip "$bgHover")
bright1=$(strip "$(bright "$danger")")
bright2=$(strip "$(bright "$green")")
bright3=$(strip "$(bright "$warn")")
bright4=$(strip "$(bright "$blue")")
bright5=$(strip "$(bright "$hot")")
bright6=$(strip "$(bright "$cyan")")
bright7=$(strip "$fg")
F
    cat > "$d/alacritty.toml" <<A
# written by apsis-systheme.sh; use it with: general.import = ["~/.config/apsis/terminal/alacritty.toml"]
[colors.primary]
foreground = "$fg"
background = "$bgMain"
[colors.cursor]
text = "$onAccent"
cursor = "$accent"
[colors.selection]
text = "$onAccent"
background = "$accent"
[colors.normal]
black = "$bgItem"
red = "$danger"
green = "$green"
yellow = "$warn"
blue = "$blue"
magenta = "$hot"
cyan = "$cyan"
white = "$fg2"
[colors.bright]
black = "$bgHover"
red = "$(bright "$danger")"
green = "$(bright "$green")"
yellow = "$(bright "$warn")"
blue = "$(bright "$blue")"
magenta = "$(bright "$hot")"
cyan = "$(bright "$cyan")"
white = "$fg"
A

    kc="$cfg/kitty/kitty.conf"
    if [ -f "$kc" ] && ! grep -q 'apsis/terminal/kitty.conf' "$kc"; then
        printf '\n# Apsis colours (apsis-systheme.sh)\ninclude %s/apsis/terminal/kitty.conf\n' "$cfg" >> "$kc"
    fi
    pkill -USR1 -x kitty 2>/dev/null
    return 0
}

on sysThemeQt && qt_scheme
on sysThemeKde && kde_scheme
on sysThemeTerminal && terminal_files
exit 0
