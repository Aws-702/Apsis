#!/bin/sh
# apsis doctor: checks what Apsis needs and prints the fix for each problem; never changes anything.
# Usage: apsis-doctor.sh [--tsv]. Edit: add a check with need, opt or say.

tsv=0; [ "$1" = "--tsv" ] && tsv=1
fails=0; warns=0

say() {
    case "$1" in fail) fails=$((fails + 1)) ;; warn) warns=$((warns + 1)) ;; esac
    if [ $tsv -eq 1 ]; then
        printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
        return
    fi
    case "$1" in
        ok)   tag="  ok  " ;;
        warn) tag=" warn " ;;
        fail) tag=" FAIL " ;;
        *)    tag="  ..  " ;;
    esac
    printf '%s %s%s\n' "$tag" "$2" "${3:+  ($3)}"
    [ -n "$4" ] && printf '        fix: %s\n' "$4"
}
has() { command -v "$1" >/dev/null 2>&1; }
pkgver() { pacman -Q "$1" 2>/dev/null | awk '{ print $2 }'; }
section() { [ $tsv -eq 1 ] || printf '\n%s\n' "$1"; }

[ $tsv -eq 1 ] || printf 'Apsis doctor\n'

section "Programs"

need() {
    if has "$1"; then say ok "$1"
    else say "$4" "$1 is missing" "$3" "sudo pacman -S $2"; fi
}
need Hyprland hyprland "the compositor" fail
need qs quickshell "the shell" fail
need uwsm uwsm "the session" fail
need hyprctl hyprland "talking to Hyprland" fail
need awww awww "image wallpapers" fail
need matugen matugen "the Auto palette" warn
need hyprlock hyprlock "the hyprlock lockscreen" warn
need hyprsunset hyprsunset "night light" warn
need pamixer pamixer "volume keys" fail
need brightnessctl brightnessctl "brightness keys" fail
need playerctl playerctl "media keys and the media card" warn
need nmcli networkmanager "Wi-Fi" fail
need wl-paste wl-clipboard "the clipboard" fail
need cliphist cliphist "clipboard history" warn
need grim grim "screenshots" warn
need slurp slurp "picking a region" warn
need jq jq "scripts reading JSON" fail
need curl curl "weather and lyrics" warn
need notify-send libnotify "messages from scripts" warn
need checkupdates pacman-contrib "the updates count" warn
need cava cava "the visualizer" warn
need hypridle hypridle "locking and turning the screen off when idle" warn

from_repo() {
    if has pacman && pacman -Si "$1" >/dev/null 2>&1; then echo "sudo pacman -S $1"
    else echo "paru -S $2 (AUR; read its PKGBUILD first)"; fi
}
if has grimblast; then say ok grimblast
else say warn "grimblast is missing" "screenshots" "$(from_repo grimblast grimblast-git)"; fi

section "Optional"
opt() {
    if has "$1"; then say ok "$1"
    else say info "$1 not installed" "$3" "$2"; fi
}
opt mpvpaper "$(from_repo mpvpaper mpvpaper)" "video wallpapers"
opt gpu-screen-recorder "sudo pacman -S gpu-screen-recorder" "screen recording"
opt tmux "sudo pacman -S tmux" "Training mode's session"
opt easyeffects "sudo pacman -S easyeffects" "the equalizer"

if has easyeffects; then
    lsp=0
    for d in $(printf '%s' "${LV2_PATH:-}" | tr ':' ' ') "$HOME/.lv2" /usr/lib/lv2 /usr/lib64/lv2 /usr/local/lib/lv2; do
        [ -d "$d/lsp-plugins.lv2" ] && lsp=1
    done
    if [ $lsp -eq 1 ]; then say ok "LSP plugins (the equalizer)"
    else say warn "LSP plugins are missing" "EasyEffects' equalizer needs them" "sudo pacman -S lsp-plugins-lv2"; fi
fi

section "Session"
if has hyprctl && hyprctl version >/dev/null 2>&1; then
    tag=$(hyprctl version -j 2>/dev/null | jq -r '.tag // .version // empty' 2>/dev/null)
    say ok "Hyprland is running" "${tag:-version unknown}"
    errs=$(hyprctl configerrors 2>/dev/null | grep -viE '^[[:space:]]*$|no errors' | head -3)
    if [ -n "$errs" ]; then
        say fail "the Hyprland config has errors" "$(printf '%s' "$errs" | head -1 | cut -c1-120)" "hyprctl configerrors (then fix ~/.config/hypr/hyprland.lua)"
    else
        say ok "the Hyprland config loads cleanly"
    fi
else
    say info "Hyprland isn't running here" "session checks skipped"
fi

elog="$HOME/.cache/apsis/hypr-errors.log"
if [ -s "$elog" ]; then
    say fail "a part of the Hyprland config has an error" "$(tail -n 1 "$elog" | cut -c1-110)" "fix it, then reload Hyprland; the full log is $elog"
fi

if has qs; then
    n=$(qs list 2>/dev/null | grep -c '^Instance')
    case "$n" in
        0) say fail "the shell isn't running" "" "qs -n -d" ;;
        1) say ok "the shell is running once" ;;
        *) say fail "the shell is running $n times" "two phones, two docks, IPC goes astray" "qs kill; sleep 1; qs -n -d" ;;
    esac
fi

for d in dunst mako swaync; do
    if pgrep -x "$d" >/dev/null 2>&1; then
        say warn "$d is running" "it takes notifications from the shell" "pkill -x $d (and drop it from your autostart)"
    fi
done

pk=$(cat "$HOME/.cache/quickshell/apsis-polkit" 2>/dev/null)
if [ "$pk" = "apsis" ] && qs list 2>/dev/null | grep -q '^Instance'; then
    say ok "polkit agent" "the shell's"
elif pgrep -f polkit-gnome-authentication-agent >/dev/null 2>&1 || pgrep -f polkit-kde-authentication-agent >/dev/null 2>&1 || pgrep -x hyprpolkitagent >/dev/null 2>&1; then
    say ok "polkit agent" "a separate one"
else
    say fail "no polkit agent" "apps that ask for your password can't" "restart the shell (qs kill; qs -n -d), or sudo pacman -S polkit-gnome"
fi

upd="$HOME/.config/hypr/scripts/apsis-updates.sh"
if has pacman && [ -f "$upd" ]; then
    pins=$(sh "$upd" pins 2>/dev/null)
    while read -r g state rest; do
        [ -n "$g" ] || continue
        case "$state" in
            mixed) say warn "$g packages are only partly pinned" "pacman -Syu would refuse to update:$(printf ' %s' $rest | cut -c1-90)" "sh $upd hold $g   (pins all of them; or: sh $upd release $g)" ;;
        esac
    done <<DOCTOREOF
$pins
DOCTOREOF

    if findmnt -no FSTYPE / 2>/dev/null | grep -q btrfs; then
        st=$(sh "$upd" status 2>/dev/null)
        case "$st" in
            *"snappac yes"*) say ok "snapshots around every update" "snap-pac" ;;
            *"snapper yes"*) say info "snapper doesn't snapshot updates by itself" "the Updates screen can take one first" "sudo pacman -S snap-pac" ;;
            *) say info "no snapshots" "your root is btrfs; snapper would make a bad update undoable" "sudo pacman -S snapper snap-pac" ;;
        esac
    fi
fi

if has bluetoothctl; then
    ba=$(cat "$HOME/.cache/quickshell/apsis-btagent" 2>/dev/null)
    if ! has python3 || ! python3 -c 'import gi; gi.require_version("Gio", "2.0"); from gi.repository import Gio' >/dev/null 2>&1; then
        say warn "no Bluetooth pairing agent" "python-gobject is missing, so new devices can't pair" "sudo pacman -S python-gobject, then restart the shell (qs kill; qs -n -d)"
    elif [ "$ba" = "apsis" ] && qs list 2>/dev/null | grep -q '^Instance'; then
        say ok "Bluetooth pairing agent" "the shell's"
    elif pgrep -x blueman-applet >/dev/null 2>&1 || pgrep -x bt-agent >/dev/null 2>&1; then
        say ok "Bluetooth pairing agent" "a separate one"
    else
        say warn "no Bluetooth pairing agent" "pairing a new device can fail" "restart the shell (qs kill; qs -n -d); is bluetooth.service running?"
    fi
fi

section "Versions"
if has pacman; then
    qt=$(pkgver qt6-base); qsv=$(pkgver quickshell); hl=$(pkgver hyprland)
    [ -n "$qt" ]  && say info "qt6-base $qt"
    [ -n "$qsv" ] && say info "quickshell $qsv"
    [ -n "$hl" ]  && say info "hyprland $hl"

    if [ -n "$qt" ] && [ -n "$qsv" ]; then
        qtd=$(stat -c %Y /var/lib/pacman/local/qt6-base-"$qt"/desc 2>/dev/null)
        qsd=$(stat -c %Y /var/lib/pacman/local/quickshell-"$qsv"/desc 2>/dev/null)
        qtmm=$(printf '%s' "$qt" | cut -d. -f1-2)
        built=$(pacman -Qi quickshell 2>/dev/null | sed -n 's/^Build Date *: *//p')
        if [ -n "$qtd" ] && [ -n "$qsd" ] && [ "$qtd" -gt "$qsd" ] && [ $((qtd - qsd)) -gt 86400 ]; then
            say warn "Qt ($qtmm) was updated after quickshell" "quickshell built ${built:-earlier}; if the shell crashes, it needs a rebuild" "sudo pacman -Syu quickshell (or rebuild it from the AUR)"
        fi
    fi
    if grep -Eq '^[[:space:]]*IgnorePkg[[:space:]]*=.*(hyprland|quickshell)' /etc/pacman.conf 2>/dev/null; then
        say ok "Hyprland and quickshell are pinned"
    else
        say info "Hyprland and quickshell aren't pinned" "an update can change the Lua config under you" "sh ~/.config/hypr/scripts/apsis-updates.sh hold hypr, then hold shell (each is pinned with the libraries it needs)"
    fi
fi

if has nvidia-smi; then
    section "NVIDIA"
    gpu=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$gpu" ]; then say ok "GPU" "$gpu"
    else say fail "nvidia-smi can't reach the GPU" "" "reboot; if it stays, reinstall the NVIDIA driver"; fi
    pres=$(grep -s PreserveVideoMemoryAllocations /proc/driver/nvidia/params | awk '{ print $2 }')
    if [ "$pres" = "1" ]; then say ok "video memory kept over suspend"
    elif [ -n "$pres" ]; then say warn "video memory isn't kept over suspend" "apps can come back glitched after sleep" "options nvidia NVreg_PreserveVideoMemoryAllocations=1 in /etc/modprobe.d/nvidia.conf, then rebuild the initramfs"; fi
    if has systemctl && ! systemctl is-enabled nvidia-suspend.service >/dev/null 2>&1; then
        say warn "nvidia-suspend isn't enabled" "" "sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume"
    fi
fi

section "Files"
state="${XDG_STATE_HOME:-$HOME/.local/state}/apsis"
if has jq && [ -d "$state" ]; then
    bad=""
    for f in "$state"/*.json; do
        [ -f "$f" ] || continue
        jq empty "$f" >/dev/null 2>&1 || bad="$bad $(basename "$f")"
    done
    if [ -n "$bad" ]; then say fail "unreadable settings:$bad" "the shell falls back to defaults for these" "fix or delete them in $state"
    else say ok "settings files read cleanly"; fi
fi
walls=$(find "$HOME/Apsis/wallpapers" -maxdepth 1 -type f ! -name '.*' 2>/dev/null | grep -ciE '\.(jpg|jpeg|png|webp|gif|mp4|webm|mkv|mov)$')
if [ "${walls:-0}" -gt 0 ]; then say ok "wallpapers" "$walls in ~/Apsis/wallpapers"
else say info "no wallpapers yet" "" "put images or videos in ~/Apsis/wallpapers"; fi
if has fc-list && ! fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    say warn "JetBrains Mono Nerd font is missing" "the bar and terminal fall back" "sudo pacman -S ttf-jetbrains-mono-nerd"
fi
if [ ! -d /usr/share/icons/Papirus-Dark ] && [ ! -d "$HOME/.local/share/icons/Papirus-Dark" ]; then
    say warn "Papirus icons are missing" "apps show placeholder icons" "sudo pacman -S papirus-icon-theme"
fi

if [ $tsv -eq 0 ]; then
    printf '\n'
    if [ $fails -eq 0 ] && [ $warns -eq 0 ]; then echo "All good."
    else echo "$fails to fix, $warns worth a look."; fi
fi
exit $fails
