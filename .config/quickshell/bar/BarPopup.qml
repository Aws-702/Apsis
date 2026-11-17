// The window the bar's cards drop into (battery, calendar, privacy, GPU), under the key that opened it.
// Edit: gap and card width here; the cards in bar/cards/.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"
import "cards"

PanelWindow {
    id: win

    readonly property bool open: UiState.barPopup !== ""

    property string showing: ""
    Connections {
        target: UiState
        function onBarPopupChanged() { if (UiState.barPopup !== "") win.showing = UiState.barPopup }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-barpopup"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || !pop.settled

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: UiState.barPopup = ""
    }

    Item {
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: UiState.barPopup = ""

        Pop {
            id: pop
            shown: win.open
            transformOrigin: Settings.barAtBottom ? Item.Bottom : Item.Top
            width: card.item ? card.item.implicitWidth : 0
            height: card.item ? card.item.implicitHeight : 0
            x: Math.max(8, Math.min(win.width - width - 8, UiState.barPopupX - width / 2))
            y: Settings.barAtBottom ? win.height - Settings.barSpace - height - 6 : Settings.barSpace + 6

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }

            Loader {
                id: card
                sourceComponent: ({ battery: batteryC, calendar: calendarC, privacy: privacyC, gpu: gpuC })[win.showing] || null
            }
        }
    }

    Component { id: batteryC; BatteryCard {} }
    Component { id: calendarC; CalendarCard { active: win.open } }
    Component { id: privacyC; PrivacyCard {} }
    Component { id: gpuC; GpuCard {} }
}
