// The month card: turn months, see how far a day is, mark days with coloured dots.
// Edit: dot colours and cell size here; dates in lib/CalendarMath.js.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/CalendarMath.js" as CM

Block {
    id: root

    property bool active: true
    property var today: new Date()
    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    property string hoverKey: ""
    readonly property int weekStart: Qt.locale().firstDayOfWeek % 7
    readonly property bool thisMonth: !!today && year === today.getFullYear() && month === today.getMonth()
    readonly property string todayKey: today ? CM.key(today.getFullYear(), today.getMonth(), today.getDate()) : ""
    readonly property var cells: CM.grid(year, month, weekStart)
    readonly property var marks: store.data.marks || {}
    readonly property var markColors: [Theme.accent, Theme.cyan, Theme.warn]

    implicitWidth: 340
    implicitHeight: col.implicitHeight + 28 + 2 * inset + shadowDy
    fill: Theme.bgCard
    ring: Theme.ringActive

    onActiveChanged: if (active) { today = new Date(); year = today.getFullYear(); month = today.getMonth(); forceActiveFocus() }
    Component.onCompleted: forceActiveFocus()

    function turn(n) { var s = CM.shift(year, month, n); year = s.y; month = s.m }
    function mark(k, clear) {
        store.update(function(d) {
            if (!d.marks) d.marks = {}
            var cur = d.marks[k]
            if (clear || cur === root.markColors.length - 1) delete d.marks[k]
            else d.marks[k] = cur === undefined ? 0 : cur + 1
        })
    }

    JsonStore {
        id: store
        path: Config.stateDir + "/calendar.json"
        defaults: ({ version: 1, marks: {} })
    }

    focus: true
    Keys.onLeftPressed: turn(-1)
    Keys.onRightPressed: turn(1)
    Keys.onPressed: function(e) {
        if (e.key === Qt.Key_PageUp) { turn(-1); e.accepted = true }
        else if (e.key === Qt.Key_PageDown) { turn(1); e.accepted = true }
    }
    WheelHandler { onWheel: function(w) { root.turn(w.angleDelta.y > 0 ? -1 : 1) } }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label { text: Qt.locale().standaloneMonthName(root.month, Locale.LongFormat); font.pixelSize: 20; font.weight: Font.Black }
                Label { sub: true; text: root.year; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            BlockButton {
                visible: !root.thisMonth
                Layout.preferredWidth: 64
                Layout.preferredHeight: 34
                small: true
                text: "Today"
                fontSize: 11
                onClicked: { root.year = root.today.getFullYear(); root.month = root.today.getMonth() }
            }
            BlockButton { Layout.preferredWidth: 34; Layout.preferredHeight: 34; small: true; icon: Icons.chevronRight; iconSize: 16; rotation: 180; onClicked: root.turn(-1) }
            BlockButton { Layout.preferredWidth: 34; Layout.preferredHeight: 34; small: true; icon: Icons.chevronRight; iconSize: 16; onClicked: root.turn(1) }
        }

        Row {
            Layout.fillWidth: true
            Repeater {
                model: CM.weekdays(root.weekStart)
                Label {
                    required property int modelData
                    width: col.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    caps: true
                    text: Qt.locale().dayName(modelData, Locale.ShortFormat).substring(0, 2)
                    color: Qt.locale().weekDays.indexOf(modelData) < 0 ? Theme.accent : Theme.textSecondary
                }
            }
        }

        Grid {
            id: days
            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            readonly property real cw: col.width / 7
            Repeater {
                model: root.cells
                Item {
                    id: cell
                    required property var modelData
                    width: days.cw
                    height: 38
                    readonly property bool isToday: modelData.key === root.todayKey
                    readonly property var mk: root.marks[modelData.key]
                    Block {
                        anchors.centerIn: parent
                        width: 38
                        height: 36
                        small: true
                        radius: 10
                        flat: !cell.isToday
                        bare: !cell.isToday && !ma.containsMouse
                        fill: cell.isToday ? Theme.accent : Theme.bgHover
                        ring: cell.isToday ? Theme.ringActive : Theme.ring
                        pressed: ma.pressed
                        Label {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: cell.mk !== undefined ? -3 : 0
                            text: cell.modelData.d
                            font.pixelSize: 12
                            font.weight: cell.isToday ? Font.Black : Font.Medium
                            color: cell.isToday ? Theme.onAccent : (cell.modelData.inMonth ? Theme.textPrimary : Theme.alpha(Theme.textSecondary, 0.5))
                        }
                        Rectangle {
                            visible: cell.mk !== undefined
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            width: 6; height: 6; radius: 3
                            color: cell.isToday ? Theme.onAccent : root.markColors[cell.mk || 0]
                        }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: if (containsMouse) root.hoverKey = cell.modelData.key; else if (root.hoverKey === cell.modelData.key) root.hoverKey = ""
                        onClicked: function(m) {
                            if (!cell.modelData.inMonth) { root.year = cell.modelData.y; root.month = cell.modelData.m; return }
                            root.mark(cell.modelData.key, m.button === Qt.RightButton)
                        }
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            sub: true
            font.pixelSize: 11
            text: {
                if (root.hoverKey !== "") {
                    var p = root.hoverKey.split("-")
                    var d = new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
                    var n = CM.between(root.today, d)
                    return Qt.formatDate(d, "dddd d MMMM") + "  /  " + CM.relative(n)
                }
                if (!root.thisMonth) {
                    var first = new Date(root.year, root.month, 1)
                    var away = CM.between(root.today, first)
                    return away > 0 ? "Starts " + CM.relative(away) : "Week " + CM.isoWeek(first) + " onward"
                }
                var left = CM.daysIn(root.year, root.month) - root.today.getDate()
                return "Week " + CM.isoWeek(root.today) + "  /  " + left + (left === 1 ? " day" : " days") + " left in " + Qt.locale().standaloneMonthName(root.month, Locale.LongFormat)
            }
        }
    }
}
