// Desktop widget: the colours the shell uses now; click one to copy its hex.
// Edit: which roles show and swatch size here; the colours themselves in config/Theme.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    property string copied: ""
    Timer { id: clear; interval: 1400; onTriggered: root.copied = "" }
    function hex(c) {
        function h(v) { var s = Math.round(v * 255).toString(16); return s.length < 2 ? "0" + s : s }
        return ("#" + h(c.r) + h(c.g) + h(c.b)).toUpperCase()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Label { caps: true; text: "Palette"; Layout.fillWidth: true }
            Label { sub: true; font.pixelSize: 10; text: root.copied !== "" ? "Copied " + root.copied : Theme.palette + " / " + Theme.mode }
        }
        Row {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            Repeater {
                model: [
                    { c: Theme.bgMain }, { c: Theme.bgCard }, { c: Theme.bgItem },
                    { c: Theme.accent }, { c: Theme.accentHot }, { c: Theme.cyan },
                    { c: Theme.warn }, { c: Theme.danger }, { c: Theme.textPrimary }
                ]
                Rectangle {
                    id: sw
                    required property var modelData
                    width: (root.width - 28 - 6 * 8) / 9
                    height: parent.height
                    radius: 8
                    color: modelData.c
                    border.width: 2
                    border.color: Theme.line
                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.editing
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var h = root.hex(sw.modelData.c)
                            Quickshell.execDetached(["wl-copy", h])
                            root.copied = h
                            clear.restart()
                        }
                    }
                }
            }
        }
    }
}
