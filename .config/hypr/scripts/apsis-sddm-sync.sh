#!/bin/sh
# Pushes the current palette to the SDDM login screen through its root helper.
# Usage: apsis-sddm-sync.sh cherry|navy|auto

command -v sudo >/dev/null 2>&1 || exit 0
new="$1"
if [ "$new" = "auto" ]; then
    j="$HOME/.cache/quickshell/apsis-auto.json"
    get() { grep "\"$1\":" "$j" 2>/dev/null | head -1 | sed -E 's/.*"#?([0-9A-Fa-f]{6,8})".*/\1/'; }
    acc=$(get accent);       bgm=$(get bgMain)
    bgc=$(get bgCard);       bgi=$(get bgItem)
    tp=$(get textPrimary);   ts=$(get textSecondary)
    ol=$(get outline)
    sudo -n /usr/local/bin/apsis-sddm-apply auto "$acc" "$bgm" "$bgc" "$bgi" "$tp" "$ts" "$ol" >/dev/null 2>&1 || true
else
    sudo -n /usr/local/bin/apsis-sddm-apply "$new" >/dev/null 2>&1 || true
fi
