#!/bin/sh
# Sets the profile picture everywhere: the shell, ~/.face and the SDDM theme.
# Usage: apsis-face.sh IMAGE

set -e

src="$1"
if [ -z "$src" ] || [ ! -f "$src" ]; then
    echo "usage: apsis-face.sh <image-file>" >&2
    exit 1
fi
case "$(printf '%s' "$src" | tr '[:upper:]' '[:lower:]')" in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp) : ;;
    *) echo "not an image: $src" >&2; exit 1 ;;
esac

mkdir -p "$HOME/.config/apsis" "$HOME/.config/apsis/sddm/apsis"

cp -f "$src" "$HOME/.config/apsis/face.png"
cp -f "$src" "$HOME/.face" 2>/dev/null || true

cp -f "$src" "$HOME/.config/apsis/sddm/apsis/face.png"
conf="$HOME/.config/apsis/sddm/apsis/theme.conf"
if grep -q '^avatar=' "$conf" 2>/dev/null; then
    sed -i 's|^avatar=.*|avatar=face.png|' "$conf"
else
    printf 'avatar=face.png\n' >> "$conf"
fi

DEST=/usr/share/sddm/themes/apsis
if [ -d "$DEST" ]; then
    sudo sh -c "
        cp -f '$HOME/.config/apsis/face.png' '$DEST/face.png' &&
        chmod 644 '$DEST/face.png' &&
        if grep -q '^avatar=' '$DEST/theme.conf' 2>/dev/null; then
            sed -i 's|^avatar=.*|avatar=face.png|' '$DEST/theme.conf'
        else
            printf 'avatar=face.png\n' >> '$DEST/theme.conf'
        fi
    "
    echo "Profile picture set (quickshell + SDDM)."
else
    echo "Profile picture set for quickshell. SDDM theme not found at $DEST; run the SDDM install.sh first."
fi
