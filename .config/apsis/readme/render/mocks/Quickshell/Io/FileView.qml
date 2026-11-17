// Stand-in for FileView: reads any file, writes only inside the demo home.
// Edit: the demo files in demo/ (shot.py copies them into a scratch home).

import QtQuick
import ShotLab
QtObject {
    id: f
    property string path: ""
    property bool watchChanges: false
    property bool preload: false
    property bool blockLoading: false
    property bool blockWrites: false
    property bool printErrors: true
    property bool atomicWrites: true
    property string _text: ""
    signal loaded()
    signal saved()
    signal fileChanged()
    signal textChanged()
    signal loadFailed(int error)
    function text() { return _text }
    function data() { return _text }
    function reload() {
        if (!Shot.exists(path)) { loadFailed(1); return }
        var t = Shot.readFile(path)
        if (t !== _text) { _text = t; textChanged() }
        loaded()
    }
    function setText(t) { _text = String(t); Shot.writeFile(path, _text); textChanged() }
    function writeAdapter() {}
    onPathChanged: reload()
    Component.onCompleted: reload()
}
