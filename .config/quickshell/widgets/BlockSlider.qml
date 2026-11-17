// A slider of blocks: recessed track, accent fill, keycap knob; value 0 to 100.
// Edit: track height and knob size here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root
    property real value: 0
    property string icon: ""
    property string label: ""
    property bool dragging: ma.pressed
    property real _drag: 0
    readonly property real shown: dragging ? _drag : value

    signal moved(real v)
    signal released(real v)
    signal iconClicked()

    property bool more: false

    property string valueText: ""
    signal moreClicked()

    implicitWidth: 260
    implicitHeight: 44

    RowLayout {
        anchors.fill: parent
        spacing: 10

        BlockButton {
            visible: root.icon !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            icon: root.icon
            iconSize: 18
            onClicked: root.iconClicked()
        }

        Item {
            id: trackBox
            Layout.fillWidth: true
            Layout.fillHeight: true

            Block {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 22
                radius: 11
                small: true
                flat: true
                fill: Theme.bgMain

                Rectangle {
                    height: parent.height
                    radius: height / 2
                    width: Math.max(height, parent.width * Math.max(0, Math.min(100, root.shown)) / 100)
                    color: Theme.accent
                    Behavior on width { enabled: !root.dragging; NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }
                }
            }

            Block {
                id: knob
                small: true
                width: 26
                height: 26 + Theme.shadowOffsetSm
                radius: 13
                y: (parent.height - 26) / 2 - 1
                x: Math.max(0, Math.min(trackBox.width - 26, (trackBox.width - 26) * root.shown / 100))
                fill: Theme.bgCard
                pressed: ma.pressed
                Behavior on x { enabled: !root.dragging; NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function at(mx) { return Math.round(Math.max(0, Math.min(100, (mx - 13) / Math.max(1, width - 26) * 100))) }
                onPressed: function(m) { root._drag = at(m.x); root.moved(root._drag) }
                onPositionChanged: function(m) { if (pressed) { root._drag = at(m.x); root.moved(root._drag) } }
                onReleased: root.released(root._drag)
                onWheel: function(w) {
                    var v = Math.max(0, Math.min(100, root.value + (w.angleDelta.y > 0 ? 5 : -5)))
                    root.released(v)
                }
            }
        }

        Text {
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: root.valueText !== "" ? root.valueText : Math.round(root.shown) + "%"
            color: Theme.textPrimary
            font.family: Theme.fontText
            font.pixelSize: 12
        }

        BlockButton {
            visible: root.more
            Layout.preferredWidth: 32
            Layout.preferredHeight: 40
            small: true
            icon: Icons.chevronRight
            iconSize: 16
            onClicked: root.moreClicked()
        }
    }
}
