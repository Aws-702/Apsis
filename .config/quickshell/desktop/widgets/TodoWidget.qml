// Desktop widget: a to-do list; click to tick, right click to delete, type and Enter to add.
// Edit: row size and how many fit here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    readonly property var items: widget.items || []
    readonly property int remaining: items.filter(function(i) { return !i.done }).length

    function save(arr) { Desktop.setField(widget.id, "items", arr) }
    function add(t) {
        t = String(t).trim()
        if (!t.length) return
        var a = items.slice(); a.push({ t: t, done: false }); save(a)
    }
    function toggle(i) { var a = JSON.parse(JSON.stringify(items)); a[i].done = !a[i].done; save(a) }
    function remove(i) { var a = items.slice(); a.splice(i, 1); save(a) }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            VIcon { size: 16; d: Icons.listCheck; color: Theme.accent }
            Label { text: "To-do"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
            Block { small: true; flat: true; Layout.preferredWidth: 34; Layout.preferredHeight: 22; radius: 11; fill: root.remaining ? Theme.accent : Theme.bgHover
                Label { anchors.centerIn: parent; text: root.remaining; font.pixelSize: 10; font.weight: Font.Black; color: root.remaining ? Theme.onAccent : Theme.textSecondary } }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: root.items
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                id: it
                required property var modelData
                required property int index
                width: ListView.view.width
                height: 28
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    BlockButton {
                        small: true
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 25
                        radius: 7
                        active: it.modelData.done
                        icon: it.modelData.done ? Icons.check : ""
                        iconSize: 13
                        onClicked: root.toggle(it.index)
                    }
                    Label {
                        Layout.fillWidth: true
                        text: it.modelData.t
                        font.pixelSize: 12
                        font.strikeout: it.modelData.done
                        color: it.modelData.done ? Theme.textSecondary : Theme.textPrimary
                        MouseArea { anchors.fill: parent; acceptedButtons: Qt.RightButton; onClicked: root.remove(it.index) }
                    }
                }
            }
            Label { anchors.centerIn: parent; visible: root.items.length === 0; sub: true; text: "Nothing to do"; font.pixelSize: 11 }
        }

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            small: true
            fill: Theme.bgMain
            ring: field.activeFocus ? Theme.ringActive : Theme.ring
            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                font.family: Theme.fontText
                font.pixelSize: 12
                clip: true
                enabled: !root.editing
                onAccepted: { root.add(text); text = "" }
                Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Add a task"; visible: field.text === ""; font.pixelSize: 12 }
            }
        }
    }
}
