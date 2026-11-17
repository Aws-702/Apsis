// Desktop widgets and presets, saved in ~/.local/state/apsis/widgets.json and presets.json.
// Edit: default widgets here; preset rules in lib/PresetMath.js, widget types in lib/WidgetTypes.js.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/WidgetTypes.js" as Types
import "../lib/PresetMath.js" as PM
import "../lib/EditGridMath.js" as GM

Singleton {
    id: root

    readonly property var widgets: store.data.widgets || []
    readonly property var presets: presetStore.data.presets || ({})
    readonly property var presetNames: PM.sortedNames(presets)

    property var undoState: null
    readonly property bool canUndo: undoState !== null
    readonly property var types: Types.TYPES
    readonly property var typeOrder: Types.ORDER
    property string barState: "show"

    function newId() { return "w" + Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36) }

    function onScreen(name, first) {
        var out = []
        for (var i = 0; i < widgets.length; i++) {
            var s = widgets[i].screen || ""
            if (s === name || (s === "" && first)) out.push(widgets[i])
        }
        return out
    }

    function find(id) {
        for (var i = 0; i < widgets.length; i++) if (widgets[i].id === id) return widgets[i]
        return null
    }

    function rectsExcept(id, screen, first) {
        var list = onScreen(screen, first)
        var out = []
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id) continue
            var t = Types.info(list[i].type)
            var sz = Types.size(list[i].type, list[i].style)
            if (t) out.push({ x: list[i].x, y: list[i].y, w: sz.w, h: sz.h })
        }
        return out
    }

    function add(type, screen, roomW, roomH, first) {
        var t = Types.info(type)
        if (!t) return ""
        var spot = GM.freeSpot(t.w, t.h, rectsExcept("", screen, first), { roomW: roomW, roomH: roomH, grid: Settings.gridSize })
        var w = { id: newId(), type: type, x: spot.x, y: spot.y, screen: screen, style: Types.styleOf(type, {}) }
        store.update(function(d) { d.widgets.push(w) })
        return w.id
    }

    function remove(id) {
        store.update(function(d) { d.widgets = d.widgets.filter(function(w) { return w.id !== id }) })
    }

    function move(id, x, y) {
        store.update(function(d) {
            for (var i = 0; i < d.widgets.length; i++)
                if (d.widgets[i].id === id) { d.widgets[i].x = Math.round(x); d.widgets[i].y = Math.round(y) }
        })
    }

    function setStyle(id, key, value) {
        store.update(function(d) {
            for (var i = 0; i < d.widgets.length; i++)
                if (d.widgets[i].id === id) { d.widgets[i].style = d.widgets[i].style || {}; d.widgets[i].style[key] = value }
        })
    }

    function setField(id, key, value) {
        store.update(function(d) {
            for (var i = 0; i < d.widgets.length; i++)
                if (d.widgets[i].id === id) d.widgets[i][key] = value
        })
    }

    function liveState() {
        return {
            palette: Theme.palette,
            mode: Theme.mode,
            widgets: root.widgets,
            dock: { enabled: Settings.dockEnabled, autohide: Settings.dockAutohide },
            bar: { shown: root.barState !== "hide" }
        }
    }

    function savePreset(name) {
        var n = PM.safeName(name)
        if (!n.length) return false
        var p = PM.capture(n, liveState(), Types.TYPES)
        presetStore.update(function(d) { d.presets[n] = p })
        return true
    }

    function deletePreset(name) {
        presetStore.update(function(d) { delete d.presets[name] })
    }

    function renamePreset(from, to) {
        var r = PM.rename(presets, from, to)
        if (!r.ok) return r.why
        presetStore.update(function(d) { d.presets = r.presets })
        return ""
    }

    function toggleFavorite(name) {
        presetStore.update(function(d) { if (d.presets[name]) d.presets[name].favorite = !d.presets[name].favorite })
    }

    function undoPreset() {
        var u = undoState
        if (!u) return
        undoState = null
        store.update(function(d) { d.widgets = u.widgets })
        Settings.set("dockEnabled", u.dock.enabled !== false)
        Settings.set("dockAutohide", u.dock.autohide !== false)
        if (u.palette !== Theme.palette) Quickshell.execDetached([Config.scripts + "/apsis-palette.sh", u.palette])
        if (u.mode !== Theme.mode) Quickshell.execDetached([Config.scripts + "/apsis-mode.sh", u.mode])
        Quickshell.execDetached([Config.scripts + "/apsis-bar.sh", u.bar.shown === false ? "hide" : "show"])
    }

    function applyPreset(name) {
        var p = presets[name]
        if (!p) return
        undoState = JSON.parse(JSON.stringify(liveState()))
        var s = PM.apply(p, liveState(), Types.TYPES)
        store.update(function(d) { d.widgets = s.widgets })
        Settings.set("dockEnabled", s.dock.enabled !== false)
        Settings.set("dockAutohide", s.dock.autohide !== false)
        if (s.palette !== Theme.palette) Quickshell.execDetached([Config.scripts + "/apsis-palette.sh", s.palette])
        if (s.mode !== Theme.mode) Quickshell.execDetached([Config.scripts + "/apsis-mode.sh", s.mode])
        Quickshell.execDetached([Config.scripts + "/apsis-bar.sh", s.bar.shown === false ? "hide" : "show"])
    }

    property FileView barFile: FileView {
        path: Config.cacheDir + "/apsis-bar"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.barState = text().trim() === "hide" ? "hide" : "show"
    }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/widgets.json"
        defaults: ({ version: 1, widgets: [] })
    }

    property JsonStore presetStore: JsonStore {
        path: Config.stateDir + "/presets.json"
        defaults: ({ version: 1, presets: {} })
    }
}
