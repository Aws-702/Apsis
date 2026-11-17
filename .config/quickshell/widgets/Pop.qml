// Pops its content in and swallows it on the way out; flip `shown`.
// Edit: the timings in config/Motion.qml (popInMs, popOutMs, popFrom).

import QtQuick
import "../config"

Item {
    id: root
    property bool shown: false
    readonly property bool settled: !inAnim.running && !outAnim.running
    property real fromScale: Motion.popFrom

    visible: shown || outAnim.running
    scale: fromScale
    opacity: 0

    onShownChanged: {
        if (shown) { outAnim.stop(); inAnim.restart() }
        else { inAnim.stop(); outAnim.restart() }
    }
    Component.onCompleted: if (shown) { scale = 1; opacity = 1 }

    ParallelAnimation {
        id: inAnim
        NumberAnimation { target: root; property: "scale"; to: 1; duration: Motion.popInMs; easing.type: Easing.OutBack; easing.overshoot: Motion.popOvershoot }
        NumberAnimation { target: root; property: "opacity"; to: 1; duration: Motion.popInMs * 0.5; easing.type: Easing.OutQuad }
    }
    ParallelAnimation {
        id: outAnim
        NumberAnimation { target: root; property: "scale"; to: root.fromScale; duration: Motion.popOutMs; easing.type: Easing.InBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Motion.popOutMs; easing.type: Easing.InQuad }
    }
}
