// The desktop under your windows, per monitor: the wallpaper and its widgets.
// Edit: layer and stacking here; the wallpaper in WallpaperView.qml, widgets in WidgetCanvas.qml.

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
        readonly property bool any: Desktop.onScreen(modelData.name, first).length > 0

        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "apsis-desktop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        readonly property bool widgetsShown: Settings.showWidgets && !EditMode.editing && any
        visible: Wall.drawn || widgetsShown

        WallpaperView {
            anchors.fill: parent
            visible: Wall.drawn
        }

        WidgetCanvas {
            anchors.fill: parent
            visible: win.widgetsShown
            screenName: win.modelData.name
            firstScreen: win.first
            editing: false
        }
    }
}
