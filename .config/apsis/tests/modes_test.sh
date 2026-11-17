#!/bin/sh
# Tests Game mode, Focus mode and the idle config with stubbed programs in a throwaway home.
# Run: sh ~/.config/apsis/tests/modes_test.sh

set -u

here=$(cd "$(dirname "$0")/../.." && pwd)
scripts_src="$here/hypr/scripts"
[ -f "$scripts_src/apsis-game.sh" ] || { echo "can't find the scripts next to the tests"; exit 2; }

T=$(mktemp -d "${TMPDIR:-/tmp}/apsis-modes-test.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
H="$T/home"; B="$T/bin"; LOG="$T/calls.log"
mkdir -p "$H/.config/hypr/scripts" "$H/.cache/quickshell" "$H/.cache/apsis" "$H/.local/state/apsis" "$B"
cp "$scripts_src"/apsis-*.sh "$H/.config/hypr/scripts/"
: > "$LOG"

for cmd in hyprctl notify-send pkill awww qs; do
    cat > "$B/$cmd" <<STUB
#!/bin/sh
echo "$cmd \$*" >> "$LOG"
exit 0
STUB
    chmod +x "$B/$cmd"
done

export HOME="$H" PATH="$B:/usr/bin:/bin:/usr/local/bin" XDG_STATE_HOME="$H/.local/state"
S="$H/.config/hypr/scripts"
Q="$H/.cache/quickshell"

passed=0; failed=0
ok()    { passed=$((passed + 1)); }
bad()   { failed=$((failed + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok; else bad "$1: expected [$3] got [$2]"; fi; }
logged() { if grep -q -- "$2" "$LOG"; then ok; else bad "$1: no call matching [$2]"; fi; }
notlogged() { if grep -q -- "$2" "$LOG"; then bad "$1: unexpected call [$2]"; else ok; fi; }
clearlog() { : > "$LOG"; }
dnd() { cat "$Q/apsis-dnd" 2>/dev/null; }

printf off > "$Q/apsis-dnd"
sh "$S/apsis-game.sh" on
check "game: state on" "$(sh "$S/apsis-game.sh" status)" on
check "game: silence on" "$(dnd)" on
logged "game: animations off" "animations = { enabled = false }"
logged "game: gaps off" "gaps_in = 0"
logged "game: video paused" "pkill -STOP -x mpvpaper"
clearlog
sh "$S/apsis-game.sh" off
check "game: state off" "$(sh "$S/apsis-game.sh" status)" off
check "game: silence put back" "$(dnd)" off
logged "game: config reloaded" "hyprctl reload"
logged "game: video resumed" "pkill -CONT -x mpvpaper"

printf on > "$Q/apsis-dnd"
sh "$S/apsis-game.sh" on; sh "$S/apsis-game.sh" off
check "game: pre-existing silence kept" "$(dnd)" on
printf off > "$Q/apsis-dnd"

printf show > "$Q/apsis-bar"
clearlog
sh "$S/apsis-focus.sh" on
check "focus: state on" "$(sh "$S/apsis-focus.sh" status)" on
check "focus: bar hidden" "$(cat "$Q/apsis-bar")" hide
check "focus: silence on" "$(dnd)" on
logged "focus: dimming" "dim_inactive = true"
sh "$S/apsis-focus.sh" off
check "focus: bar back" "$(cat "$Q/apsis-bar")" show
check "focus: silence off" "$(dnd)" off

printf hide > "$Q/apsis-bar"
sh "$S/apsis-focus.sh" on; sh "$S/apsis-focus.sh" off
check "focus: your hidden bar stays hidden" "$(cat "$Q/apsis-bar")" hide
printf show > "$Q/apsis-bar"

sh "$S/apsis-focus.sh" on 1
i=0; while [ ! -f "$H/.cache/apsis/focus-timer.pid" ] && [ "$i" -lt 20 ]; do i=$((i + 1)); sleep 0.1; done
if [ -f "$H/.cache/apsis/focus-timer.pid" ]; then ok; else bad "focus: timer started"; fi
clearlog
sh "$S/apsis-focus.sh" end
check "focus: ended" "$(sh "$S/apsis-focus.sh" status)" off
logged "focus: says the session is over" "Focus session over"
if [ ! -f "$H/.cache/apsis/focus-timer.pid" ]; then ok; else bad "focus: timer cleared"; fi

sh "$S/apsis-game.sh" on; sh "$S/apsis-focus.sh" on
sh "$S/apsis-game.sh" off
check "both: silence stays while Focus is on" "$(dnd)" on
sh "$S/apsis-focus.sh" off
check "both: silence off when both are off" "$(dnd)" off

printf on > "$Q/apsis-ultra"
sh "$S/apsis-game.sh" on; clearlog; sh "$S/apsis-game.sh" off
notlogged "ultra: no reload while Ultra saver is on" "hyprctl reload"
rm -f "$Q/apsis-ultra"

sh "$S/apsis-game.sh" on; sh "$S/apsis-focus.sh" on
sh "$S/apsis-game.sh" reset; sh "$S/apsis-focus.sh" reset
check "reset: game" "$(sh "$S/apsis-game.sh" status)" off
check "reset: focus" "$(sh "$S/apsis-focus.sh" status)" off

echo '{"idleLockMin":5,"idleScreenMin":0,"idleSleepMin":20}' > "$H/.local/state/apsis/settings.json"
cfg=$(sh "$S/apsis-idle.sh" print)
case "$cfg" in *"timeout = 300"*) ok ;; *) bad "idle: lock at 5 minutes" ;; esac
case "$cfg" in *"timeout = 1200"*) ok ;; *) bad "idle: sleep at 20 minutes" ;; esac
case "$cfg" in *"apsis-screen.sh off"*) bad "idle: 0 means no screen-off step" ;; *) ok ;; esac
case "$cfg" in *"apsis/train"*) ok ;; *) bad "idle: sleep skips Training mode" ;; esac
echo '{}' > "$H/.local/state/apsis/settings.json"
cfg=$(sh "$S/apsis-idle.sh" print)
case "$cfg" in *"timeout = 600"*"timeout = 900"*) ok ;; *) bad "idle: defaults are lock 10, screens off 15" ;; esac
case "$cfg" in *"systemctl suspend"*) bad "idle: sleep is off by default" ;; *) ok ;; esac
echo '{"idleEnabled":false}' > "$H/.local/state/apsis/settings.json"
check "idle: disabled reads as off" "$(sh "$S/apsis-idle.sh" status)" off

echo "mode tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
