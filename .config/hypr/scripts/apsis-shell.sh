#!/bin/sh
# Start, restart and size the Apsis shell (quickshell).
#   apsis-shell.sh start [-d]       start it (-d: detached), with the saved size
#   apsis-shell.sh restart          stop it and start it again, detached
#   apsis-shell.sh scale            show the saved sizes
#   apsis-shell.sh scale 1.25       size for every monitor (0.75 to 2.5)
#   apsis-shell.sh scale eDP-1 1.5  size for one monitor
#   apsis-shell.sh scale reset      back to 1
# Edit: the allowed size range in valid_factor.

file="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/shell-scale"

valid_factor() { printf '%s' "$1" | grep -Eq '^([0-9](\.[0-9]{1,3})?)$' && awk -v f="$1" 'BEGIN{exit !(f >= 0.75 && f <= 2.5)}'; }
valid_name() { printf '%s' "$1" | grep -Eq '^[A-Za-z0-9_.-]{1,40}$'; }

export_scale() {
    [ -s "$file" ] || return 0
    all=$(sed -n 's/^all=//p' "$file" | head -1)
    if [ -n "$all" ] && valid_factor "$all"; then export QT_SCALE_FACTOR="$all"; fi
    per=""
    while IFS='=' read -r n f; do
        [ "$n" = all ] && continue
        valid_name "$n" && valid_factor "$f" && per="${per:+$per;}$n=$f"
    done < "$file"
    [ -n "$per" ] && export QT_SCREEN_SCALE_FACTORS="$per"
    return 0
}

start() {
    export_scale
    if [ "$1" = "-d" ]; then exec qs -n -d; else exec qs -n; fi
}

case "$1" in
start) shift; start "$1" ;;
restart)
    qs kill >/dev/null 2>&1
    i=0
    while qs list 2>/dev/null | grep -q '^Instance' && [ "$i" -lt 25 ]; do i=$((i + 1)); sleep 0.2; done
    ( start -d ) >/dev/null 2>&1
    ;;
scale)
    shift
    mkdir -p "$(dirname "$file")"
    case "$1" in
    "") [ -s "$file" ] && cat "$file" || echo "all=1" ; exit 0 ;;
    reset) rm -f "$file" ;;
    *)
        if valid_factor "$1"; then name=all; f="$1"
        elif valid_name "$1" && valid_factor "$2"; then name="$1"; f="$2"
        else echo "usage: $0 scale [FACTOR | NAME FACTOR | reset]  (0.75 to 2.5)" >&2; exit 2; fi
        tmp="$file.$$"
        { [ -f "$file" ] && grep -v "^$name=" "$file"; echo "$name=$f"; } > "$tmp"
        mv "$tmp" "$file" ;;
    esac
    if qs list 2>/dev/null | grep -q '^Instance'; then "$0" restart; fi
    ;;
*)
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
    exit 2 ;;
esac
