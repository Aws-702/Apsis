// A settings line: title, optional hint and a control on the right.
// Edit: text sizes and row height here.

import QtQuick
import QtQuick.Layouts
import "../config"

Block {
    id: root
    property string title: ""
    property string hint: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: hint === "" ? 54 : 64
    small: true
    fill: Theme.bgItem

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 12
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label { text: root.title; font.pixelSize: 13; Layout.fillWidth: true }
            Label { sub: true; text: root.hint; visible: root.hint !== ""; font.pixelSize: 10; Layout.fillWidth: true }
        }
        Item {
            id: slot
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }
    }
}
