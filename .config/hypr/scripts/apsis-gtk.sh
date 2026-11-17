#!/bin/sh
# GTK: stock widgets, plus a small accent coloured Places icon set (folders, sidebar).
# Edit: the icon SVGs written here; ICON for where they go.

set -u

cache="$HOME/.cache/quickshell"
pal=$(cat "$cache/apsis-palette" 2>/dev/null || echo cherry)
json="$cache/apsis-auto.json"
getj() { grep "\"$1\":" "$json" 2>/dev/null | head -1 | sed -E 's/.*"(#?[0-9A-Fa-f]{6})".*/\1/'; }

case "$pal" in
  navy) ACC='#3AD6E0' ;;
  auto) ACC=$(getj accent); [ -n "$ACC" ] || ACC='#EC4C78' ;;
  *)    ACC='#EC4C78' ;;
esac

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
rm -f "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"

write_ini() {
cat > "$1" <<INI
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Apsis
gtk-font-name=JetBrainsMono Nerd Font 10
INI
}
write_ini "$HOME/.config/gtk-3.0/settings.ini"
write_ini "$HOME/.config/gtk-4.0/settings.ini"

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme 'Apsis' 2>/dev/null || true
fi

ICON="$HOME/.local/share/icons/Apsis"
P="$ICON/places/scalable"

rm -rf "$ICON/mimetypes"
mkdir -p "$P"

cat > "$ICON/index.theme" <<IDX
[Icon Theme]
Name=Apsis
Comment=Apsis palette place icons
Inherits=Papirus-Dark,Adwaita,hicolor
Directories=places/scalable

[places/scalable]
Context=Places
Size=48
MinSize=16
MaxSize=512
Type=Scalable
IDX

svg() {
  name="$1"; shift
  cat > "$P/$name.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="$ACC" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
$*
</svg>
SVG
}

svg folder            '<path d="M4 7a2 2 0 0 1 2-2h4l2 2h6a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/>'
svg user-home         '<path d="M4 11.5 12 4l8 7.5"/><path d="M6 10.5V20h4v-5h4v5h4v-9.5"/>'
svg document-open-recent '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>'
svg user-trash        '<path d="M4 7h16"/><path d="M9 7V4.5h6V7"/><path d="M6.5 7 7.5 20h9L18 7"/><path d="M10 10.5v6M14 10.5v6"/>'
svg computer          '<rect x="3" y="4.5" width="18" height="11.5" rx="1.5"/><path d="M8.5 20h7M12 16v4"/>'
svg drive-harddisk    '<rect x="3.5" y="5" width="17" height="14" rx="2.5"/><path d="M7 9.5h7"/><circle cx="16.5" cy="15" r="1.2" fill="'"$ACC"'" stroke="none"/>'
svg drive-removable-media '<rect x="8" y="3.5" width="8" height="13" rx="1.5"/><path d="M9.5 20h5M12 16.5V20M10 6.5h4"/>'
svg network-workgroup '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17"/><path d="M12 3.5c3 3 3 14 0 17c-3-3-3-14 0-17z"/>'
svg network-server    '<rect x="4" y="4" width="16" height="6" rx="1.5"/><rect x="4" y="14" width="16" height="6" rx="1.5"/><circle cx="7.5" cy="7" r="0.9" fill="'"$ACC"'" stroke="none"/><circle cx="7.5" cy="17" r="0.9" fill="'"$ACC"'" stroke="none"/>'
svg folder-remote     '<path d="M4 7a2 2 0 0 1 2-2h4l2 2h6a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z"/><circle cx="12" cy="13" r="2.2"/>'

for a in inode-directory folder-documents folder-download folder-downloads \
         folder-pictures folder-music folder-videos folder-publicshare \
         folder-templates folder-open folder-visiting user-desktop \
         folder-drag-accept; do
  cp "$P/folder.svg" "$P/$a.svg"
done
cp "$P/user-trash.svg" "$P/user-trash-full.svg"
cp "$P/drive-removable-media.svg" "$P/media-removable.svg"

for a in folder-home go-home gnome-fs-home redhat-home user-home-open emblem-home user-bookmarks; do
  cp "$P/user-home.svg" "$P/$a.svg"
done
cp "$P/drive-harddisk.svg" "$P/drive.svg"

command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f "$ICON" >/dev/null 2>&1 || true

command -v thunar >/dev/null 2>&1 && thunar -q >/dev/null 2>&1 || true
