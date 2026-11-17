#!/bin/sh
# Nudges the phone open on Apps (SUPER + R).
# Edit: nothing; the phone reacts in phone/Phone.qml.

f="$HOME/.cache/quickshell/apsis-launcher"
mkdir -p "$(dirname "$f")"
date +%s%N > "$f"
