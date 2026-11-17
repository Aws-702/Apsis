// Draws one icon from services/Icons.qml path data at any size.
// Edit: size and color where it's used; the shapes in services/Icons.qml.

import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string d: ""
    property color color: "white"
    property real size: 16
    width: size
    height: size

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        antialiasing: true

        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            origin.x: 12; origin.y: 12
            xScale: root.size / 24
            yScale: root.size / 24
        }
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"
            PathSvg { path: root.d }
        }
    }
}
