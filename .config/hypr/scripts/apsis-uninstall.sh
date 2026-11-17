#!/usr/bin/env bash
# Deletes an app from the Apps screen in a terminal that shows what goes (pacman, flatpak, snap).
# Usage: apsis-uninstall.sh DESKTOP_ID. Edit: the protected package list here.

id="${1%.desktop}"
[ -n "$id" ] || { echo "usage: $0 <desktop-id>"; exit 2; }

if [ ! -t 0 ] || [ ! -t 1 ]; then
    title="Apsis: delete $id"
    for t in "$TERMINAL" kitty alacritty foot wezterm konsole xterm; do
        { [ -n "$t" ] && command -v "$t" >/dev/null 2>&1; } || continue
        case "$(basename "$t")" in
            kitty|foot) exec "$t" --title "$title" "$0" "$@" ;;
            alacritty)  exec "$t" --title "$title" -e "$0" "$@" ;;
            wezterm)    exec "$t" start -- "$0" "$@" ;;
            *)          exec "$t" -e "$0" "$@" ;;
        esac
    done
    notify-send "Apsis" "No terminal found to delete $id" 2>/dev/null
    exit 1
fi

finish() { echo; read -rp "Press Enter to close. " _; exit "${1:-0}"; }
ask() { local a; read -rp "$1 [y/N] " a; [[ "$a" == [yY]* ]]; }

file=""
IFS=: read -ra dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for d in "${dirs[@]}"; do
    [ -n "$d" ] || continue
    for f in "$d/applications/$id.desktop" "$d/applications/${id//-//}.desktop"; do
        [ -e "$f" ] && { file="$f"; break 2; }
    done
done
if [ -z "$file" ]; then
    echo "Can't find the launcher for \"$id\"."
    finish 1
fi
real="$(readlink -f "$file")"
name="$(grep -m1 '^Name=' "$file" | cut -d= -f2-)"
name="${name:-$id}"

echo "Delete $name"
echo "  launcher: $file"
echo

if [[ "$file" == */flatpak/exports/* || "$real" == */flatpak/* ]]; then
    command -v flatpak >/dev/null || { echo "This is a flatpak, but flatpak isn't installed."; finish 1; }
    flatpak uninstall "$id"
    finish $?
fi

if [[ "$file" == /var/lib/snapd/* ]]; then
    snap="${id%%_*}"
    ask "Remove the snap \"$snap\"?" && sudo snap remove "$snap"
    finish $?
fi

pkg="$(pacman -Qqo "$real" 2>/dev/null || pacman -Qqo "$file" 2>/dev/null)"
if [ -n "$pkg" ]; then
    case "$pkg" in
        base|base-devel|linux|linux-*|glibc|systemd|systemd-*|pacman|sudo|bash|\
        hyprland|quickshell*|uwsm|sddm|networkmanager|bluez|pipewire*|wireplumber|\
        mesa|nvidia*|polkit|dbus|papirus-icon-theme)
            echo "\"$pkg\" is part of what this desktop runs on, so Apsis won't remove it."
            echo "Hide the app instead (right click, Hide)."
            finish 1 ;;
    esac

    echo "  package:  $(pacman -Q "$pkg")"
    req="$(LC_ALL=C pacman -Qi "$pkg" | sed -n 's/^Required By *: //p' | tr -s ' ' | sed 's/ /, /g')"
    if [ -n "$req" ] && [ "$req" != "None" ]; then
        echo
        echo "Other packages need $pkg: $req"
        echo "Removing it would break those, so pacman won't. Hide the app instead"
        echo "(right click, Hide)."
        finish 1
    fi

    others="$(pacman -Qlq "$pkg" | grep -E '/applications/.+\.desktop$' | grep -vF "$real" | while read -r o; do
        grep -m1 '^Name=' "$o" | cut -d= -f2-; done | paste -sd, - | sed 's/,/, /g')"
    [ -n "$others" ] && echo "  also removes: $others"
    echo
    echo "pacman shows everything it will remove and asks before it does."
    echo
    sudo pacman -Rs "$pkg"
    finish $?
fi

if [[ "$real" == "$HOME"/* ]]; then
    echo "No package owns this launcher; it's a file in your home folder."
    echo "Deleting it removes the app from the list. What it starts (an AppImage,"
    echo "a script) stays where it is."
    echo
    ask "Delete $file?" && rm -f -- "$file" && echo "Deleted."
    finish 0
fi

echo "No package owns this launcher, so Apsis won't guess how to remove it."
echo "Hide the app instead (right click, Hide)."
finish 1
