// Desktop widget: the time with each digit on its own keycap, the date underneath.
// Edit: digit size and time format here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Item {
    id: root
    property var widget: ({})
    property bool editing: false
    readonly property var style: widget.style || {}
    readonly property bool h24: style.h24 !== false
    readonly property bool seconds: style.seconds === true

    property date now: new Date()
    Timer { interval: root.seconds ? 1000 : 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    readonly property string hhmm: Qt.formatTime(now, h24 ? "HH:mm" : "hh:mm")
    readonly property string ss: Qt.formatTime(now, "ss")

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 7
            Repeater {
                model: root.hhmm.split("")
                Item {
                    id: cell
                    required property string modelData
                    readonly property bool colon: modelData === ":"
                    Layout.preferredWidth: colon ? 18 : 62
                    Layout.preferredHeight: 92
                    Column {
                        visible: cell.colon
                        anchors.centerIn: parent
                        spacing: 14
                        Repeater { model: 2; Block { width: 14; height: 17; radius: 5; small: true; fill: Theme.accent; ring: Theme.ringActive } }
                    }
                    Block {
                        visible: !cell.colon
                        anchors.fill: parent
                        radius: 16
                        fill: Theme.bgCard
                        Label {
                            anchors.centerIn: parent
                            text: cell.modelData
                            font.pixelSize: 54
                            font.weight: Font.Black
                        }
                    }
                }
            }
            Block {
                visible: root.seconds
                Layout.preferredWidth: 40
                Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignBottom
                small: true
                fill: Theme.accent
                ring: Theme.ringActive
                Label { anchors.centerIn: parent; text: root.ss; color: Theme.onAccent; font.pixelSize: 16; font.weight: Font.Black }
            }
        }

        Block {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: dateLabel.implicitWidth + 34
            Layout.preferredHeight: 34
            small: true
            radius: 17
            fill: Theme.accent
            ring: Theme.ringActive
            Label {
                id: dateLabel
                anchors.centerIn: parent
                text: Qt.formatDate(root.now, "dddd  d MMMM")
                color: Theme.onAccent
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }
    }
}
