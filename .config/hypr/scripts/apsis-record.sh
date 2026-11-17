#!/bin/sh
# Screen recording with gpu-screen-recorder (encoded on the GPU), saved to ~/Videos/Recordings.
# Usage: apsis-record.sh start [screen|region] [audio|mute] | stop | toggle. Edit: fps and quality flags here.

state="$HOME/.cache/quickshell/apsis-record"
mkdir -p "$(dirname "$state")"
videos=$(xdg-user-dir VIDEOS 2>/dev/null)
[ -n "$videos" ] && [ "$videos" != "$HOME" ] || videos="$HOME/Videos"
dir="$videos/Recordings"
shelf="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/shelf.json"

pid_of() { cut -f1 "$state" 2>/dev/null; }
running() { p=$(pid_of); [ -n "$p" ] && kill -0 "$p" 2>/dev/null; }
say() { notify-send -a Apsis -i media-record "$1" "$2" 2>/dev/null; }

start() {
    running && { echo "already recording"; return 0; }
    if ! command -v gpu-screen-recorder >/dev/null 2>&1; then
        say "Can't record" "gpu-screen-recorder isn't installed (sudo pacman -S gpu-screen-recorder)"
        return 1
    fi
    what="${1:-screen}"; sound="$2"

    if [ -z "$sound" ]; then
        set_=$(tr -d ' \n' < "${XDG_STATE_HOME:-$HOME/.local/state}/apsis/settings.json" 2>/dev/null | sed -n 's/.*"recordAudio":\(true\|false\).*/\1/p')
        [ "$set_" = false ] && sound=mute || sound=audio
    fi
    mkdir -p "$dir"
    file="$dir/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"

    if [ "$what" = region ]; then
        command -v slurp >/dev/null 2>&1 || { say "Can't record a region" "slurp isn't installed"; return 1; }
        r=$(slurp -f '%wx%h+%x+%y') || return 0
        set -- -w region -region "$r"
    else
        mon=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)
        set -- -w "${mon:-screen}"
    fi
    [ "$sound" = mute ] || set -- "$@" -a default_output

    setsid -f sh -c 's=$1; f=$2; shift 2; echo $$ > "$s.pid"; exec gpu-screen-recorder "$@" -f 60 -o "$f" >"$s.log" 2>&1' \
        sh "$state" "$file" "$@"

    i=0; while [ ! -s "$state.pid" ] && [ $i -lt 20 ]; do sleep 0.05; i=$((i + 1)); done
    printf '%s\t%s\t%s\n' "$(cat "$state.pid" 2>/dev/null)" "$(date +%s)" "$file" > "$state"
    rm -f "$state.pid"
    sleep 0.6
    if ! running; then
        say "Recording didn't start" "$(tail -n 3 "$state.log" 2>/dev/null)"
        rm -f "$state"
        return 1
    fi
}

stop() {
    running || { rm -f "$state"; echo "not recording"; return 0; }
    p=$(pid_of); file=$(cut -f3 "$state")
    kill -INT "$p"

    i=0; while kill -0 "$p" 2>/dev/null && [ $i -lt 100 ]; do sleep 0.1; i=$((i + 1)); done
    rm -f "$state"
    if [ -s "$file" ]; then

        if command -v jq >/dev/null 2>&1; then
            mkdir -p "$(dirname "$shelf")"
            [ -f "$shelf" ] || printf '{"version":1,"items":[]}' > "$shelf"
            tmp="$shelf.$$"
            jq --arg p "$file" '.items = ([{path: $p}] + ((.items // []) | map(select(.path != $p))))[:24]' "$shelf" > "$tmp" 2>/dev/null && mv "$tmp" "$shelf" || rm -f "$tmp"
        fi
        say "Recording saved" "$(basename "$file") (on the dock's shelf)"
    else
        say "Recording failed" "$(tail -n 3 "$state.log" 2>/dev/null)"
    fi
}

status() {
    if running; then printf 'on\t%s\t%s\n' "$(cut -f2 "$state")" "$(cut -f3 "$state")"
    else echo off; fi
}

case "${1:-toggle}" in
    start) start "$2" "$3" ;;
    stop) stop ;;
    toggle) if running; then stop; else start "${2:-screen}" "$3"; fi ;;
    status) status ;;
    *) echo "usage: $0 start [screen|region] [audio|mute] | stop | toggle [screen|region] | status" >&2; exit 2 ;;
esac
