// One JSON file of durable state with defaults; update() and set() save shortly after.
// Edit: the save delay here.

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string path
    property var defaults: ({})
    property var data: merged({})
    property bool ready: false
    signal loaded()

    function clone(v) { return JSON.parse(JSON.stringify(v)) }

    function merged(obj) {
        var out = clone(root.defaults)
        if (obj && typeof obj === "object")
            for (var k in obj) out[k] = obj[k]
        return out
    }

    function get(key) { return root.data[key] }

    function set(key, value) {
        update(function(d) { d[key] = value })
    }

    function update(fn) {
        var d = clone(root.data)
        fn(d)
        root.data = d
        saveTimer.restart()
    }

    function replace(obj) {
        root.data = merged(obj)
        saveTimer.restart()
    }

    function _read() {
        try {
            var t = String(file.text() || "").trim()
            root.data = merged(t.length ? JSON.parse(t) : {})
        } catch (e) {
            console.warn("apsis: could not parse " + root.path + ", using defaults")
            root.data = merged({})
        }
        if (!root.ready) { root.ready = true; root.loaded() }
    }

    property FileView file: FileView {
        path: root.path
        preload: true
        blockLoading: true
        printErrors: false

        watchChanges: true
        onFileChanged: if (!root.saveTimer.running) reload()
        onLoaded: root._read()
        onLoadFailed: function(err) {
            root.data = root.merged({})
            if (!root.ready) { root.ready = true; root.loaded() }
        }
    }

    property Timer saveTimer: Timer {
        interval: 300
        onTriggered: root.file.setText(JSON.stringify(root.data, null, 2) + "\n")
    }

    property Timer readyTimer: Timer {
        interval: 600
        running: true
        onTriggered: if (!root.ready) root._read()
    }

    Component.onCompleted: {
        var dir = root.path.substring(0, root.path.lastIndexOf("/"))
        if (dir.length) Quickshell.execDetached(["mkdir", "-p", dir])
    }
}
