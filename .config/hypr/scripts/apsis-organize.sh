#!/bin/sh
# One time tidy: makes ~/Apsis/wallpapers and ~/Apsis/pfps and moves old files there.
# Edit: the folder names here.

set -e

mkdir -p "$HOME/Apsis/wallpapers" "$HOME/Apsis/pfps"

old="$HOME/.config/apsis/wallpapers"
if [ -d "$old" ]; then
    find "$old" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -exec mv -n {} "$HOME/Apsis/wallpapers/" \; 2>/dev/null || true
    rmdir "$old" 2>/dev/null || true
fi

if [ -f "$HOME/.config/apsis/face.png" ] && [ ! -f "$HOME/Apsis/pfps/current.png" ]; then
    cp "$HOME/.config/apsis/face.png" "$HOME/Apsis/pfps/current.png"
fi

echo "Done."
echo "  Wallpapers: ~/Apsis/wallpapers"
echo "  Profile pictures: ~/Apsis/pfps"
