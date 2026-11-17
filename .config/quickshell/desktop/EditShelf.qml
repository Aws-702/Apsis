// The tray at the bottom of Edit Desktop: add widgets, presets, grid on or off, Done.
// Edit: tabs and key sizes here; widget list comes from lib/WidgetTypes.js; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"
import "../lib/WidgetTypes.js" as Types

Block {
    id: root
    property string screenName: ""
    property bool firstScreen: false
    property real roomW: 1920
    property real roomH: 1080

    fill: Theme.bgCard
    radius: 22
    implicitHeight: 92 + 8 + slider.implicitHeight + 24 + 2 * inset + shadowDy

    readonly property var iconFor: ({
        clock: Icons.clock, calendar: Icons.calendar, weather: Icons.cloud, media: Icons.music,
        todo: Icons.listCheck, note: Icons.note, stats: Icons.memory, visualizer: Icons.volHigh,
        lyrics: Icons.mic, events: Icons.bell, image: Icons.image, palette: Icons.theme, user: Icons.account
    })

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 14

        ColumnLayout {
            Layout.preferredWidth: 130
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 8
            BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 40; small: true; icon: Icons.plus; text: "Widgets"; fontSize: 12; active: EditMode.tab === "widgets"; onClicked: EditMode.tab = "widgets" }
            BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 40; small: true; icon: Icons.layers; text: "Presets"; fontSize: 12; active: EditMode.tab === "presets"; onClicked: EditMode.tab = "presets" }
            Item { Layout.fillHeight: true }
        }

        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 2; radius: 1; color: Theme.outline }

        ColumnLayout {
            visible: EditMode.tab === "widgets"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 92

                Flickable {
                    id: tray
                    anchors.fill: parent
                    clip: true
                    contentWidth: trayRow.implicitWidth
                    contentHeight: height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    Behavior on contentX { enabled: !slider.dragging && !tray.dragging; NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }

                    Row {
                        id: trayRow
                        spacing: 10
                        Repeater {
                            model: Types.ORDER
                            BlockButton {
                                required property string modelData
                                width: 92
                                height: 92
                                vertical: true
                                icon: root.iconFor[modelData] || Icons.apps
                                iconSize: 26
                                text: Types.TYPES[modelData].title
                                fontSize: 11
                                onClicked: Desktop.add(modelData, root.screenName, root.roomW, root.roomH, root.firstScreen)
                            }
                        }
                    }
                }

                Rectangle {
                    width: 28
                    height: parent.height
                    opacity: tray.contentX > 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.bgCard }
                        GradientStop { position: 1; color: Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0) }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    width: 28
                    height: parent.height
                    opacity: tray.contentX < slider.span - 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0) }
                        GradientStop { position: 1; color: Theme.bgCard }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: function(w) { slider.nudge(slider.wheelBy(w)) }
                }
            }

            BlockScroller {
                id: slider
                Layout.fillWidth: true
                flick: tray
            }
        }

        ColumnLayout {
            visible: EditMode.tab === "presets"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Block {
                    Layout.preferredWidth: 260
                    Layout.preferredHeight: 40
                    small: true
                    fill: Theme.bgMain
                    ring: nameField.activeFocus ? Theme.ringActive : Theme.ring
                    TextInput {
                        id: nameField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontText
                        font.pixelSize: 12
                        maximumLength: 40
                        clip: true
                        onAccepted: if (Desktop.savePreset(text)) text = ""
                        Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Name this look"; visible: nameField.text === "" }
                    }
                }
                BlockButton { small: true; Layout.preferredWidth: 96; Layout.preferredHeight: 40; icon: Icons.save; text: "Save"; fontSize: 11
                    active: nameField.text.trim() !== ""; onClicked: if (Desktop.savePreset(nameField.text)) nameField.text = "" }
                Item { Layout.fillWidth: true }
            }
            Flow {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                Repeater {
                    model: Desktop.presetNames
                    BlockButton {
                        required property string modelData
                        small: true
                        width: 150
                        height: 38
                        text: modelData
                        fontSize: 11
                        onClicked: Desktop.applyPreset(modelData)
                        onRightClicked: Desktop.deletePreset(modelData)
                    }
                }
                Label { visible: Desktop.presetNames.length === 0; sub: true; text: "No presets yet. Click to wear one, right click to delete."; font.pixelSize: 11 }
            }
        }

        Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 2; radius: 1; color: Theme.outline }

        ColumnLayout {
            Layout.preferredWidth: 120
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 8
            BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 40; small: true; text: Settings.gridSnap ? "Snap on" : "Snap off"; fontSize: 11; active: Settings.gridSnap; onClicked: Settings.toggle("gridSnap") }
            BlockButton { Layout.fillWidth: true; Layout.fillHeight: true; icon: Icons.check; text: "Done"; fontSize: 13; active: true; onClicked: EditMode.exit() }
        }
    }
}
