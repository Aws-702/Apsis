// Desktop widget: upcoming events you type in ("2026-11-03 Dentist", "+3 Call back").
// Edit: how many show and row size here; date parsing in lib/Events.js; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/Events.js" as Ev

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    property date now: new Date()
    Timer { interval: 600000; running: true; repeat: true; onTriggered: root.now = new Date() }
    readonly property var events: widget.events || []
    readonly property var next: Ev.upcoming(events, now, 5)

    function add(line) {
        var e = Ev.parseLine(line, new Date())
        if (!e) { hint.text = "Try: 2026-11-03 Dentist, 11-03 Birthday or +3 Call back"; return false }
        var list = events.slice()
        list.push(e)
        Desktop.setField(widget.id, "events", list)
        hint.text = ""
        return true
    }
    function removeAt(i) {
        var list = events.slice()
        list.splice(i, 1)
        Desktop.setField(widget.id, "events", list)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 6
        Label { caps: true; text: "Coming up" }
        Repeater {
            model: root.next
            RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                spacing: 8
                Block {
                    small: true; radius: 7
                    Layout.preferredWidth: 46; Layout.preferredHeight: 24
                    fill: row.modelData.days === 0 ? Theme.accent : Theme.bgItem
                    Label { anchors.centerIn: parent; text: row.modelData.date.slice(5); font.pixelSize: 10; font.weight: Font.DemiBold
                        color: row.modelData.days === 0 ? Theme.onAccent : Theme.textPrimary }
                }
                Label { Layout.fillWidth: true; text: row.modelData.text; font.pixelSize: 12; elide: Text.ElideRight }
                Label { sub: true; text: Ev.when(row.modelData.days); font.pixelSize: 10 }
                MouseArea {
                    Layout.preferredWidth: 14; Layout.preferredHeight: 20
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeAt(row.modelData.index)
                    Label { anchors.centerIn: parent; text: "x"; sub: true; font.pixelSize: 11 }
                }
            }
        }
        Label { visible: root.next.length === 0; sub: true; font.pixelSize: 12; text: "Nothing coming up" }
        Item { Layout.fillHeight: true }
        Label { id: hint; Layout.fillWidth: true; sub: true; font.pixelSize: 9; wrapMode: Text.WordWrap; visible: text !== ""; color: Theme.warn }
        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            small: true
            fill: Theme.bgMain
            ring: input.activeFocus ? Theme.ringActive : Theme.ring
            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                font.family: Theme.fontText
                font.pixelSize: 12
                clip: true
                enabled: !root.editing
                maximumLength: 80
                onAccepted: if (root.add(text)) text = ""
                Label { anchors.verticalCenter: parent.verticalCenter; sub: true; font.pixelSize: 12; visible: input.text === ""; text: "Add: 11-03 Birthday" }
            }
        }
    }
}
