#!/bin/sh
# Tests apsis-lyrics.sh against local fakes of LRCLIB and NetEase.
# Run: sh ~/.config/apsis/tests/lyrics_test.sh

here=$(cd "$(dirname "$0")" && pwd)
script="$here/../../hypr/scripts/apsis-lyrics.sh"
T=$(mktemp -d)
pass=0; fail=0
ok() { if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: got [$2] want [$3]"; fi; }
has() { if printf '%s' "$2" | grep -q "$3"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: [$2] lacks [$3]"; fi; }

cat > "$T/srv.py" <<'EOF'
import json, sys
from http.server import BaseHTTPRequestHandler, HTTPServer
LRC = "\n".join("[%02d:%02d.00]line %d" % (i // 60, i % 60, i) for i in range(5, 65, 4))
YRC = "[5000,2000](5000,500,0)he(5500,500,0)llo \n[9000,2000](9000,1000,0)wor(10000,1000,0)ld \n[13000,2000](13000,1000,0)aa(14000,1000,0)bb"
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, obj):
        b = json.dumps(obj).encode()
        self.send_response(200); self.send_header("Content-Type", "application/json"); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        p = self.path
        if p.startswith("/lrclib/get"): return self.send({"syncedLyrics": "[00:01.00]only\n[00:05.00]two"} if "thin" in p else {"syncedLyrics": LRC})
        if p.startswith("/lrclib/search"): return self.send([])
        if p.startswith("/ne/song/lyric/v1"):
            return self.send({"yrc": {"lyric": YRC}} if "id=777" in p else {})
        if p.startswith("/ne/song/lyric"): return self.send({"lrc": {"lyric": LRC}})
        self.send({})
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0)); body = self.rfile.read(n).decode()
        if self.path.startswith("/ne/search/get"):
            return self.send({"code": 200, "result": {"songs": [{"id": 777 if "wordy" in body.lower() else 888}]}})
        self.send({})
HTTPServer(("127.0.0.1", 8799), H).serve_forever()
EOF
python3 "$T/srv.py" & srv=$!
sleep 1
export XDG_CACHE_HOME="$T/cache" XDG_STATE_HOME="$T/state" HOME="$T/home"
export APSIS_LRCLIB_API=http://127.0.0.1:8799/lrclib APSIS_NETEASE_API=http://127.0.0.1:8799/ne
mkdir -p "$T/home" "$T/state/apsis"

out=$(sh "$script" Artist Plain Album 70 "")
has "plain lyrics printed" "$out" "line 5"
src=$(sh "$script" sources Artist Plain Album 70 "")
has "both sources listed" "$src" "lrclib"
has "netease listed" "$src" "netease"
ok "lrclib chosen on a tie" "$(printf '%s\n' "$src" | grep '\*' | cut -f1)" "lrclib"

out=$(sh "$script" Artist Wordy Album 70 "")
has "word tags present" "$out" "<00:05.00>he"
has "enhanced line format" "$out" "^\[00:05.00\]<00:05.00>he<00:05.50>llo"
src=$(sh "$script" sources Artist Wordy Album 70 "")
ok "netease chosen for word timing" "$(printf '%s\n' "$src" | grep '\*' | cut -f1)" "netease"
ok "words flag" "$(printf '%s\n' "$src" | grep '^netease' | cut -f4)" "yes"

sh "$script" pick Artist Wordy Album 70 "" lrclib
ok "picked source wins" "$(sh "$script" sources Artist Wordy Album 70 "" | grep '\*' | cut -f1)" "lrclib"
sh "$script" pick Artist Wordy Album 70 "" auto
ok "auto restores best" "$(sh "$script" sources Artist Wordy Album 70 "" | grep '\*' | cut -f1)" "netease"
sh "$script" pick Artist Wordy Album 70 "" nonsense 2>/dev/null
ok "bad pick refused" "$?" "1"

out=$(sh "$script" Artist thin Album 70 "")
has "fuller text wins over a 2 line one" "$out" "line 9"

src=$(sh "$script" sources Artist Plain Album 20 "")
s=$(printf '%s\n' "$src" | grep '^lrclib' | cut -f2)
if [ "${s:-0}" -lt 100 ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL overlong not penalised: $s"; fi

echo '{"lyricsProviders":["netease"]}' > "$T/state/apsis/settings.json"
src=$(sh "$script" sources Artist Plain Album 70 "")
ok "only netease asked" "$(printf '%s\n' "$src" | cut -f1 | tr '\n' ' ')" "netease "
rm -f "$T/state/apsis/settings.json"

mkdir -p "$T/music"; printf '[00:01.00]mine\n[00:03.00]mine two\n' > "$T/music/song one.lrc"; : > "$T/music/song one.mp3"
out=$(sh "$script" Artist Local Album 5 "file://$T/music/song%20one.mp3")
has "local lrc read" "$out" "mine"

key=$(printf '%s\t%s' "artist" "old" | md5sum | cut -c1-20)
printf '[00:01.00]cached a\n[00:09.00]cached b\n' > "$T/cache/apsis/lyrics/$key.lrc"
out=$(sh "$script" Artist Old Album 30 "")
has "old cache adopted" "$out" "cached a"

out=$(sh "$script" "" "" "" 0 "")
ok "no title, no output" "$out" ""

kill $srv 2>/dev/null
echo "lyrics tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
