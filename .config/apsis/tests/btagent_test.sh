#!/bin/sh
# Runs the pairing agent tests on a private D-Bus; your real Bluetooth is never touched.
# Run: sh ~/.config/apsis/tests/btagent_test.sh

here=$(cd "$(dirname "$0")" && pwd)
command -v dbus-run-session >/dev/null 2>&1 || { echo "needs dbus-run-session (the dbus package)"; exit 2; }

py=
for p in python3 python3.12 python3.13 python3.11 python3.14; do
    if command -v "$p" >/dev/null 2>&1 && "$p" -c 'import gi; gi.require_version("Gio", "2.0"); from gi.repository import Gio' 2>/dev/null; then
        py=$p; break
    fi
done
[ -n "$py" ] || { echo "needs python-gobject (sudo pacman -S python-gobject)"; exit 2; }

APSIS_BT_TEST_LOG=$(mktemp "${TMPDIR:-/tmp}/apsis-bt-test.XXXXXX") || exit 2
export APSIS_BT_TEST_LOG
trap 'rm -f "$APSIS_BT_TEST_LOG"' EXIT
exec dbus-run-session -- "$py" "$here/btagent_test.py"
