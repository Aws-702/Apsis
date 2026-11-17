#!/bin/sh
# Updates: lists them with pins and groups, runs the update, and pins or unpins whole groups.
# Usage: apsis-updates.sh list|status|pins | run [--hold G] [--release G] [--snapshot] | hold|release hypr|shell | apsis
# Edit: group_re for which packages move together.

CONF=${APSIS_PACMAN_CONF:-/etc/pacman.conf}
SUDO=${APSIS_SUDO-sudo}

group_re() {
    case "$1" in
        hypr)  echo '^(hypr.*|aquamarine|xdg-desktop-portal-hyprland)$' ;;
        shell) echo '^(quickshell(-git)?|qt6-(base|declarative|wayland))$' ;;
        *) return 1 ;;
    esac
}

tag() {
    awk -v held=" $(held_names | tr '\n' ' ') " -v hypr="$(group_re hypr)" -v shell="$(group_re shell)" 'BEGIN { OFS = "\t" }
        { print $1, $2, $3, $4, (index(held, " " $2 " ") ? "held" : "-"), ($2 ~ hypr ? "hypr" : ($2 ~ shell ? "shell" : "-")) }'
}

held_names() {
    awk '/^[[:space:]]*IgnorePkg[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*IgnorePkg[[:space:]]*=[[:space:]]*/, "", line)
            n = split(line, P, /[[:space:]]+/)
            for (i = 1; i <= n; i++) if (P[i] != "") print P[i]
        }' "$CONF" 2>/dev/null
}

edit_ignore() {
    _conf=$1; _mode=$2; _re=$(group_re "$3") || return 1
    _names=""
    [ "$_mode" = add ] && _names=$(pacman -Qq 2>/dev/null | grep -E "$_re" | tr '\n' ' ')
    _has=$(grep -Ec '^[[:space:]]*IgnorePkg[[:space:]]*=' "$_conf")
    awk -v mode="$_mode" -v re="$_re" -v names="$_names" -v has="$_has" '
        BEGIN { n = split(names, N, " "); first = 1 }
        /^[[:space:]]*IgnorePkg[[:space:]]*=/ {
            line = $0
            sub(/^[[:space:]]*IgnorePkg[[:space:]]*=[[:space:]]*/, "", line)
            m = split(line, P, /[[:space:]]+/)
            out = ""
            delete seen
            for (i = 1; i <= m; i++) {
                if (P[i] == "") continue
                if (mode == "remove" && P[i] ~ re) continue
                if (P[i] in seen) continue
                seen[P[i]] = 1
                out = out (out == "" ? "" : " ") P[i]
            }
            if (mode == "add" && first) {
                for (i = 1; i <= n; i++) if (!(N[i] in seen)) { seen[N[i]] = 1; out = out (out == "" ? "" : " ") N[i] }
            }
            first = 0
            if (out != "") print "IgnorePkg = " out
            next
        }
        /^\[options\]/ { print; if (mode == "add" && has == 0 && names != "") { gsub(/ +$/, "", names); print "IgnorePkg = " names }; next }
        { print }
    ' "$_conf"
}

held_updates() {
    db=${CHECKUPDATES_DB:-${TMPDIR:-/tmp}/checkup-db-$(id -u)}
    [ -d "$db/sync" ] || return 0
    names=$(held_names | tr '\n' ' ')
    [ -n "$names" ] || return 0
    # shellcheck disable=SC2086
    inst=$(pacman -Q $names 2>/dev/null)
    # shellcheck disable=SC2086
    pacman --dbpath "$db" -Si $names 2>/dev/null \
        | awk -F' *: *' '/^Name/ { n = $2 } /^Version/ && !(n in seen) { seen[n] = 1; print n, $2 }' \
        | while read -r n new; do
            cur=$(printf '%s\n' "$inst" | awk -v n="$n" '$1 == n { print $2 }')
            [ -n "$cur" ] && [ "$(vercmp "$cur" "$new" 2>/dev/null)" = -1 ] && printf '%s %s %s\n' "$n" "$cur" "$new"
        done
}

apply_pins() {
    [ -z "$HOLD$RELEASE" ] && return 0
    tmp=$(mktemp) || return 1
    cp "$CONF" "$tmp"
    for g in $RELEASE; do edit_ignore "$tmp" remove "$g" > "$tmp.n" && mv "$tmp.n" "$tmp"; done
    for g in $HOLD;    do edit_ignore "$tmp" add "$g"    > "$tmp.n" && mv "$tmp.n" "$tmp"; done
    if cmp -s "$CONF" "$tmp"; then rm -f "$tmp"; return 0; fi
    echo "This changes which packages are pinned in $CONF:"
    echo
    diff -u "$CONF" "$tmp" | tail -n +3
    echo
    printf 'Apply it? [y/N] '
    read -r a
    case "$a" in
        y|Y|yes) ;;
        *) echo "Not changed. Nothing was updated."; rm -f "$tmp"; return 1 ;;
    esac
    if $SUDO cp "$CONF" "$CONF.apsis-backup" && $SUDO cp "$tmp" "$CONF"; then
        echo "Done. The old file is $CONF.apsis-backup"
    else
        echo "Could not write $CONF. Nothing was updated."
        rm -f "$tmp"; return 1
    fi
    rm -f "$tmp"
}

in_terminal() {
    for t in "$TERMINAL" kitty alacritty foot wezterm konsole xterm; do
        { [ -n "$t" ] && command -v "$t" >/dev/null 2>&1; } || continue
        case "$(basename "$t")" in
            kitty|foot) exec "$t" --title "Apsis: updates" "$0" "$@" ;;
            alacritty)  exec "$t" --title "Apsis: updates" -e "$0" "$@" ;;
            wezterm)    exec "$t" start -- "$0" "$@" ;;
            *)          exec "$t" -e "$0" "$@" ;;
        esac
    done
    notify-send "Apsis" "No terminal found to run the update" 2>/dev/null
    exit 1
}

wait_enter() { echo; printf 'Press Enter to close. '; read -r _; }

case "${1:-list}" in
    list)
        command -v checkupdates >/dev/null 2>&1 || { echo missing; exit 0; }
        cu=$(checkupdates 2>/dev/null | awk 'NF >= 4 { print $1, $2, $4 }')
        {
            printf '%s\n' "$cu" | awk 'NF == 3 { print "repo", $0 }'
            held_updates | CU="$cu" awk 'BEGIN { n = split(ENVIRON["CU"], L, "\n"); for (i = 1; i <= n; i++) { split(L[i], f, " "); have[f[1]] = 1 } }
                !($1 in have) { print "repo", $0 }'
            helper=""
            command -v paru >/dev/null 2>&1 && helper=paru
            command -v yay >/dev/null 2>&1 && [ -z "$helper" ] && helper=yay
            [ -n "$helper" ] && "$helper" -Qua 2>/dev/null | awk 'NF >= 4 { print "aur", $1, $2, $4 }'
        } | tag
        ;;
    status)

        if command -v snapper >/dev/null 2>&1 && snapper list-configs 2>/dev/null | grep -Eq '^root[[:space:]]'; then echo "snapper yes"; else echo "snapper no"; fi

        if pacman -Q snap-pac >/dev/null 2>&1; then echo "snappac yes"; else echo "snappac no"; fi

        if pacman -Q limine-snapper-sync >/dev/null 2>&1 || pacman -Q grub-btrfs >/dev/null 2>&1; then echo "bootable yes"; else echo "bootable no"; fi
        ;;
    pins)
        held=" $(held_names | tr '\n' ' ') "
        all=$(pacman -Qq 2>/dev/null)
        for g in hypr shell; do
            members=$(printf '%s\n' "$all" | grep -E "$(group_re "$g")")
            [ -n "$members" ] || continue
            n=0; h=0; miss=""
            for m in $members; do
                n=$((n + 1))
                case "$held" in *" $m "*) h=$((h + 1)) ;; *) miss="$miss $m" ;; esac
            done
            if [ $h -eq 0 ]; then echo "$g free"
            elif [ $h -eq $n ]; then echo "$g held"
            else echo "$g mixed$miss"; fi
        done
        ;;
    edit)
        edit_ignore "$2" "$3" "$4" ;;
    run)
        shift
        HOLD=""; RELEASE=""; SNAPSHOT=0
        args="$*"
        while [ $# -gt 0 ]; do
            case "$1" in
                --hold)    shift; HOLD=$(printf '%s' "${1:-}" | tr ',' ' ') ;;
                --release) shift; RELEASE=$(printf '%s' "${1:-}" | tr ',' ' ') ;;
                --snapshot) SNAPSHOT=1 ;;
            esac
            shift
        done

        if [ ! -t 0 ] || [ ! -t 1 ]; then
            # shellcheck disable=SC2086
            in_terminal run $args
        fi
        apply_pins || { wait_enter; exit 1; }
        if [ "$SNAPSHOT" = 1 ]; then
            if pacman -Q snap-pac >/dev/null 2>&1; then
                echo "snap-pac takes a snapshot before and after the update by itself."
            elif command -v snapper >/dev/null 2>&1 && snapper list-configs 2>/dev/null | grep -Eq '^root[[:space:]]'; then
                echo "Taking a snapshot of / first..."
                sudo snapper -c root create -d "Apsis: before update" || { echo "The snapshot failed. Nothing was updated."; wait_enter; exit 1; }
            else
                echo "No snapshot tool is set up, so there is no snapshot."
            fi
            echo
        fi
        if command -v paru >/dev/null 2>&1; then paru -Syu
        elif command -v yay >/dev/null 2>&1; then yay -Syu
        else sudo pacman -Syu
        fi
        wait_enter
        ;;
    apsis)
        if [ ! -t 0 ] || [ ! -t 1 ]; then in_terminal apsis; fi
        sh "$HOME/.config/apsis/update.sh" update
        wait_enter
        ;;
    hold|release)
        mode=$1; g=${2:-}
        group_re "$g" >/dev/null 2>&1 || { echo "usage: apsis-updates.sh hold|release hypr|shell" >&2; exit 2; }
        if [ ! -t 0 ] || [ ! -t 1 ]; then in_terminal "$mode" "$g"; fi
        if [ "$mode" = hold ]; then HOLD=$g; RELEASE=""; else RELEASE=$g; HOLD=""; fi
        apply_pins
        wait_enter
        ;;
esac
