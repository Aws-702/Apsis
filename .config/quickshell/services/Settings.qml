// Shell settings (~/.local/state/apsis/settings.json), everything except palette and mode.
// Edit: the defaults block here sets every setting's starting value.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    readonly property var data: store.data
    readonly property bool ready: store.ready

    readonly property string notifyStyle: data.notifyStyle

    readonly property real phonePeek: data.phonePeek
    readonly property bool dockEnabled: data.dockEnabled
    readonly property bool dockAutohide: data.dockAutohide

    readonly property bool dockCards: data.dockCards
    readonly property bool gridSnap: data.gridSnap
    readonly property int gridSize: data.gridSize
    readonly property bool showWidgets: data.showWidgets

    readonly property string phoneStyle: data.phoneStyle

    readonly property string wallTransition: data.wallTransition

    readonly property string lockWith: data.lockWith

    readonly property string webSearch: data.webSearch

    readonly property string userName: String(data.userName || "").trim() || systemName
    property string systemName: {
        var u = Quickshell.env("USER") || ""
        return u.length ? u.charAt(0).toUpperCase() + u.substring(1) : "You"
    }

    property Process nameLookup: Process {
        running: true
        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        stdout: StdioCollector { onStreamFinished: { var n = this.text.trim(); if (n.length) root.systemName = n } }
    }

    function set(key, value) {
        store.set(key, value)

        if (String(key).indexOf("idle") === 0) idleApply.restart()
    }
    property Timer idleApply: Timer {
        interval: 1500
        onTriggered: Quickshell.execDetached([Config.scripts + "/apsis-idle.sh", "apply"])
    }

    readonly property string barEdge: data.barEdge === "bottom" ? "bottom" : "top"
    readonly property string barStyle: ["block", "floating", "slim"].indexOf(data.barStyle) >= 0 ? data.barStyle : "block"
    readonly property bool barAtBottom: barEdge === "bottom"

    readonly property int barGap: barStyle === "slim" ? 0 : Config.barMargin
    readonly property int barSpace: Config.barHeight + barGap

    readonly property var lyricsProviders: data.lyricsProviders
    function lyricsHas(name) { return (data.lyricsProviders || []).indexOf(name) >= 0 }
    function lyricsToggle(name) {
        var l = (data.lyricsProviders || []).slice()
        var i = l.indexOf(name)
        if (i >= 0) l.splice(i, 1); else l.push(name)
        store.set("lyricsProviders", l)
    }

    readonly property var barModules: data.barModules

    readonly property string dockEdge: ["bottom", "left", "right"].indexOf(data.dockEdge) >= 0 ? data.dockEdge : "bottom"

    readonly property string lockStyle: data.lockStyle
    readonly property bool lockFinger: data.lockFinger

    readonly property bool lockSleep: data.lockSleep
    readonly property string lockWall: data.lockWall

    readonly property string lockCrop: data.lockCrop
    readonly property string wallhavenSort: data.wallhavenSort

    readonly property bool idleEnabled: data.idleEnabled
    readonly property int idleLockMin: data.idleLockMin
    readonly property int idleScreenMin: data.idleScreenMin
    readonly property int idleSleepMin: data.idleSleepMin
    function toggle(key) { set(key, !store.data[key]) }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/settings.json"
        defaults: ({
            notifyStyle: "cards",
            phonePeek: 0.94,
            dockEnabled: true,
            dockAutohide: true,
            dockCards: true,
            gridSnap: true,
            gridSize: 24,
            showWidgets: true,
            phoneStyle: "2.5d",
            wallTransition: "random",
            lockWith: "apsis",
            webSearch: "https://duckduckgo.com/?q=%s",
            userName: "",

            mutedApps: [],

            recordAudio: true,

            sysThemeQt: true,
            sysThemeKde: true,
            sysThemeTerminal: true,
            lyricsProviders: ["lrclib", "netease"],
            barEdge: "top",
            barModules: null,
            barStyle: "block",
            dockEdge: "bottom",
            lockStyle: "cards",
            lockFinger: false,
            lockSleep: true,
            apsisUpdateCheck: true,
            lockWall: "",
            lockCrop: "center",
            wallhavenSort: "toplist",
            idleEnabled: true,
            idleLockMin: 10,
            idleScreenMin: 15,
            idleSleepMin: 0
        })
    }
}
