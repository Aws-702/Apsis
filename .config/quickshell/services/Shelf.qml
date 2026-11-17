// The dock's shelf: file paths put aside to drag out later (~/.local/state/apsis/shelf.json).
// Edit: the size limit here.

pragma Singleton
import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    readonly property var items: store.data.items || []

    function add(urls) {
        var paths = []
        for (var i = 0; i < urls.length; i++) {
            var u = String(urls[i])
            if (u.indexOf("file://") !== 0) continue
            paths.push(decodeURIComponent(u.substring(7)))
        }
        if (!paths.length) return
        store.update(function(d) {
            var have = d.items.map(function(x) { return x.path })
            for (var k = 0; k < paths.length; k++) if (have.indexOf(paths[k]) < 0) d.items.unshift({ path: paths[k] })
            d.items = d.items.slice(0, 24)
        })
    }
    function remove(path) { store.update(function(d) { d.items = d.items.filter(function(x) { return x.path !== path }) }) }
    function clear() { store.set("items", []) }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/shelf.json"
        defaults: ({ version: 1, items: [] })
    }
}
