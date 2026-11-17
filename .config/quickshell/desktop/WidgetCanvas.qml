// All desktop widgets of one monitor, kept in a synced model so typing never rebuilds them.
// Edit: nothing visual here; each widget's look is in desktop/widgets/.

import QtQuick
import "../services"

Item {
    id: root
    property string screenName: ""
    property bool firstScreen: false
    property bool editing: false
    readonly property var list: Desktop.onScreen(screenName, firstScreen)

    ListModel { id: ids }

    function sync() {
        var want = {}
        for (var i = 0; i < list.length; i++) want[list[i].id] = true
        for (var j = ids.count - 1; j >= 0; j--)
            if (!want[ids.get(j).wid]) ids.remove(j)
        var have = {}
        for (var k = 0; k < ids.count; k++) have[ids.get(k).wid] = true
        for (var m = 0; m < list.length; m++)
            if (!have[list[m].id]) ids.append({ wid: list[m].id })
    }
    onListChanged: sync()
    Component.onCompleted: sync()

    Repeater {
        model: ids
        WidgetFrame {
            required property string wid
            widget: Desktop.find(wid) || ({ id: wid, type: "", x: 0, y: 0 })
            editing: root.editing
            screenName: root.screenName
            firstScreen: root.firstScreen
            roomW: root.width
            roomH: root.height
        }
    }
}
