// The dock's pinned apps (~/.local/state/apsis/dock.json) plus the running windows.
// Edit: default pins here.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"

Singleton {
    id: root

    property bool revealed: false
    property bool forcedHidden: false
    property bool held: false

    function toggle() {
        if (Settings.dockAutohide) { forcedHidden = false; held = !held }
        else { held = false; forcedHidden = !forcedHidden }
    }

    property string card: ""

    property string cardScreen: ""
    function toggleCard(name, screen) {
        if (card === name) { card = ""; return }
        if (screen) cardScreen = screen
        card = name
    }

    readonly property var pinned: store.data.pinned || []

    function isPinned(id) { return pinned.indexOf(id) >= 0 }
    function pin(id) { if (id && !isPinned(id)) store.update(function(d) { d.pinned.push(id) }) }
    function unpin(id) { store.update(function(d) { d.pinned = d.pinned.filter(function(p) { return p !== id }) }) }
    function togglePin(id) { isPinned(id) ? unpin(id) : pin(id) }
    function moveTo(id, index) {
        store.update(function(d) {
            var a = d.pinned.filter(function(p) { return p !== id })
            a.splice(Math.max(0, Math.min(a.length, index)), 0, id)
            d.pinned = a
        })
    }

    function entry(id) {
        if (!id) return null
        try {
            return DesktopEntries.byId(id) || DesktopEntries.heuristicLookup(id)
        } catch (e) {
            return null
        }
    }

    function toplevelsFor(id) {
        var out = []
        var all = []
        try { all = ToplevelManager.toplevels.values || [] } catch (e) { all = [] }
        var low = String(id).toLowerCase()
        for (var i = 0; i < all.length; i++) {
            var a = String(all[i].appId || "").toLowerCase()
            if (a === low || a.indexOf(low) >= 0 || low.indexOf(a) >= 0 && a.length > 2) out.push(all[i])
        }
        return out
    }

    readonly property var items: {
        var out = []
        var seen = {}
        var all = []
        try { all = ToplevelManager.toplevels.values || [] } catch (e) { all = [] }
        for (var i = 0; i < pinned.length; i++) {
            var tl = toplevelsFor(pinned[i])
            out.push({ id: pinned[i], pinned: true, running: tl.length > 0, toplevels: tl })
            seen[pinned[i].toLowerCase()] = true
            for (var j = 0; j < tl.length; j++) seen[String(tl[j].appId || "").toLowerCase()] = true
        }
        for (var k = 0; k < all.length; k++) {
            var a = String(all[k].appId || "")
            if (!a.length || seen[a.toLowerCase()]) continue
            seen[a.toLowerCase()] = true
            out.push({ id: a, pinned: false, running: true, toplevels: toplevelsFor(a) })
        }
        return out
    }

    function launch(id) {
        var e = entry(id)
        if (e) {
            try { e.execute(); return } catch (err) {}
        }
        Quickshell.execDetached(["sh", "-c", "uwsm app -- " + id + ".desktop >/dev/null 2>&1 || gtk-launch " + id])
    }

    function activate(item) {
        if (item.toplevels && item.toplevels.length) {
            var t = item.toplevels[0]
            try { t.activate(); return } catch (e) {}
        }
        launch(item.id)
    }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/dock.json"

        defaults: ({ version: 1, pinned: ["kitty", "thunar", "brave-browser", "dev.zed.Zed"] })
    }
}
