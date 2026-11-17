// Desktop widget: synced lyrics of what's playing, the sung line filling in; scroll to nudge timing.
// Edit: line sizes and how many lines show here; finding lyrics is services/Lyrics.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/Lrc.js" as Lrc

Block {
    id: root
    property var widget: ({})
    property bool editing: false

    fill: Theme.bgCard

    property real t: 0
    readonly property var lines: Lyrics.lines
    readonly property int idx: Lrc.at(lines, t)
    readonly property real prog: Lrc.progress(lines, idx, t)
    readonly property bool hasWords: idx >= 0 && idx < lines.length && lines[idx].words !== undefined && lines[idx].words.length > 0
    property bool picking: false

    Component.onCompleted: { Lyrics.want++; Sys.wantMedia++ }
    Component.onDestruction: { Lyrics.want--; Sys.wantMedia-- }

    Timer {
        interval: 80
        repeat: true
        running: Lyrics.phase === "found" && root.visible
        triggeredOnStart: true
        onTriggered: root.t = Lyrics.now()
    }

    WheelHandler {
        enabled: !root.editing && Lyrics.phase === "found"
        onWheel: function(w) { Lyrics.nudge += w.angleDelta.y > 0 ? 0.25 : -0.25 }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            VIcon { size: 14; d: Icons.music; color: Theme.accent }
            Label {
                Layout.fillWidth: true
                sub: true
                font.pixelSize: 10
                elide: Text.ElideRight
                text: Sys.hasPlayer ? Sys.title + (Sys.artist ? "  /  " + Sys.artist : "") : "Lyrics"
            }

            Label {
                visible: Lyrics.phase === "found" && Lyrics.sources.length > 0 && !root.editing
                sub: true
                font.pixelSize: 10
                color: Theme.accent
                text: { for (var i = 0; i < Lyrics.sources.length; i++) if (Lyrics.sources[i].chosen) return Lyrics.sources[i].name; return "source" }
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.picking = !root.picking }
            }
            Label {
                visible: Lyrics.nudge !== 0
                sub: true
                font.pixelSize: 10
                text: (Lyrics.nudge > 0 ? "+" : "") + Lyrics.nudge.toFixed(2) + "s"
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            visible: Lyrics.phase === "found"
            sub: true
            font.pixelSize: 13
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.idx > 0 ? root.lines[root.idx - 1].text : " "
            opacity: 0.6
        }

        Flow {
            id: wordLine
            Layout.fillWidth: true
            visible: Lyrics.phase === "found" && root.hasWords
            spacing: 0
            Repeater {
                model: root.hasWords ? root.lines[root.idx].words : []
                Item {
                    id: wd
                    required property int index
                    required property var modelData
                    readonly property real frac: Lrc.wordFrac(root.lines[root.idx].words, index, root.t, root.idx + 1 < root.lines.length ? root.lines[root.idx + 1].t : root.t + 2)
                    width: dim.implicitWidth
                    height: dim.implicitHeight
                    Label { id: dim; text: wd.modelData.text; font.pixelSize: 20; font.weight: Font.Black; color: Theme.textSecondary }
                    Item {
                        width: parent.width * wd.frac
                        height: parent.height
                        clip: true
                        Label { text: wd.modelData.text; font.pixelSize: 20; font.weight: Font.Black; color: Theme.accent }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: cur.implicitHeight
            visible: Lyrics.phase === "found" && !root.hasWords
            Label {
                id: cur
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: 20
                font.weight: Font.Black

                color: lineCount > 1 ? Theme.textPrimary : Theme.textSecondary
                text: root.idx >= 0 ? (root.lines[root.idx].text || "...") : "..."
            }

            Item {
                readonly property real textLeft: (cur.width - cur.contentWidth) / 2
                x: textLeft
                width: cur.contentWidth * root.prog
                height: parent.height
                clip: true
                visible: cur.lineCount === 1
                Label {
                    x: -parent.textLeft
                    width: cur.width
                    horizontalAlignment: Text.AlignHCenter
                    font: cur.font
                    color: Theme.accent
                    text: cur.text
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: Lyrics.phase === "found"
            sub: true
            font.pixelSize: 13
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.idx + 1 < root.lines.length ? root.lines[root.idx + 1].text : " "
            opacity: 0.6
        }

        Label {
            Layout.fillWidth: true
            visible: Lyrics.phase !== "found"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            sub: true
            font.pixelSize: 13
            text: Lyrics.phase === "looking" ? "Looking for the lyrics..."
                : Lyrics.phase === "none" ? "No synced lyrics for this song"
                : "Play something"
        }

        Item { Layout.fillHeight: true }
    }

    Block {
        visible: root.picking && Lyrics.sources.length > 0
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 34 }
        height: pickCol.implicitHeight + 16
        small: true
        fill: Theme.bgMain
        ColumnLayout {
            id: pickCol
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            Repeater {
                model: Lyrics.sources
                BlockButton {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    small: true
                    fontSize: 11
                    align: Qt.AlignLeft
                    active: modelData.chosen
                    text: modelData.name + (modelData.words ? "  word by word" : "") + "  " + modelData.lines + " lines"
                    onClicked: { Lyrics.pick(modelData.name); root.picking = false }
                }
            }
            BlockButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                small: true
                fontSize: 11
                text: "Best one, automatically"
                onClicked: { Lyrics.pick("auto"); root.picking = false }
            }
        }
    }
}
