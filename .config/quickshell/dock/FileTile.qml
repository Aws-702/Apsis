// One file on a dock card: thumbnail or icon and its name; click opens, drag out, right click acts.
// Edit: tile size and thumbnail radius here.

import QtQuick
import Quickshell
import "../config"
import "../services"
import "../widgets"

Item {
    id: root
    property string path: ""
    signal secondary()

    readonly property string name: path.substring(path.lastIndexOf("/") + 1)
    readonly property bool picture: /\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(path)
    readonly property string ext: (name.lastIndexOf(".") > 0 ? name.substring(name.lastIndexOf(".") + 1) : "file").toUpperCase()

    width: 78
    height: 92

    Block {
        id: key
        anchors.horizontalCenter: parent.horizontalCenter
        width: 66
        height: 64
        small: true
        fill: Theme.bgItem
        ring: ma.containsMouse ? Theme.ringActive : Theme.ring
        pressed: ma.pressed && !ma.drag.active
        RoundImage {
            id: thumb
            anchors.fill: parent
            radius: Math.max(0, key.radius - key.inset)
            visible: root.picture && status === Image.Ready
            source: root.picture ? "file://" + root.path : ""
            sourceSize.width: 132
            sourceSize.height: 128
        }
        Label {
            anchors.centerIn: parent
            visible: !thumb.visible
            text: root.ext.substring(0, 4)
            font.pixelSize: 12
            font.weight: Font.Black
            color: Theme.accent
        }
    }
    Label {
        anchors.top: key.bottom
        anchors.topMargin: 4
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        font.pixelSize: 9
        sub: true
        text: root.name
    }

    Item {
        id: carrier
        width: key.width
        height: key.height
        Drag.active: ma.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: ({ "text/uri-list": "file://" + encodeURI(root.path) + "\r\n" })
    }

    MouseArea {
        id: ma
        anchors.fill: key
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        drag.target: carrier
        onClicked: function(m) {
            if (m.button === Qt.RightButton) root.secondary()
            else Quickshell.execDetached(["xdg-open", root.path])
        }
        onReleased: { carrier.x = 0; carrier.y = 0 }
    }
}
