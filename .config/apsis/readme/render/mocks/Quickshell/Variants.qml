// Stand-in for Variants: one instance per model entry, on the stage.
// Edit: nothing.

import QtQuick
import ShotLab
QtObject {
    id: v
    default property Component delegate
    property var model: []
    property list<QtObject> instances
    Component.onCompleted: {
        var m = model || []
        var out = []
        for (var i = 0; i < m.length; i++) {
            var o = delegate.createObject(Shot.root, { modelData: m[i] })
            if (o) out.push(o); else console.warn("Variants: delegate failed")
        }
        instances = out
    }
}
