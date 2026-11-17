// Edit Desktop state: on or off, the shelf tab, and the snap guides while dragging.
// Edit: nothing visual here; the guides are drawn by desktop/EditView.qml.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool editing: false
    property string tab: "widgets"
    property string dragging: ""
    property string dragScreen: ""
    property var guides: []

    function toggle() { editing ? exit() : enter() }
    function enter() { root.editing = true }
    function exit() {
        root.editing = false
        root.dragging = ""
        root.guides = []
    }
}
