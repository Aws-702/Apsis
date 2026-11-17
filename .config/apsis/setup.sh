#!/bin/sh
# Apsis setup for Arch based systems, run after checking the dotfiles out into $HOME.
#   sh setup.sh                 full setup
#   sh setup.sh --dry-run       print everything it would do, change nothing
#   sh setup.sh --check         read only: what is installed and what is missing
#   sh setup.sh --update        what an update needs: packages, the SDDM theme and its helper
#   sh setup.sh --yes           don't let pacman ask before installing
#   sh setup.sh --hypr merge    keep your own hyprland.lua; Apsis only adds its session part
#   sh setup.sh --hypr merge --with-keys   and its keys as well
#   sh setup.sh --hypr skip     don't touch the Hyprland config at all
# Edit: PKGS for the package list.

set -e

DRY=0; CHECK=0; UPDATE=0; YES=0; HYPR=full; WITH_KEYS=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --check) CHECK=1 ;;
        --update) UPDATE=1 ;;
        --yes|-y) YES=1 ;;
        --hypr) shift; HYPR="${1:-}" ;;
        --hypr=*) HYPR="${1#--hypr=}" ;;
        --with-keys) WITH_KEYS=1 ;;
        -h|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1 (try --help)" >&2; exit 2 ;;
    esac
    shift
done
case "$HYPR" in full|merge|skip) ;; *) echo "--hypr takes full, merge or skip" >&2; exit 2 ;; esac

HERE=$(cd "$(dirname "$0")" && pwd)
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/apsis"
GIT_DIR="${APSIS_GIT_DIR:-$HOME/.apsis}"

say()  { printf '>> %s\n' "$*"; }
note() { printf '   %s\n' "$*"; }

run() {
    if [ "$DRY" -eq 1 ]; then printf '   [dry run] %s\n' "$*"; else "$@"; fi
}

if ! command -v pacman >/dev/null 2>&1; then
    echo "!! setup.sh installs packages with pacman (Arch and Arch-based distros)."
    echo "   On another distro, install the packages listed in the README's"
    echo "   'Other distros' section yourself; the rest of Apsis works the same."
    exit 1
fi

PKGS="hyprland quickshell uwsm xdg-desktop-portal-hyprland polkit-gnome sddm
    kitty fish wofi
    thunar thunar-volman gvfs tumbler ffmpegthumbnailer thunar-archive-plugin
    awww matugen hyprlock hypridle hyprpicker hyprsunset
    pamixer brightnessctl playerctl networkmanager bluez bluez-utils python-gobject
    grim slurp gnome-keyring
    wl-clipboard cliphist cava jq curl ffmpeg pacman-contrib
    tmux gpu-screen-recorder
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts-emoji papirus-icon-theme"

OPT_PKGS="easyeffects lsp-plugins-lv2 fprintd qt5ct qt6ct"

pacman_flags="-S --needed"
[ "$YES" -eq 1 ] && pacman_flags="$pacman_flags --noconfirm"

if [ "$CHECK" -eq 1 ]; then
    missing=0
    say "Apsis setup check (read only)"
    echo
    say "Packages"
    for p in $PKGS; do
        if pacman -Qq "$p" >/dev/null 2>&1; then :; else note "missing: $p"; missing=$((missing + 1)); fi
    done
    [ "$missing" -eq 0 ] && note "all $(echo "$PKGS" | wc -w | tr -d ' ') required packages are installed"
    for p in $OPT_PKGS; do
        pacman -Qq "$p" >/dev/null 2>&1 || note "optional, not installed: $p"
    done
    for c in grimblast mpvpaper; do
        command -v "$c" >/dev/null 2>&1 || note "not installed: $c ($([ "$c" = grimblast ] && echo 'screenshots, needed' || echo 'video wallpapers, optional'))"
    done
    [ -x /usr/local/bin/apsis-sddm-apply ] || { note "missing: the SDDM palette helper (setup.sh installs it)"; missing=$((missing + 1)); }
    [ -f /etc/sudoers.d/apsis-sddm ] || { note "missing: /etc/sudoers.d/apsis-sddm"; missing=$((missing + 1)); }
    [ -d /usr/share/sddm/themes/apsis ] || { note "missing: the Apsis SDDM theme"; missing=$((missing + 1)); }
    for s in sddm NetworkManager bluetooth; do
        systemctl is-enabled "$s.service" >/dev/null 2>&1 || { note "service not enabled: $s"; missing=$((missing + 1)); }
    done
    [ -f "$STATE/monitors.lua" ] || note "no saved monitor layout yet (monitors-init.sh writes one inside Hyprland)"
    echo
    if [ "$missing" -eq 0 ]; then say "nothing required is missing"; else say "$missing thing(s) missing: run  sh $0"; fi
    exit "$missing"
fi

say "Apsis setup starting"
[ "$DRY" -eq 1 ] && note "dry run: nothing below is actually done"

say "Installing packages"
# shellcheck disable=SC2086  # the word splitting is the point
run sudo pacman $pacman_flags $PKGS || \
    echo "!! Some packages failed to install; check the pacman output above."

helper=""
command -v paru >/dev/null 2>&1 && helper=paru
command -v yay  >/dev/null 2>&1 && helper=yay

get() {
    command -v "$1" >/dev/null 2>&1 && return 0
    if pacman -Si "$2" >/dev/null 2>&1; then
        say "Installing $2 from your distro's repos ($4)"
        # shellcheck disable=SC2086
        run sudo pacman $pacman_flags "$2" && return 0
    fi
    if [ -n "$helper" ]; then
        say "$2 isn't in your repos; building $3 from the AUR with $helper ($4)"
        run "$helper" -S --needed "$3" && return 0
    fi
    if [ "$5" = required ]; then
        echo "!! $1 is missing: $4 need it. It's in the AUR as $3."
    else
        echo "   (optional) $3 from the AUR adds $4."
    fi
}
get grimblast grimblast grimblast-git "screenshots" required
get mpvpaper mpvpaper mpvpaper "video wallpapers" optional

for p in $OPT_PKGS; do
    pacman -Qq "$p" >/dev/null 2>&1 || note "optional: sudo pacman -S $p"
done

run mkdir -p "$HOME/Apsis/wallpapers" "$HOME/Apsis/pfps"

if [ -x "$HOME/.config/apsis/sddm/install.sh" ]; then
    say "Deploying SDDM theme"
    run sh "$HOME/.config/apsis/sddm/install.sh"
fi

say "Installing SDDM palette helper"
if [ "$DRY" -eq 1 ]; then
    note "[dry run] would write /usr/local/bin/apsis-sddm-apply and /etc/sudoers.d/apsis-sddm"
else
sudo tee /usr/local/bin/apsis-sddm-apply >/dev/null <<'APPLY'
#!/bin/sh
# Writes palette/colors into the Apsis SDDM theme.conf. Nothing else.
set -e
THEME="/usr/share/sddm/themes/apsis/theme.conf"
[ -f "$THEME" ] || exit 1
pal="$1"; accent="$2"; bg="$3"
is_hex() { printf '%s' "$1" | grep -Eq '^#?[0-9A-Fa-f]{6}$'; }
case "$pal" in
    cherry|navy) base="$pal"; aover=""; bover="" ;;
    auto)
        base="cherry"
        is_hex "$accent" && aover="#${accent#\#}" || aover=""
        is_hex "$bg"     && bover="#${bg#\#}"     || bover=""
        ;;
    *) exit 2 ;;
esac
sed -i -E "s|^palette=.*|palette=$base|"                "$THEME"
sed -i -E "s|^accentOverride=.*|accentOverride=$aover|" "$THEME"
sed -i -E "s|^bgOverride=.*|bgOverride=$bover|"         "$THEME"
APPLY
sudo chown root:root /usr/local/bin/apsis-sddm-apply
sudo chmod 755 /usr/local/bin/apsis-sddm-apply
echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/apsis-sddm-apply" | sudo tee /etc/sudoers.d/apsis-sddm >/dev/null
sudo chmod 440 /etc/sudoers.d/apsis-sddm
sudo visudo -cf /etc/sudoers.d/apsis-sddm
fi

if [ "$UPDATE" -eq 0 ]; then
    say "Enabling services"
    run sudo systemctl enable sddm.service NetworkManager.service bluetooth.service

    if [ "$DRY" -eq 1 ]; then
        note "[dry run] would enable the NVIDIA suspend/resume services if present"
    else
        sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service 2>/dev/null || true
    fi
fi

say "Seeding initial state"
run mkdir -p "$HOME/.cache/quickshell" "$STATE" "$HOME/.cache/apsis"
if [ "$DRY" -eq 0 ]; then
    [ -f "$HOME/.cache/quickshell/apsis-palette" ] || printf cherry > "$HOME/.cache/quickshell/apsis-palette"
    [ -f "$HOME/.cache/quickshell/apsis-mode" ]    || printf dark   > "$HOME/.cache/quickshell/apsis-mode"
    sh "$HOME/.config/hypr/scripts/apsis-hyprlock.sh" 2>/dev/null || true
fi

if [ "$UPDATE" -eq 0 ] && [ -x "$HERE/monitors-init.sh" ]; then
    if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
        if [ "$DRY" -eq 1 ]; then
            note "[dry run] would write a monitor layout for the connected screens:"
            sh "$HERE/monitors-init.sh" --print 2>/dev/null | sed 's/^/        /'
        else
            sh "$HERE/monitors-init.sh" || true
        fi
    else
        note "not inside Hyprland, so no monitor layout was written."
        note "Run  sh ~/.config/apsis/monitors-init.sh  once you are logged in."
    fi
fi

if [ "$HYPR" = merge ]; then
    say "Merge mode: keeping your own hyprland.lua"
    cfg="$HOME/.config/hypr/hyprland.lua"
    mine="$HOME/.apsis-backup/.config/hypr/hyprland.lua"
    if grep -q '>>> apsis' "$cfg" 2>/dev/null; then
        note "your config already loads Apsis"
    else
        if grep -q 'Apsis -- Hyprland config' "$cfg" 2>/dev/null; then

            if [ ! -f "$mine" ]; then
                echo "!! No hyprland.lua of yours was found in ~/.apsis-backup/.config/hypr/."
                echo "   Merge mode needs your own Lua config (Hyprland 0.55 or newer). If you only have"
                echo "   a hyprland.conf, convert it first, or use the full Apsis config."
                exit 1
            fi
            run cp -p "$mine" "$cfg"
        fi
        if [ "$DRY" -eq 1 ]; then
            note "[dry run] would add the Apsis lines to $cfg"
        else
            {
                printf '\n-- >>> apsis (added by setup.sh --hypr merge; delete these lines to stop loading Apsis)\n'
                printf 'do\n    local home = os.getenv("HOME")\n'
                printf '    pcall(dofile, home .. "/.config/hypr/apsis-session.lua")\n'
                [ "$WITH_KEYS" -eq 1 ] && printf '    pcall(dofile, home .. "/.config/hypr/apsis-keys.lua")\n'
                printf 'end\n-- <<< apsis\n'
            } >> "$cfg"
        fi
    fi
    if [ "$DRY" -eq 0 ] && [ -d "$GIT_DIR" ]; then

        git --git-dir="$GIT_DIR" --work-tree="$HOME" update-index --skip-worktree .config/hypr/hyprland.lua 2>/dev/null || true
        mkdir -p "$STATE"; : > "$STATE/hypr-merge"
    fi
    note "Apsis's autostart (the shell, wallpaper, clipboard history) loads from your config."
    [ "$WITH_KEYS" -eq 1 ] || note "Its keys did not load. Add --with-keys, or dofile apsis-keys.lua yourself."
elif [ "$HYPR" = skip ]; then
    note "left the Hyprland config alone"
fi

echo ""
if [ "$DRY" -eq 1 ]; then
    say "Dry run finished. Nothing was changed."
    exit 0
fi
say "Apsis setup complete."
if [ "$UPDATE" -eq 0 ]; then
    echo "   Manual follow-ups (machine specific, not automated):"
    echo "     - Pin updates (optional): sh ~/.config/hypr/scripts/apsis-updates.sh hold hypr, and hold shell. Each pins Hyprland or quickshell together with the libraries it needs; the Updates screen then asks before updating them"
    echo "     - NVIDIA laptops: options nvidia NVreg_PreserveVideoMemoryAllocations=1 in /etc/modprobe.d, then rebuild initramfs"
    echo "     - (optional) The phone's equalizer works through EasyEffects: sudo pacman -S easyeffects lsp-plugins-lv2"
    echo "     - (optional) Fingerprint unlock on the lockscreen: sudo pacman -S fprintd, then fprintd-enroll"
    echo "   Check everything any time with: apsis doctor"
    echo "   Keep it current with:           apsis update"
    echo "   Then reboot and log in with the 'Hyprland (uwsm-managed)' session."
fi
