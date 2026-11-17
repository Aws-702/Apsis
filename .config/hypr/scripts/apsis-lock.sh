#!/bin/sh
# Locks with the lockscreen chosen in Settings (Apsis or hyprlock); falls back to hyprlock.
# Edit: nothing usually; the choice is Settings > Desktop > Lock.

f="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/settings.json"
with=$(sed -n 's/.*"lockWith"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$f" 2>/dev/null | head -n 1)
[ -n "$with" ] || with=apsis

if [ "$with" = apsis ] && qs list 2>/dev/null | grep -q "^Instance" \
   && qs ipc call lock lock >/dev/null 2>&1; then
    exit 0
fi
pgrep -x hyprlock >/dev/null 2>&1 && exit 0
exec hyprlock
