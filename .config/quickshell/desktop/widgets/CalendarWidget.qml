// Desktop widget: this month, today as a lit keycap; the wheel moves between months.
// Edit: cell size and spacing here; dates in lib/CalendarMath.js; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    property date now: new Date()
    property int offset: 0
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.now = new Date() }

    readonly property date shown: new Date(now.getFullYear(), now.getMonth() + offset, 1)
    readonly property bool thisMonth: offset === 0
    function cells() {
        var y = shown.getFullYear(), m = shown.getMonth()
        var first = (new Date(y, m, 1).getDay() + 6) % 7
        var days = new Date(y, m + 1, 0).getDate()
        var a = []
        for (var i = 0; i < first; i++) a.push(0)
        for (var d = 1; d <= days; d++) a.push(d)
        return a
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Label { text: Qt.formatDate(root.shown, "MMMM yyyy"); font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
            Label { sub: true; visible: !root.thisMonth; text: "today"; font.pixelSize: 10
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.offset = 0 } }
        }
        Grid {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            rowSpacing: 3
            columnSpacing: 3
            Repeater {
                model: ["M", "T", "W", "T", "F", "S", "S"]
                Label { required property string modelData; width: 30; horizontalAlignment: Text.AlignHCenter; caps: true; text: modelData; font.pixelSize: 9 }
            }
            Repeater {
                model: root.cells()
                Item {
                    id: day
                    required property int modelData
                    readonly property bool today: root.thisMonth && modelData === root.now.getDate()
                    width: 30
                    height: 26
                    Block {
                        visible: day.today
                        anchors.fill: parent
                        small: true
                        radius: 8
                        fill: Theme.accent
                        ring: Theme.ringActive
                    }
                    Label {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: day.today ? -1 : 0
                        text: day.modelData > 0 ? day.modelData : ""
                        font.pixelSize: 11
                        font.weight: day.today ? Font.Black : Font.Normal
                        color: day.today ? Theme.onAccent : Theme.textPrimary
                    }
                }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        enabled: !root.editing
        acceptedButtons: Qt.NoButton
        onWheel: function(w) { root.offset += w.angleDelta.y > 0 ? -1 : 1 }
    }
}
