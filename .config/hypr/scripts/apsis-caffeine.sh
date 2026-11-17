#!/bin/sh
# Keep awake: each run toggles a held systemd-inhibit lock.
# Edit: --what for what it blocks (idle:sleep).

mkdir -p "$HOME/.cache/quickshell"
STATE="$HOME/.cache/quickshell/apsis-caffeine"
PIDF="$HOME/.cache/quickshell/apsis-caffeine.pid"
if [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; then
    kill "$(cat "$PIDF")" 2>/dev/null
    rm -f "$PIDF"
    printf 'off' > "$STATE"
else
    systemd-inhibit --what=idle:sleep --who=Apsis --why="Keep awake" sleep infinity >/dev/null 2>&1 &
    echo $! > "$PIDF"
    printf 'on' > "$STATE"
fi
