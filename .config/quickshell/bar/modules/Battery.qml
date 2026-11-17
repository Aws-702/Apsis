// Bar key: battery level and charging; warns at 20, 10 and 5 percent; click for the battery card.
// Edit: the low threshold and look here; warning levels in lib/BatteryMath.js; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Shapes
import "../../config"
import "../../widgets"
import "../../services"
import "../../lib/BatteryMath.js" as BM

Block {
    id: root
    small: true
    radius: 10
    implicitWidth: brow.implicitWidth + 18
    Layout.fillHeight: true
    implicitHeight: 29
    fill: Theme.bgItem

    property int    pct: 0
    property string status: ""
    readonly property bool  charging: status === "Charging"
    readonly property bool  low: pct <= 15 && !charging
    readonly property color battColor: low ? Theme.danger : Theme.accent

    property int warned: 101
    property bool seen: false
    function checkLow() {
        if (!seen) return
        var r = BM.lowAlert(pct, charging || status === "Full", warned)
        warned = r.warned
        if (!r.level) return
        var critical = r.level <= 10
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", critical ? "critical" : "normal",
            "-i", critical ? "battery-caution" : "battery-low",
            "Battery at " + pct + "%", critical ? "Plug in now: the laptop will sleep soon." : "Time to find the charger."])
    }

    Poll {
        interval: 5000
        command: ["sh", "-c",
            "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n \"$b\" ] && echo \"$(cat $b/capacity 2>/dev/null) $(cat $b/status 2>/dev/null)\""]
        onUpdated: function(out) {
            var p = out.trim().split(" ")
            root.pct = parseInt(p[0]) || 0
            root.status = p[1] || ""
            root.seen = p[0] !== ""
            root.checkLow()
        }
    }

    RowLayout {
        id: brow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 24
            height: 14
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: body
                width: 20
                height: 11
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: "transparent"
                border.width: 1.5
                border.color: root.battColor
            }

            Rectangle {
                width: 2.5
                height: 5
                radius: 1
                anchors.left: body.right
                anchors.leftMargin: 0.5
                anchors.verticalCenter: body.verticalCenter
                color: root.battColor
            }

            Rectangle {
                id: fill
                anchors.left: body.left
                anchors.top: body.top
                anchors.bottom: body.bottom
                anchors.leftMargin: body.border.width
                anchors.topMargin: body.border.width
                anchors.bottomMargin: body.border.width
                width: Math.max(0, (body.width - body.border.width * 2) * root.pct / 100)
                radius: 1.5
                color: root.battColor
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }

            Item {
                id: boltWrap
                visible: root.charging
                anchors.centerIn: body
                width: 24
                height: 24
                property real slide: 0
                opacity: 0
                transform: [
                    Scale { origin.x: 12; origin.y: 12; xScale: 8 / 24; yScale: 8 / 24 },
                    Rotation { origin.x: 12; origin.y: 12; angle: 90 },
                    Translate { x: boltWrap.slide }
                ]

                Shape {
                    anchors.fill: parent
                    antialiasing: true
                    ShapePath {
                        fillColor: Theme.textPrimary
                        strokeColor: Theme.bgMain
                        strokeWidth: 1
                        PathSvg { path: "M11,4L4,14H10L9,20L16,10H10L11,4Z" }
                    }
                }

                SequentialAnimation {
                    running: root.charging
                    loops: Animation.Infinite
                    ParallelAnimation {
                        NumberAnimation { target: boltWrap; property: "slide"; from: -6; to: 6; duration: 950; easing.type: Easing.InOutSine }
                        SequentialAnimation {
                            NumberAnimation { target: boltWrap; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutSine }
                            NumberAnimation { target: boltWrap; property: "opacity"; from: 1; to: 0; duration: 650; easing.type: Easing.InSine }
                        }
                    }
                    PauseAnimation { duration: 150 }
                }
            }
        }

        Text {
            text: root.pct + "%"
            font.family: Theme.fontText
            font.pixelSize: 12
            color: Theme.textPrimary
        }
    }

    pressed: battArea.pressed
    MouseArea {
        id: battArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleBarPopup("battery", root.mapToItem(null, root.width / 2, 0).x)
    }
}
