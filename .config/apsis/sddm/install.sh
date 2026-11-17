#!/bin/sh
# Copies the Apsis SDDM theme to /usr/share/sddm/themes/apsis.
# Edit: SRC and DEST.

set -e
SRC="$HOME/.config/apsis/sddm/apsis"
DEST="/usr/share/sddm/themes/apsis"

if [ ! -d "$SRC" ]; then
    echo "Source not found: $SRC" >&2
    exit 1
fi

sudo rm -rf "$DEST"
sudo mkdir -p "$DEST"
sudo cp -r "$SRC/." "$DEST/"

sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=apsis\n' | sudo tee /etc/sddm.conf.d/10-apsis.conf >/dev/null

cur=$(cat "$HOME/.cache/quickshell/apsis-palette" 2>/dev/null)
if [ -n "$cur" ] && [ -x "$HOME/.config/hypr/scripts/apsis-sddm-sync.sh" ]; then
    "$HOME/.config/hypr/scripts/apsis-sddm-sync.sh" "$cur" || true
fi

echo "Apsis SDDM theme installed to $DEST and set as current (palette: ${cur:-cherry})."
echo "Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme $DEST   (or sddm-greeter --test-mode --theme $DEST)"
