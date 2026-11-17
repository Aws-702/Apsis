// Bar key: only while an app records the mic, a camera or the screen; click for which apps.
// Edit: which streams count here; the list is bar/cards/PrivacyCard.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root

    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream)
    PwObjectTracker { objects: root.streams }

    function prop(n, k) { var p = n && n.properties ? n.properties : {}; return p[k] === undefined ? "" : String(p[k]) }
    function name(n) { return prop(n, "application.name") || prop(n, "application.process.binary") || n.description || n.name || "An app" }
    function uniq(a) { var o = []; for (var i = 0; i < a.length; i++) if (o.indexOf(a[i]) < 0) o.push(a[i]); return o }

    readonly property var mic: root.uniq(streams.filter(n => root.prop(n, "media.class") === "Stream/Input/Audio"
            && root.prop(n, "stream.monitor") !== "true" && root.prop(n, "node.passive") !== "true"
            && root.prop(n, "stream.capture.sink") !== "true" && root.name(n).toLowerCase() !== "cava"
            && !(Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted)).map(n => root.name(n)))
    readonly property var video: root.uniq(streams.filter(n => root.prop(n, "media.class") === "Stream/Input/Video").map(n => root.name(n)))
    readonly property bool live: mic.length > 0 || video.length > 0

    onMicChanged: UiState.privacyMic = mic
    onVideoChanged: UiState.privacyVideo = video

    small: true
    radius: 10
    Layout.fillHeight: true
    implicitHeight: 29
    implicitWidth: live ? row.implicitWidth + 18 : 0
    visible: live
    fill: Theme.mix(Theme.bgItem, Theme.danger, 0.22)
    ring: Theme.danger
    pressed: ma.pressed

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        VIcon { visible: root.mic.length > 0; size: 15; d: Icons.mic; color: Theme.danger }
        VIcon { visible: root.video.length > 0; size: 15; d: Icons.camera; color: Theme.danger }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleBarPopup("privacy", root.mapToItem(null, root.width / 2, 0).x)
    }
}
