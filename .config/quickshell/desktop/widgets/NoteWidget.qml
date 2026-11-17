// Desktop widget: a sticky note that saves as you type; the tint key cycles its colour.
// Edit: tint list and font size here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    readonly property string tint: (widget.style && widget.style.tint) || "accent"
    readonly property var tints: ["accent", "cyan", "warn", "plain"]
    readonly property color tone: tint === "cyan" ? Theme.cyan : (tint === "warn" ? Theme.warn : (tint === "plain" ? Theme.bgItem : Theme.accent))
    readonly property color ink: tint === "plain" ? Theme.textPrimary : Theme.onAccent

    fill: tone
    ring: Theme.ringActive
    radius: 10

    Connections {
        target: root
        function onWidgetChanged() { if (!edit.activeFocus && edit.text !== (root.widget.text || "")) edit.text = root.widget.text || "" }
    }
    Component.onCompleted: edit.text = widget.text || ""
    Timer { id: saveLater; interval: 700; onTriggered: Desktop.setField(root.widget.id, "text", edit.text) }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -12
        width: 70
        height: 18
        rotation: -3
        radius: 2
        color: Theme.alpha(Theme.cream, 0.75)
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: 16
        contentHeight: edit.contentHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        TextEdit {
            id: edit
            width: flick.width
            wrapMode: TextEdit.Wrap
            color: root.ink
            selectionColor: Theme.bgMain
            font.family: Theme.fontText
            font.pixelSize: 13
            enabled: !root.editing
            onTextChanged: if (activeFocus) saveLater.restart()
            onActiveFocusChanged: if (!activeFocus && saveLater.running) { saveLater.stop(); Desktop.setField(root.widget.id, "text", text) }
        }
        Label { visible: edit.text === "" && !edit.activeFocus; text: "Write something"; color: Theme.alpha(root.ink, 0.6); font.pixelSize: 13 }
    }

    BlockButton {
        visible: root.editing
        small: true
        width: 64
        height: 28
        x: 8
        y: root.keyHeight - 40
        text: root.tint
        fontSize: 10
        onClicked: {
            var i = root.tints.indexOf(root.tint)
            Desktop.setStyle(root.widget.id, "tint", root.tints[(i + 1) % root.tints.length])
        }
    }
}
