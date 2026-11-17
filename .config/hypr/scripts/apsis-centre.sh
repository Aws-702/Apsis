#!/bin/sh
# Nudges the phone open on the quick panel (SUPER + Space).
# Edit: nothing; the phone reacts in phone/Phone.qml.

f="$HOME/.cache/quickshell/apsis-centre"
mkdir -p "$(dirname "$f")"
date +%s%N > "$f"
