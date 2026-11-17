#!/bin/sh
# Tests apsis-updates.sh: groups, pins in pacman.conf, list columns, snapshot status.
# Run: sh ~/.config/apsis/tests/updates_test.sh

set -u

here=$(cd "$(dirname "$0")/../.." && pwd)
S="$here/hypr/scripts/apsis-updates.sh"
[ -f "$S" ] || { echo "can't find apsis-updates.sh next to the tests"; exit 2; }

T=$(mktemp -d "${TMPDIR:-/tmp}/apsis-updates-test.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
B="$T/bin"; mkdir -p "$B"
CONF="$T/pacman.conf"

cat > "$B/pacman" <<'STUB'
#!/bin/sh
case "$1" in
    -Qq) printf '%s\n' hyprland aquamarine hyprgraphics hyprutils quickshell qt6-base qt6-svg firefox xdg-desktop-portal-hyprland ;;
    -Q)
        shift; rc=1
        for n in "$@"; do
            case "$n" in
                hyprland) echo "hyprland 0.56.2-3.1"; rc=0 ;;
                quickshell) echo "quickshell 0.3.2-1"; rc=0 ;;
                *) for h in $HAVE; do [ "$h" = "$n" ] && rc=0; done ;;
            esac
        done
        exit $rc ;;
    --dbpath)
        shift 3
        for n in "$@"; do
            case "$n" in
                hyprland) printf 'Name            : hyprland\nVersion         : 0.57.2-1.1\n\nName            : hyprland\nVersion         : 0.57.2-1\n\n' ;;
                quickshell) printf 'Name            : quickshell\nVersion         : 0.3.3-1\n\n' ;;
            esac
        done ;;
esac
STUB

cat > "$B/vercmp" <<'STUB'
#!/bin/sh
if [ "$1" = "$2" ]; then echo 0
elif [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ]; then echo -1
else echo 1; fi
STUB
cat > "$B/checkupdates" <<'STUB'
#!/bin/sh
echo "quickshell 0.3.2-1 -> 0.3.3-1 [ignored]"
echo "aquamarine 0.15.0-1.1 -> 0.16.0-1.1"
echo "firefox 130.0-1 -> 131.0-1"
echo "qt6-base 6.12.0-1 -> 6.12.1-1 [ignored]"
STUB
cat > "$B/snapper" <<'STUB'
#!/bin/sh
[ "$1" = list-configs ] && printf 'Config │ Subvolume\n───────┼──────────\nhome   │ /home\nroot   │ /\n'
STUB
chmod +x "$B"/*
mkdir -p "$T/db/sync"
export PATH="$B:/usr/bin:/bin:/usr/local/bin" APSIS_PACMAN_CONF="$CONF" APSIS_SUDO="" CHECKUPDATES_DB="$T/db"

passed=0; failed=0
ok()    { passed=$((passed + 1)); }
bad()   { failed=$((failed + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }
ign()   { grep '^IgnorePkg' "$1" | head -1; }

write_conf() { printf '%s\n' "# a comment about IgnorePkg" "#IgnorePkg =" "[options]" "$@" "" "[core]" "Include = /etc/pacman.d/mirrorlist" > "$CONF"; }

write_conf "IgnorePkg = hyprland quickshell"
check "add hypr keeps the existing pins and adds the rest, once" \
    "$(sh "$S" edit "$CONF" add hypr | grep '^IgnorePkg')" \
    "IgnorePkg = hyprland quickshell aquamarine hyprgraphics hyprutils xdg-desktop-portal-hyprland"
check "add shell adds only the shell group" \
    "$(sh "$S" edit "$CONF" add shell | grep '^IgnorePkg')" \
    "IgnorePkg = hyprland quickshell qt6-base"
check "a package that isn't in a group is never pinned" \
    "$(sh "$S" edit "$CONF" add hypr | grep -c firefox)" "0"

write_conf "IgnorePkg = hyprland quickshell aquamarine hyprgraphics"
check "remove hypr leaves the shell pin" "$(sh "$S" edit "$CONF" remove hypr | grep '^IgnorePkg')" "IgnorePkg = quickshell"
write_conf "IgnorePkg = hyprland aquamarine"
check "emptying IgnorePkg removes the line" "$(sh "$S" edit "$CONF" remove hypr | grep -c '^IgnorePkg')" "0"
write_conf "IgnorePkg = firefox hyprland"
check "pins that aren't ours are kept" "$(sh "$S" edit "$CONF" remove hypr | grep '^IgnorePkg')" "IgnorePkg = firefox"

write_conf
out=$(sh "$S" edit "$CONF" add shell)
check "a new IgnorePkg line sits under [options]" "$(printf '%s\n' "$out" | grep -A1 '^\[options\]' | tail -1)" "IgnorePkg = quickshell qt6-base"
check "comments are untouched" "$(printf '%s\n' "$out" | grep -c '^# a comment about IgnorePkg')" "1"
check "the commented IgnorePkg stays commented" "$(printf '%s\n' "$out" | grep -c '^#IgnorePkg =')" "1"
check "removing from a conf with no pins changes nothing" "$(sh "$S" edit "$CONF" remove hypr | cmp -s - "$CONF" && echo same)" "same"

write_conf "IgnorePkg = hyprland quickshell"
tab=$(printf '\t')
list=$(sh "$S" list)
check "a pinned package checkupdates leaves out is still found" "$(printf '%s\n' "$list" | grep -c "${tab}hyprland${tab}")" "1"
check "a pinned package checkupdates lists is not listed twice" "$(printf '%s\n' "$list" | grep -c "${tab}quickshell${tab}")" "1"
check "hyprland: held, in the hypr group" "$(printf '%s\n' "$list" | grep "${tab}hyprland${tab}")" "repo${tab}hyprland${tab}0.56.2-3.1${tab}0.57.2-1.1${tab}held${tab}hypr"
check "aquamarine: not held, in the hypr group" "$(printf '%s\n' "$list" | grep "${tab}aquamarine${tab}" | cut -f5,6)" "-${tab}hypr"
check "firefox: no group" "$(printf '%s\n' "$list" | grep "${tab}firefox${tab}" | cut -f5,6)" "-${tab}-"
check "qt6-base: in the shell group, the [ignored] mark doesn't leak in" "$(printf '%s\n' "$list" | grep "${tab}qt6-base${tab}" | cut -f4,6)" "6.12.1-1${tab}shell"

mkdir -p "$T/tmp/checkup-db-$(id -u)/sync"
check "the default database folder is TMPDIR/checkup-db-<uid>" \
    "$(env -u CHECKUPDATES_DB TMPDIR="$T/tmp" sh "$S" list | grep -c "${tab}hyprland${tab}")" "1"
check "no database folder, no pinned lookup, and no error" \
    "$(env -u CHECKUPDATES_DB TMPDIR="$T/nothing" sh "$S" list 2>&1 | grep -c "${tab}hyprland${tab}")" "0"

check "status with everything" "$(HAVE='snap-pac limine-snapper-sync' sh "$S" status | tr '\n' ' ')" "snapper yes snappac yes bootable yes "
check "status with only snapper" "$(HAVE='' sh "$S" status | tr '\n' ' ')" "snapper yes snappac no bootable no "

if command -v script >/dev/null 2>&1; then
    write_conf "IgnorePkg = hyprland quickshell"
    cp "$CONF" "$T/before"
    printf 'n\n\n' | script -qec "sh $S hold hypr" /dev/null >/dev/null 2>&1
    check "declining leaves the conf alone" "$(cmp -s "$CONF" "$T/before" && echo same)" "same"
    printf 'y\n\n' | script -qec "sh $S hold hypr" /dev/null >/dev/null 2>&1
    check "accepting writes the pins" "$(ign "$CONF")" "IgnorePkg = hyprland quickshell aquamarine hyprgraphics hyprutils xdg-desktop-portal-hyprland"
    check "and keeps the old file" "$(cmp -s "$CONF.apsis-backup" "$T/before" && echo same)" "same"
    printf 'y\n\n' | script -qec "sh $S release hypr" /dev/null >/dev/null 2>&1
    check "releasing takes the group out again" "$(ign "$CONF")" "IgnorePkg = quickshell"
else
    echo "(skipping the terminal tests: needs script from util-linux)"
fi

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
