// A Block that is a key: icon and label, hover tint, press spring; `active` lights it.
// Edit: padding and icon size here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../config"

Block {
    id: root

    property string icon: ""
    property string text: ""
    property string subText: ""
    property real iconSize: small ? 15 : 20
    property real fontSize: small ? 11 : 13
    property bool active: false
    property bool vertical: false
    property int align: Qt.AlignHCenter
    readonly property bool hovered: ma.containsMouse

    property color fillIdle: Theme.bgItem
    property color fillHover: Theme.bgHover
    property color fillActive: Theme.accent

    property color inkIdle: Theme.textPrimary
    readonly property color ink: active ? Theme.onAccent : inkIdle
    readonly property color inkSub: active ? Theme.alpha(Theme.onAccent, 0.75) : Theme.textSecondary

    signal clicked()
    signal rightClicked()

    fill: active ? fillActive : (hovered && enabled ? fillHover : fillIdle)
    ring: active ? Theme.ringActive : Theme.ring
    pressed: ma.pressed && enabled
    opacity: enabled ? 1 : 0.45

    GridLayout {
        id: lay
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: root.align === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.left: root.align === Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: 12
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rows: root.vertical ? 3 : 1
        columnSpacing: 8
        rowSpacing: 4

        VIcon {
            visible: root.icon !== ""
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            size: root.iconSize
            d: root.icon
            color: root.ink
        }
        ColumnLayout {
            visible: root.text !== "" || root.subText !== ""
            spacing: 0
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            Text {
                visible: root.text !== ""
                text: root.text
                color: root.ink
                font.family: Theme.fontText
                font.pixelSize: root.fontSize
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.maximumWidth: Math.max(20, root.keyWidth - (root.icon !== "" && !root.vertical ? root.iconSize + 40 : 16))
                Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignLeft
            }
            Text {
                visible: root.subText !== ""
                text: root.subText
                color: root.inkSub
                font.family: Theme.fontText
                font.pixelSize: root.fontSize - 2
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 7
                elide: Text.ElideRight
                Layout.maximumWidth: root.keyWidth - 60
                Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignLeft
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: function(mouse) {
            if (!root.enabled) return
            if (mouse.button === Qt.RightButton) root.rightClicked()
            else root.clicked()
        }
    }
}
