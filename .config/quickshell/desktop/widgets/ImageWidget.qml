// Desktop widget: a picture from ~/Apsis/pictures; click for the next one.
// Edit: frame and corner radius here; widget size in lib/WidgetTypes.js.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    property var files: []
    readonly property string path: widget.path || ""
    readonly property bool rounded: !(widget.style && widget.style.square === true)

    Process {
        id: lister
        command: ["sh", "-c", "d=\"$HOME/Apsis/pictures\"; find \"$d\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var o = this.text.trim()
                root.files = o.length ? o.split("\n") : []
                if (root.files.length && (root.path === "" || root.files.indexOf(root.path) < 0))
                    Desktop.setField(root.widget.id, "path", root.files[0])
            }
        }
    }
    function next() {
        if (!files.length) { lister.running = true; return }
        var i = files.indexOf(path)
        Desktop.setField(widget.id, "path", files[(i + 1) % files.length])
    }

    RoundImage {
        anchors.fill: parent
        radius: root.rounded ? Math.max(0, root.radius - root.inset) : 0
        source: root.path ? "file://" + root.path : ""
        sourceSize.width: 600
        sourceSize.height: 600
        asynchronous: true
    }
    Label {
        anchors.centerIn: parent
        visible: root.path === ""
        sub: true
        horizontalAlignment: Text.AlignHCenter
        text: "Drop images in\n~/Apsis/pictures"
    }
    MouseArea { anchors.fill: parent; enabled: !root.editing; cursorShape: Qt.PointingHandCursor; onClicked: root.next() }
    BlockButton {
        visible: root.editing
        small: true
        width: 64; height: 28
        x: 8; y: root.height - 40
        text: root.rounded ? "round" : "square"
        fontSize: 10
        onClicked: Desktop.setStyle(root.widget.id, "square", root.rounded)
    }
}
