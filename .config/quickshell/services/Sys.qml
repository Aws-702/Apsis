// Shared readings (volume, brightness, media, stats, weather, radios), polled only while shown.
// Edit: each Poll's interval here; the readings come from hypr/scripts/apsis-*.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property int wantAudio: 0
    property int wantMedia: 0
    property int wantStats: 0
    property int wantWeather: 0
    property int wantRadios: 0

    readonly property bool phoneUp: PhoneState.open

    property int volume: 0
    property bool muted: false
    property bool micMuted: false
    property int brightness: 0

    Poll {
        active: root.phoneUp || root.wantAudio > 0
        interval: 1500
        command: ["sh", "-c", "printf '%s %s %s ' \"$(pamixer --get-volume 2>/dev/null)\" \"$(pamixer --get-mute 2>/dev/null)\" \"$(pamixer --default-source --get-mute 2>/dev/null)\"; c=$(brightnessctl get 2>/dev/null); m=$(brightnessctl max 2>/dev/null); [ -n \"$m\" ] && [ \"$m\" -gt 0 ] && echo $(( c * 100 / m )) || echo -1"]
        onUpdated: function(out) {
            var p = out.trim().split(/\s+/)
            root.volume = parseInt(p[0]) || 0
            root.muted = p[1] === "true"
            root.micMuted = p[2] === "true"
            var b = parseInt(p[3])
            root.brightness = isNaN(b) ? -1 : b
        }
    }

    function setVolume(v) {
        root.volume = Math.round(v)
        Quickshell.execDetached(["pamixer", "--set-volume", String(Math.round(v))])
    }
    function toggleMute() { root.muted = !root.muted; Quickshell.execDetached([Config.scripts + "/apsis-volume.sh", "mute"]) }
    function toggleMic() { root.micMuted = !root.micMuted; Quickshell.execDetached([Config.scripts + "/apsis-mic.sh"]) }
    function setBrightness(v) {
        root.brightness = Math.round(v)
        Quickshell.execDetached(["brightnessctl", "set", Math.max(1, Math.round(v)) + "%", "-q"])
    }

    property bool wifiOn: false
    property bool btOn: false
    property string wifiName: ""
    property string profile: "balanced"

    Poll {
        active: root.phoneUp || root.wantRadios > 0
        interval: 3000
        command: ["sh", "-c", "printf '%s\\t' \"$(nmcli radio wifi 2>/dev/null)\"; bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && printf 'on\\t' || printf 'off\\t'; printf '%s\\t' \"$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2)\"; " + Config.scripts + "/apsis-profile.sh get 2>/dev/null"]
        onUpdated: function(out) {
            var p = out.replace(/\n/g, "").split("\t")
            root.wifiOn = p[0] === "enabled"
            root.btOn = p[1] === "on"
            root.wifiName = p[2] || ""
            if (p[3]) root.profile = p[3].trim()
        }
    }

    function toggleWifi() {
        root.wifiOn = !root.wifiOn
        Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "on" : "off"])
    }
    function toggleBt() {
        root.btOn = !root.btOn
        Quickshell.execDetached(["bluetoothctl", "power", root.btOn ? "on" : "off"])
    }
    function setProfile(name) {
        root.profile = name.toLowerCase()
        Quickshell.execDetached([Config.scripts + "/apsis-profile.sh", "set", name])
    }

    property bool hasPlayer: false
    property bool playing: false
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string album: ""
    property string url: ""
    property real position: 0

    property real positionAt: Date.now()
    onPositionChanged: positionAt = Date.now()
    property real length: 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    Poll {
        id: mediaPoll
        active: root.phoneUp || root.wantMedia > 0
        interval: 2000
        command: [Config.scripts + "/apsis-media.sh", "status"]
        onUpdated: function(s) {
            if (!s || s.trim() === "") { root.hasPlayer = false; return }
            var p = s.split("\t")
            root.hasPlayer = true
            root.playing = p[0] === "Playing"
            var t = p[1] || ""
            var pp = parseFloat(p[4]) || 0
            root.length = (parseFloat(p[5]) || 0) / 1000000
            if (t !== root.title) { root.title = t; root.position = pp }
            else if (pp > 0) root.position = pp
            root.artist = p[2] || ""
            root.artUrl = p[3] || ""
            root.album = p[6] || ""
            root.url = (p[7] || "").trim()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.hasPlayer && root.playing && mediaPoll.active
        onTriggered: root.position = root.length > 0 ? Math.min(root.position + 1, root.length) : root.position + 1
    }
    function media(cmd) {
        if (cmd === "play-pause") root.playing = !root.playing
        Quickshell.execDetached([Config.scripts + "/apsis-media.sh", cmd])
        mediaPoll.now()
    }

    property int cpu: 0
    property int ram: 0
    property int temp: 0
    property int battery: -1
    property bool charging: false

    Poll {
        active: root.phoneUp || root.wantStats > 0
        interval: 3000
        command: ["sh", "-c", Config.scripts + "/apsis-sysinfo.sh; echo; b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n \"$b\" ] && echo \"$(cat $b/capacity) $(cat $b/status)\" || echo '-1 none'"]
        onUpdated: function(out) {
            var lines = out.trim().split("\n")
            var p = (lines[0] || "").trim().split(/\s+/)
            root.cpu = parseInt(p[0]) || 0
            root.ram = parseInt(p[1]) || 0
            root.temp = parseInt(p[2]) || 0
            var b = (lines[1] || "").trim().split(/\s+/)
            root.battery = parseInt(b[0])
            if (isNaN(root.battery)) root.battery = -1
            root.charging = b[1] === "Charging"
        }
    }

    property int temp_c: -999
    property string cond: ""
    property string desc: ""
    property int feels: -999
    property int hi: -999
    property int lo: -999
    property string city: ""
    readonly property bool hasWeather: temp_c > -999

    Poll {
        active: root.phoneUp || root.wantWeather > 0
        interval: 900000
        command: ["sh", "-c", Config.scripts + "/apsis-weather.sh"]
        onUpdated: function(out) {
            var p = out.split("\t")
            if (p.length < 2 || p[0] === "") return
            root.temp_c = parseInt(p[0])
            root.cond = p[1] || ""
            root.desc = (p[2] && p[2] !== "") ? p[2] : root.cond
            root.feels = (p[3] && p[3] !== "") ? parseInt(p[3]) : -999
            root.hi = (p[4] && p[4] !== "") ? parseInt(p[4]) : -999
            root.lo = (p[5] && p[5] !== "") ? parseInt(p[5]) : -999
            root.city = (p[7] && p[7] !== "") ? p[7].trim() : ""
        }
    }

    property bool nightLight: false
    property bool dnd: false
    property bool caffeine: false
    property bool game: false
    property bool focus: false
    property bool barHidden: false

    FileView { path: Config.cacheDir + "/apsis-nightlight"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.nightLight = text().trim() === "on" }
    FileView { path: Config.cacheDir + "/apsis-dnd"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.dnd = text().trim() === "on" }
    FileView { path: Config.cacheDir + "/apsis-game"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.game = text().trim() === "on" }
    FileView { path: Config.cacheDir + "/apsis-focus"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.focus = text().trim() === "on" }
    FileView { path: Config.cacheDir + "/apsis-caffeine"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.caffeine = text().trim() === "on" }
    FileView { path: Config.cacheDir + "/apsis-bar"; watchChanges: true; preload: true; printErrors: false; onFileChanged: reload(); onTextChanged: root.barHidden = text().trim() === "hide" }

    function script(name, arg) { Quickshell.execDetached(arg ? [Config.scripts + "/" + name, arg] : [Config.scripts + "/" + name]) }
}
