#!/bin/sh
# Nudges the power menu open (ALT + F4).
# Edit: nothing; the menu is panel/PowerMenu.qml.

mkdir -p "$HOME/.cache/quickshell"
printf 'open %s' "$(date +%s%N)" > "$HOME/.cache/quickshell/apsis-powermenu"
