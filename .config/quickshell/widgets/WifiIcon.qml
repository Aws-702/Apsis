// A drawn Wi-Fi icon: three arcs over a dot.
// Edit: the arcs here.

import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property color color: "white"
    property real  size: 16
    width: size
    height: size

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        antialiasing: true
        transform: Scale {
            origin.x: 12; origin.y: 12
            xScale: root.size / 24
            yScale: root.size / 24
        }

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: 2.1
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                moveToStart: true
                centerX: 12; centerY: 18.5
                radiusX: 10; radiusY: 10
                startAngle: -142; sweepAngle: 104
            }
        }

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: 2.1
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                moveToStart: true
                centerX: 12; centerY: 18.5
                radiusX: 6.2; radiusY: 6.2
                startAngle: -138; sweepAngle: 96
            }
        }

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: 2.1
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                moveToStart: true
                centerX: 12; centerY: 18.5
                radiusX: 2.6; radiusY: 2.6
                startAngle: -132; sweepAngle: 84
            }
        }
    }

    Rectangle {
        width: root.size * (3.0 / 24)
        height: width
        radius: width / 2
        color: root.color
        x: root.size / 2 - width / 2
        y: root.size * (18.5 / 24) - height / 2
    }
}
