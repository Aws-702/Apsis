// The lockscreen's shared state: locked, typed buffer, PAM check, messages, fingerprint.
// Edit: the messages shown on a wrong password here.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool locked: false
    property string buffer: ""
    property bool checking: false
    property string message: ""
    property int fails: 0

    property string fingerMessage: ""
    property bool fingerActive: false

    property int shakeTick: 0

    property var submitter: null

    function lock() {
        if (root.locked) return
        root.buffer = ""
        root.message = ""
        root.fails = 0
        root.checking = false
        root.fingerMessage = ""
        root.locked = true
    }

    function type(text) {
        if (!root.locked || root.checking || !text) return
        if (root.buffer.length < 256) root.buffer += text
        root.message = ""
    }
    function backspace() { if (!root.checking) root.buffer = root.buffer.slice(0, -1) }
    function clear() { if (!root.checking) root.buffer = "" }

    function submit() {
        if (root.checking || root.buffer.length === 0 || !root.submitter) return
        root.checking = true
        root.message = ""
        root.submitter()
    }

    function finished(ok, why) {
        root.checking = false
        root.buffer = ""
        if (ok) {
            root.locked = false
            root.fails = 0
            root.message = ""
        } else {
            root.fails++
            root.shakeTick++
            root.message = why || "Wrong password"
        }
    }
}
