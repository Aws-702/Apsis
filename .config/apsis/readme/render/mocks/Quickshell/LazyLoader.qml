// Stand-in for LazyLoader: creates its component while active.
// Edit: nothing.

import QtQuick
import ShotLab
QtObject {
    id: l
    default property Component component
    property bool active: false
    property bool loading: false
    property url source
    property QtObject item: null
    function _load() {
        if (!active || item) return
        var c = component
        if (!c && source.toString() !== "") c = Qt.createComponent(source)
        if (!c) return
        if (c.status === Component.Error) { console.warn("LazyLoader: " + c.errorString()); return }
        item = c.createObject(Shot.root)
    }
    onActiveChanged: _load()
    Component.onCompleted: _load()
}
