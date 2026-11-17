// The dock's window on each monitor: autohide, the edge it sits on, stepping aside for the phone.
// Edit: hide delay, edge offset and size here; the tray itself is DockView.qml.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        readonly property bool enabledHere: Settings.dockEnabled && !Dock.forcedHidden
        readonly property bool autohide: Settings.dockAutohide
        readonly property string edge: Settings.dockEdge
        readonly property bool vertical: edge !== "bottom"
        readonly property bool blocked: PhoneState.open || EditMode.editing
        property bool hovered: false

        readonly property bool carding: Dock.card !== "" && modelData.name === Dock.cardScreen
        readonly property bool up: enabledHere && !blocked && (!autohide || hovered || carding || Dock.held)
        readonly property real cardRoom: carding || !cardPop.settled ? card.implicitHeight + 14 : 0

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "apsis-dock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.bottom: edge === "bottom"
        anchors.left: edge === "left"
        anchors.right: edge === "right"

        margins.bottom: (edge === "bottom" && Settings.barAtBottom && !Sys.barHidden) ? Settings.barSpace : 0
        exclusiveZone: (enabledHere && !autohide) ? (vertical ? view.implicitWidth + 10 : view.implicitHeight + 10) : 0
        implicitWidth: vertical ? view.implicitWidth + 24 + cardRoom : Math.max(view.implicitWidth + 40, 200, card.implicitWidth + 40)
        implicitHeight: vertical ? Math.max(view.implicitHeight + 40, 200, card.implicitHeight + 40) : view.implicitHeight + 24 + cardRoom
        color: "transparent"
        visible: enabledHere

        mask: up ? fullRegion : stripRegion
        Region { id: fullRegion; item: hoverArea }
        Region { id: stripRegion; item: strip }

        Item {
            id: strip
            anchors.bottom: win.edge === "bottom" ? parent.bottom : undefined
            anchors.left: win.edge === "left" ? parent.left : undefined
            anchors.right: win.edge === "right" ? parent.right : undefined
            anchors.horizontalCenter: win.vertical ? undefined : parent.horizontalCenter
            anchors.verticalCenter: win.vertical ? parent.verticalCenter : undefined
            width: win.vertical ? 3 : view.implicitWidth
            height: win.vertical ? view.implicitHeight : 3
        }

        Item {
            id: hoverArea
            anchors.fill: parent
            DockView {
                id: view
                screenName: win.modelData.name
                width: implicitWidth
                height: implicitHeight

                y: win.vertical ? (parent.height - height) / 2 : (win.up ? 8 + win.cardRoom : win.implicitHeight + 6)
                x: !win.vertical ? (parent.width - width) / 2
                   : win.edge === "left" ? (win.up ? 8 : -(width + 6))
                   : (win.up ? win.implicitWidth - width - 8 : win.implicitWidth + 6)
                Behavior on x {
                    enabled: win.vertical
                    NumberAnimation {
                        duration: win.up ? Motion.riseMs : Motion.sinkMs
                        easing.type: win.up ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: Motion.riseOvershoot
                    }
                }
                Behavior on y {
                    enabled: !win.vertical
                    NumberAnimation {
                        duration: win.up ? Motion.riseMs : Motion.sinkMs
                        easing.type: win.up ? Easing.OutBack : Easing.InCubic
                        easing.overshoot: Motion.riseOvershoot
                    }
                }
            }

            Pop {
                id: cardPop
                shown: win.carding
                transformOrigin: win.edge === "left" ? Item.Left : (win.edge === "right" ? Item.Right : Item.Bottom)

                x: win.edge === "left" ? view.implicitWidth + 16 : (win.edge === "right" ? 4 : (parent.width - width) / 2)
                y: win.vertical ? (parent.height - height) / 2 : 4
                width: card.implicitWidth
                height: card.implicitHeight
                DockCard { id: card; anchors.fill: parent }
            }
            HoverHandler {
                onHoveredChanged: {
                    if (hovered) { hideLater.stop(); closeCard.stop(); win.hovered = true }
                    else { hideLater.restart(); if (win.carding) closeCard.restart() }
                }
            }
        }
        Timer { id: hideLater; interval: 650; onTriggered: win.hovered = false }

        Timer { id: closeCard; interval: 1100; onTriggered: if (win.carding) Dock.card = "" }
        onCardingChanged: if (carding && !hovered) closeCard.restart()

    }
}
