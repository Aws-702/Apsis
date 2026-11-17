// The 1920x1080 stage every shot is drawn on; loads the scene that shot.py names.
// Edit: the stage size here and in shot.py (Shot.screen).

import QtQuick
import ShotLab
Item {
    id: stage
    width: 1920
    height: 1080
    Rectangle { anchors.fill: parent; color: "#101010" }
    Loader { id: loader; anchors.fill: parent }
    Component.onCompleted: { Shot.root = stage; loader.source = Shot.scene }
}
