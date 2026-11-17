// Stand-in for PanelWindow: an Item on the stage placed by its anchors and margins, stacked by layer and by when it showed.
// Edit: placement and stacking here.

import QtQuick
import ShotLab
QtObject {
    id: w
    default property list<QtObject> data
    property var screen: Shot.screen
    property PanelAnchors anchors: PanelAnchors {}
    property PanelMargins margins: PanelMargins {}
    property int exclusionMode: 0
    property int exclusiveZone: 0
    property int layer: 2
    property color color: "transparent"
    property var mask: null
    property real implicitWidth: 0
    property real implicitHeight: 0
    property bool visible: true
    property string title: ""
    readonly property real width: box.width
    readonly property real height: box.height
    readonly property Item contentItem: box
    readonly property real sw: screen ? screen.width : 1920
    readonly property real sh: screen ? screen.height : 1080
    property Item box: Item {
        parent: Shot.root
        visible: w.visible
        z: w.layer * 1000 + Shot.nextZ()
        onVisibleChanged: if (visible) z = w.layer * 1000 + Shot.nextZ()
        width: (w.anchors.left && w.anchors.right) ? w.sw - w.margins.left - w.margins.right : w.implicitWidth
        height: (w.anchors.top && w.anchors.bottom) ? w.sh - w.margins.top - w.margins.bottom : w.implicitHeight
        x: w.anchors.left ? w.margins.left : (w.anchors.right ? w.sw - width - w.margins.right : (w.sw - width) / 2)
        y: w.anchors.top ? w.margins.top : (w.anchors.bottom ? w.sh - height - w.margins.bottom : (w.sh - height) / 2)
        Rectangle { anchors.fill: parent; color: w.color }
    }
    Component.onCompleted: {
        for (var i = 0; i < data.length; i++) {
            var o = data[i]
            if (o instanceof Item) o.parent = box
        }
    }
}
