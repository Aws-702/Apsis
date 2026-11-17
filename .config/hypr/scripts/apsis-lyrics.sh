#!/bin/sh
# Finds synced lyrics for the playing song: cache, a .lrc beside it, LRCLIB, NetEase.
# Usage: apsis-lyrics.sh [sources|pick] ARTIST TITLE ALBUM SECONDS URL. Edit: scoring in score().

mode=lyrics
case "$1" in sources|pick) mode="$1"; shift ;; esac
artist="$1"; title="$2"; album="$3"; secs="$4"; url="$5"; want="$6"
[ -n "$title" ] || exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/apsis/lyrics"
mkdir -p "$cache"
settings="${XDG_STATE_HOME:-$HOME/.local/state}/apsis/settings.json"
ua="Apsis shell (https://github.com/Aws-702/Apsis)"
lrclib_api="${APSIS_LRCLIB_API:-https://lrclib.net/api}"
netease_api="${APSIS_NETEASE_API:-https://music.163.com/api}"

clean() { printf '%s' "$1" | sed -E 's/ *[([][^])]*\b(official|lyrics?|video|audio|visuali[sz]er|hd|4k|mv|remaster(ed)?)\b[^])]*[])]//Ig; s/ +$//'; }
title=$(clean "$title")
case "$title" in
    *" - "*)
        if [ -z "$artist" ] || printf '%s' "$artist" | grep -qiE 'vevo|topic|official|records'; then
            artist="${title%% - *}"; title="${title#* - }"
        fi ;;
esac
artist=$(printf '%s' "$artist" | sed -E 's/ - Topic$//; s/VEVO$//')
secs=$(printf '%.0f' "${secs:-0}" 2>/dev/null || echo 0)

key=$(printf '%s\t%s' "$(printf '%s' "$artist" | tr '[:upper:]' '[:lower:]')" "$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')" | md5sum | cut -c1-20)

providers() {
    p=""
    if [ -f "$settings" ] && command -v jq >/dev/null 2>&1; then
        p=$(jq -r '(.lyricsProviders // empty) | if type == "array" then .[] else empty end' "$settings" 2>/dev/null | tr '\n' ' ')
    fi
    [ -n "$p" ] || p="lrclib netease"
    echo "local $p"
}

src_local() {
    case "$url" in
        file://*)
            path=$(printf '%s' "${url#file://}" | sed 's/+/ /g; s/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf '%b' 2>/dev/null)
            lrc="${path%.*}.lrc"
            [ -s "$lrc" ] && cat "$lrc" ;;
    esac
}

synced() {
    jq -r 'if type == "array" then (map(select(.syncedLyrics != null)) | .[0].syncedLyrics // empty) else (.syncedLyrics // empty) end' 2>/dev/null
}

src_lrclib() {
    command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 0
    out=$(curl -sfG --max-time 8 -A "$ua" "$lrclib_api/get" \
            --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title" \
            --data-urlencode "album_name=$album" --data-urlencode "duration=$secs" 2>/dev/null | synced)
    if [ -z "$out" ]; then
        out=$(curl -sfG --max-time 8 -A "$ua" "$lrclib_api/search" \
                --data-urlencode "artist_name=$artist" --data-urlencode "track_name=$title" 2>/dev/null | synced)
    fi
    printf '%s' "$out"
}

src_netease() {
    command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 || return 0
    q="$title $artist"
    id=$(curl -sf --max-time 8 -A "$ua" "$netease_api/search/get/" \
            --data-urlencode "s=$q" -d "limit=5" -d "type=1" -d "offset=0" 2>/dev/null \
         | jq -r '.result.songs[0].id // empty' 2>/dev/null)
    printf '%s' "$id" | grep -Eq '^[0-9]{1,15}$' || return 0

    wt=$(curl -sf --max-time 8 -A "$ua" "$netease_api/song/lyric/v1?id=$id&lv=1&yv=1&tv=-1" 2>/dev/null \
         | jq -r '.yrc.lyric // empty' 2>/dev/null)
    if [ -n "$wt" ]; then
        printf '%s\n' "$wt" | yrc_to_lrc
        return 0
    fi
    curl -sf --max-time 8 -A "$ua" "$netease_api/song/lyric?id=$id&lv=1&kv=1&tv=-1" 2>/dev/null \
        | jq -r '.lrc.lyric // empty' 2>/dev/null
}

yrc_to_lrc() {
    awk '
    function stamp(ms,   m, s) { m = int(ms / 60000); s = (ms - m * 60000) / 1000; return sprintf("%02d:%05.2f", m, s) }
    /^\[[0-9]+,[0-9]+\]/ {
        line = $0
        match(line, /^\[[0-9]+,[0-9]+\]/)
        head = substr(line, 2, RLENGTH - 2); split(head, h, ",")
        rest = substr(line, RLENGTH + 1)
        out = "[" stamp(h[1]) "]"
        while (match(rest, /^\([0-9]+,[0-9]+,[0-9]+\)/)) {
            t = substr(rest, 2, RLENGTH - 2); split(t, w, ",")
            rest = substr(rest, RLENGTH + 1)
            # the word runs to the next "(start,dur,0)" tag
            if (match(rest, /\([0-9]+,[0-9]+,[0-9]+\)/)) { word = substr(rest, 1, RSTART - 1); rest = substr(rest, RSTART) }
            else { word = rest; rest = "" }
            out = out "<" stamp(w[1]) ">" word
        }
        print out
    }'
}

score() {
    file="$1"
    awk -v secs="$secs" '
    function tosec(s,   a) { split(s, a, ":"); return a[1] * 60 + a[2] }
    {
        if (match($0, /^\[[0-9]+:[0-9.]+\]/)) {
            n++
            t = tosec(substr($0, 2, RLENGTH - 2))
            if (t > last) last = t
            if ($0 ~ /<[0-9]+:[0-9.]+>/) w++
        }
    }
    END {
        if (n < 2) { print 0; exit }
        s = 100
        if (w >= n / 2) s += 40
        f = n; if (f > 60) f = 60
        s += f / 3
        if (secs > 0 && last > secs + 5) s -= 40
        if (secs > 0 && last < secs * 0.4) s -= 20
        printf "%d\n", s
    }' "$file"
}

want_words() { grep -Eq '<[0-9]+:[0-9.]+>' "$1" && echo yes || echo no; }

gather() {

    if [ -s "$cache/$key.lrc" ] && [ ! -e "$cache/$key.lrclib.lrc" ]; then mv "$cache/$key.lrc" "$cache/$key.lrclib.lrc"; fi
    for p in $(providers); do
        f="$cache/$key.$p.lrc"
        if [ -s "$f" ]; then continue; fi
        if [ -e "$cache/$key.$p.none" ] && [ -n "$(find "$cache/$key.$p.none" -mmin -1440 2>/dev/null)" ]; then continue; fi
        case "$p" in
            local)   out=$(src_local) ;;
            lrclib)  out=$(src_lrclib) ;;
            netease) out=$(src_netease) ;;
            *)       continue ;;
        esac
        if [ -n "$out" ] && printf '%s\n' "$out" | grep -Eq '^\[[0-9]+:[0-9.]+\]'; then
            printf '%s\n' "$out" > "$f"
        else
            [ "$p" = local ] || : > "$cache/$key.$p.none"
        fi
    done
}

choose() {
    pk=$(cat "$cache/$key.pick" 2>/dev/null)
    if [ -n "$pk" ] && [ -s "$cache/$key.$pk.lrc" ]; then echo "$pk"; return; fi
    best=""; bs=0
    for p in $(providers); do
        f="$cache/$key.$p.lrc"
        [ -s "$f" ] || continue
        s=$(score "$f")

        if [ "$s" -gt "$bs" ]; then bs="$s"; best="$p"; fi
    done
    [ -n "$best" ] && echo "$best"
}

gather
case "$mode" in
lyrics)
    w=$(choose)
    [ -n "$w" ] && cat "$cache/$key.$w.lrc"
    ;;
sources)
    w=$(choose)
    TAB=$(printf '\t')
    for p in $(providers); do
        f="$cache/$key.$p.lrc"
        [ -s "$f" ] || continue
        mark=""; [ "$p" = "$w" ] && mark="*"
        printf '%s%s%s%s%s%s%s%s%s\n' "$p" "$TAB" "$(score "$f")" "$TAB" "$(grep -Ec '^\[[0-9]+:[0-9.]+\]' "$f")" "$TAB" "$(want_words "$f")" "$TAB" "$mark"
    done
    ;;
pick)
    case "$want" in
        auto|"") rm -f "$cache/$key.pick" ;;
        *) if printf '%s' "$want" | grep -Eq '^[a-z]{2,12}$' && [ -s "$cache/$key.$want.lrc" ]; then printf '%s' "$want" > "$cache/$key.pick"; else echo "no such source for this song" >&2; exit 1; fi ;;
    esac
    ;;
esac
exit 0
