// Edit Desktop's window on every monitor, above everything (SUPER + SHIFT + E).
// Edit: what it draws is EditView.qml; this only places the window.

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"
import "../services"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        readonly property bool first: Quickshell.screens.length > 0 && Quickshell.screens[0].name === modelData.name

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "apsis-edit"
        WlrLayershell.keyboardFocus: EditMode.editing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: EditMode.editing

        EditView {
            id: view
            anchors.fill: parent
            screenName: win.modelData.name
            firstScreen: win.first
            focus: true
            Keys.onEscapePressed: EditMode.exit()
        }
        onVisibleChanged: if (visible) view.forceActiveFocus()
    }
}
