// Stand-in for Pipewire: the demo sink and source from demo.json.
// Edit: the nodes in demo.json (pipewire).

pragma Singleton
import QtQuick
import ShotLab
QtObject {
    function om(a) { var r = []; for (var i = 0; a && i < a.length; i++) r.push(a[i]); return { values: r } }
    readonly property var nodes: om(Shot.pwNodes())
    readonly property var links: om([])
    readonly property var defaultAudioSink: nodes.values[0]
    readonly property var defaultAudioSource: nodes.values[2]
    property var preferredDefaultAudioSink: defaultAudioSink
    property var preferredDefaultAudioSource: defaultAudioSource
    readonly property bool ready: true
}
