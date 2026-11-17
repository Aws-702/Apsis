// The wallpaper on one monitor, with the palette coloured transition shader.
// Edit: transition length and list here; the effect itself in shaders/wall.frag (rebuild the .qsb).

import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property string source: Wall.path
    property int front: 0
    property bool busy: anim.running

    readonly property real aspect: width / Math.max(1, height)
    readonly property var slots: [imgA, imgB]

    function cropScale(img) {
        if (!img || img.implicitWidth <= 0 || img.implicitHeight <= 0) return Qt.size(1, 1)
        var ia = img.implicitWidth / img.implicitHeight
        return ia > root.aspect ? Qt.size(root.aspect / ia, 1) : Qt.size(1, ia / root.aspect)
    }

    property string pending: ""

    opacity: Wall.video ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

    function load(path) {
        if (!path || Wall.video) return
        if (anim.running) { pending = path; return }
        var back = slots[1 - front]
        var cur = slots[front]
        if (cur.source.toString() === "" ) {

            cur.source = "file://" + path
            return
        }
        if (cur.source.toString() === "file://" + path) return
        back.source = ""
        back.source = "file://" + path
    }
    onSourceChanged: load(source)
    Component.onCompleted: load(source)

    function startIfReady(img) {
        if (img !== slots[1 - front] || img.status !== Image.Ready) return
        fx.fromTex = slots[front]
        fx.toTex = img
        fx.fromScale = cropScale(slots[front])
        fx.toScale = cropScale(img)
        fx.mode = Wall.pickMode()
        fx.seed = Math.random()
        fx.center = Qt.point(0.3 + Math.random() * 0.4, 0.35 + Math.random() * 0.3)
        fx.progress = 0
        anim.restart()
    }

    Image {
        id: imgA
        visible: false
        asynchronous: true
        cache: false
        onStatusChanged: root.startIfReady(imgA)
    }
    Image {
        id: imgB
        visible: false
        asynchronous: true
        cache: false
        onStatusChanged: root.startIfReady(imgB)
    }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        visible: root.slots[root.front].status === Image.Ready

        property var fromTex: imgA
        property var toTex: imgA
        property real progress: 1
        property real aspect: root.aspect
        property real seed: 0
        property int mode: 0
        property point center: Qt.point(0.5, 0.5)
        property size fromScale: root.cropScale(imgA)
        property size toScale: root.cropScale(imgA)
        property color colA: Theme.accent
        property color colB: Theme.accentHot
        property color colC: Theme.ring

        fragmentShader: Qt.resolvedUrl("../shaders/wall.frag.qsb")

        function settle() {
            fromTex = root.slots[root.front]
            toTex = root.slots[root.front]
            fromScale = root.cropScale(root.slots[root.front])
            toScale = fromScale
            progress = 1
        }
    }

    NumberAnimation {
        id: anim
        target: fx
        property: "progress"
        from: 0
        to: 1
        duration: fx.mode === 0 ? 700 : 1250
        easing.type: Easing.Linear
        onFinished: {
            root.slots[root.front].source = ""
            root.front = 1 - root.front
            fx.settle()
            if (root.pending !== "") {
                var next = root.pending
                root.pending = ""
                root.load(next)
            }
        }
    }

    Connections {
        target: imgA
        function onStatusChanged() { if (!anim.running && root.front === 0 && imgA.status === Image.Ready) fx.settle() }
    }
    Connections {
        target: imgB
        function onStatusChanged() { if (!anim.running && root.front === 1 && imgB.status === Image.Ready) fx.settle() }
    }
    onWidthChanged: if (!anim.running) fx.settle()
    onHeightChanged: if (!anim.running) fx.settle()
}
