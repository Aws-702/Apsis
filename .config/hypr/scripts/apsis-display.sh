#!/bin/sh
# Monitors for Settings > Display: try a layout with a 15 second revert, keep, revert, apply.
# Edit: the revert delay here; kept layouts go to ~/.local/state/apsis/monitors.lua.

file="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/monitors.lua"
pending="${XDG_RUNTIME_DIR:-/tmp}/apsis-display-pending"
mkdir -p "$(dirname "$file")"

die() { echo "$*" >&2; exit 2; }
ok_name() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_.-]{1,40}$' || die "bad monitor name: $1"; }

line_for() {
    ok_name "$1"
    printf '%s' "$2" | grep -Eq '^(preferred|highres|highrr|[0-9]{3,5}x[0-9]{3,5}(@[0-9]{1,3}(\.[0-9]{1,3})?)?)$' || die "bad mode: $2"
    printf '%s' "$3" | grep -Eq '^(auto|-?[0-9]{1,5}x-?[0-9]{1,5})$' || die "bad position: $3"
    printf '%s' "$4" | grep -Eq '^[0-9](\.[0-9]{1,6})?$' || die "bad scale: $4"
    printf '%s' "$5" | grep -Eq '^[0-7]$' || die "bad transform: $5"
    l="hl.monitor({ output = \"$1\", mode = \"$2\", position = \"$3\", scale = $4, transform = $5"
    if [ -n "$6" ] && [ "$6" != "-" ]; then ok_name "$6"; l="$l, mirror = \"$6\""; fi
    printf '%s })' "$l"
}

run() {
    out=$(hyprctl eval "$1" 2>&1)
    case "$out" in ok*|"") return 0 ;; esac
    echo "Hyprland refused it: $out" >&2
    return 1
}

save() {
    tmp="$file.$$"
    { printf -- '-- Apsis: monitors set in Settings > Display (scripts/apsis-display.sh)\n'
      [ -f "$file" ] && grep -F 'hl.monitor(' "$file" | grep -vF "output = \"$1\""
      [ -n "$2" ] && printf '%s\n' "$2"
    } > "$tmp"
    mv "$tmp" "$file"
}

case "$1" in
    try)
        shift
        [ $# -eq 11 ] || die "try needs the new and the previous layout"
        new=$(line_for "$1" "$2" "$3" "$4" "$5" "$6") || exit 2
        old=$(line_for "$1" "$7" "$8" "$9" "${10}" "${11}") || exit 2
        token="$$-$(date +%s%N)"
        printf '%s\t%s\n' "$token" "$old" > "$pending"
        run "$new"

        setsid -f sh -c '
            sleep 15
            [ "$(cut -f1 "$1" 2>/dev/null)" = "$2" ] || exit 0
            l=$(cut -f2- "$1"); rm -f "$1"
            hyprctl eval "$l" >/dev/null 2>&1
            notify-send -a Apsis "Display" "Went back to the previous layout" 2>/dev/null
        ' sh "$pending" "$token" >/dev/null 2>&1 ;;
    revert)
        [ -f "$pending" ] || exit 0
        l=$(cut -f2- "$pending"); rm -f "$pending"
        run "$l" ;;
    apply) shift; l=$(line_for "$@") || exit 2; run "$l" ;;
    keep)  shift; rm -f "$pending"; l=$(line_for "$@") || exit 2; run "$l" && save "$1" "$l" ;;
    off)   ok_name "$2"; l="hl.monitor({ output = \"$2\", disabled = true })"; run "$l" && save "$2" "$l" ;;
    forget) ok_name "$2"; save "$2" ""; hyprctl reload >/dev/null 2>&1 ;;
    reset) rm -f "$file"; hyprctl reload >/dev/null 2>&1 ;;
    show)  cat "$file" 2>/dev/null ;;
    restore)
        [ -f "$file" ] || exit 0
        grep -E '^hl\.monitor\(\{ output = "[A-Za-z0-9_.-]+",' "$file" | while IFS= read -r l; do run "$l"; done ;;
    *) echo "usage: $0 try NAME <new layout> <previous layout> | revert | apply|keep NAME MODE POS SCALE TRANSFORM [MIRROR] | off NAME | forget NAME | reset | show | restore" >&2; exit 2 ;;
esac
