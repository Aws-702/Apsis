// Apps hidden from the Apps screen, saved in ~/.local/state/apsis/apps.json.
// Edit: nothing visual here; starring is the dock's pins (services/Dock.qml).

pragma Singleton
import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    readonly property var hidden: store.data.hidden || []

    function isHidden(id) { return hidden.indexOf(id) >= 0 }
    function hide(id) { if (id && !isHidden(id)) store.update(function(d) { d.hidden.push(id) }) }
    function unhide(id) { store.update(function(d) { d.hidden = d.hidden.filter(function(h) { return h !== id }) }) }

    function uninstall(id) {
        if (id) Quickshell.execDetached([Config.scripts + "/apsis-uninstall.sh", id])
    }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/apps.json"
        defaults: ({ version: 1, hidden: [] })
    }
}
