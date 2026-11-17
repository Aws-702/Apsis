// Synced lyrics of the playing song for the Lyrics widget (found by apsis-lyrics.sh).
// Edit: sources and their order in Settings (lyricsProviders) or hypr/scripts/apsis-lyrics.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/Lrc.js" as Lrc

Singleton {
    id: root

    property int want: 0
    property var lines: []
    property string phase: "idle"
    property real nudge: 0
    property string forKey: ""

    property var sources: []

    readonly property string songKey: Sys.hasPlayer && Sys.title !== "" ? Sys.artist + "\t" + Sys.title : ""

    function now() {
        var t = Sys.position
        if (Sys.playing) t += (Date.now() - Sys.positionAt) / 1000
        if (Sys.length > 0) t = Math.min(t, Sys.length)
        return t + root.nudge
    }

    function look() {
        if (root.want <= 0) return
        if (root.songKey === "") { root.lines = []; root.phase = "idle"; root.forKey = ""; return }
        if (root.songKey === root.forKey) return
        root.forKey = root.songKey
        root.lines = []
        root.sources = []
        root.nudge = 0
        root.phase = "looking"
        finder.running = false
        finder.command = root.args("")
        finder.running = true
    }

    function args(verb, extra) {
        var a = [Config.scripts + "/apsis-lyrics.sh"]
        if (verb !== "") a.push(verb)
        a.push(Sys.artist, Sys.title, Sys.album, String(Math.round(Sys.length)), Sys.url)
        if (extra) a.push(extra)
        return a
    }

    function pick(name) {
        picker.command = root.args("pick", name)
        picker.running = true
    }
    function refreshSources() {
        lister.command = root.args("sources")
        lister.running = true
    }
    Process {
        id: picker
        onExited: { root.forKey = ""; root.look() }
    }
    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var rows = this.text.trim().split("\n")
                for (var i = 0; i < rows.length; i++) {
                    var p = rows[i].split("\t")
                    if (p.length >= 4) out.push({ name: p[0], score: parseInt(p[1]) || 0, lines: parseInt(p[2]) || 0, words: p[3] === "yes", chosen: p[4] === "*" })
                }
                root.sources = out
            }
        }
    }

    onSongKeyChanged: settle.restart()
    onWantChanged: settle.restart()

    Timer { id: settle; interval: 600; onTriggered: root.look() }

    Process {
        id: finder
        property string key: ""
        onStarted: key = root.forKey
        stdout: StdioCollector {
            onStreamFinished: {
                if (finder.key !== root.forKey && finder.key !== "") return
                var l = Lrc.parse(this.text)
                root.lines = l
                root.phase = l.length ? "found" : "none"
                if (l.length) root.refreshSources(); else root.sources = []
            }
        }
    }
}
