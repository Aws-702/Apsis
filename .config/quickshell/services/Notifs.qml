// Notification history in $XDG_RUNTIME_DIR (memory only, up to 200), muted apps and timed DND.
// Edit: the 200 limit and the "ago" wording here.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property var entries: store.data.entries
    readonly property real seenAt: store.data.seenAt
    readonly property int unread: entries.filter(e => e.time > seenAt).length
    readonly property var muted: Settings.data.mutedApps || []
    property real dndUntil: 0

    readonly property var groups: {
        var by = {}, order = []
        for (var i = 0; i < entries.length; i++) {
            var e = entries[i]
            if (!by[e.app]) { by[e.app] = { app: e.app, icon: e.icon, items: [], latest: e.time }; order.push(e.app) }
            by[e.app].items.push(e)
        }
        return order.map(a => by[a])
    }

    function isMuted(app) { return muted.indexOf(app) >= 0 }
    function toggleMute(app) {
        var m = muted.slice()
        var i = m.indexOf(app)
        if (i >= 0) m.splice(i, 1); else m.push(app)
        Settings.set("mutedApps", m)
    }

    function add(n, silenced) {
        var app = String(n.appName || "").trim() || "Unknown"
        var e = {
            id: Date.now() + "-" + Math.floor(Math.random() * 1e6),
            app: app,
            icon: String(n.appIcon || ""),
            summary: String(n.summary || ""),
            body: String(n.body || "").replace(/<[^>]*>/g, ""),
            time: Date.now(),
            urgency: n.urgency === undefined ? 1 : Number(n.urgency),
            silenced: silenced === true
        }
        store.update(function(d) { d.entries = [e].concat(d.entries).slice(0, 200) })
    }
    function remove(id) { store.update(function(d) { d.entries = d.entries.filter(x => x.id !== id) }) }
    function clearApp(app) { store.update(function(d) { d.entries = d.entries.filter(x => x.app !== app) }) }
    function clearAll() { store.update(function(d) { d.entries = [] }) }
    function markSeen() { store.set("seenAt", Date.now()) }

    function dndFor(minutes) { Quickshell.execDetached([Config.scripts + "/apsis-dnd.sh", "on", String(minutes || 0)]) }
    function dndOff() { Quickshell.execDetached([Config.scripts + "/apsis-dnd.sh", "off"]) }

    function ago(t) {
        var s = Math.max(0, Math.round((Date.now() - t) / 1000))
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + " min"
        if (s < 86400) return Math.floor(s / 3600) + " h"
        return Qt.formatDate(new Date(t), "d MMM")
    }

    FileView {
        path: Config.cacheDir + "/apsis-dnd-until"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.dndUntil = (parseInt(text().trim()) || 0) * 1000
        onLoadFailed: root.dndUntil = 0
    }

    Timer {
        interval: 20000
        repeat: true
        running: root.dndUntil > 0
        triggeredOnStart: true
        onTriggered: if (root.dndUntil > 0 && Date.now() >= root.dndUntil) root.dndOff()
    }

    property JsonStore store: JsonStore {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/apsis/notifications.json"
        defaults: ({ entries: [], seenAt: 0 })
    }
}
