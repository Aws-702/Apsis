// The dock's timer, counted from the wall clock; rings once at zero and blinks until seen.
// Edit: the ring sound and notification text here.

pragma Singleton
import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    property bool running: false
    property bool paused: false
    property bool rang: false
    property real total: 0
    property real endAt: 0
    property real heldLeft: 0
    property real left: 0

    readonly property bool active: running || paused
    readonly property string text: fmt(active ? left : total)

    function fmt(s) {
        s = Math.max(0, Math.ceil(s))
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), x = s % 60
        function two(v) { return v < 10 ? "0" + v : "" + v }
        return (h > 0 ? h + ":" + two(m) : m) + ":" + two(x)
    }

    function start(secs) {
        if (secs <= 0) return
        total = secs
        left = secs
        endAt = Date.now() + secs * 1000
        paused = false
        rang = false
        running = true
    }
    function pause() { if (!running) return; heldLeft = Math.max(0, (endAt - Date.now()) / 1000); left = heldLeft; running = false; paused = true }
    function resume() { if (!paused) return; endAt = Date.now() + heldLeft * 1000; paused = false; running = true }
    function reset() { running = false; paused = false; rang = false; left = total }
    function add(secs) {
        if (running) endAt += secs * 1000
        else if (paused) heldLeft += secs
        else { start(secs); return }
        left = Math.max(0, left + secs)
        total += secs
    }
    function seen() { rang = false }

    Timer {
        interval: 250
        repeat: true
        running: root.running
        onTriggered: {
            root.left = Math.max(0, (root.endAt - Date.now()) / 1000)
            if (root.left <= 0) {
                root.running = false
                root.rang = true
                Quickshell.execDetached(["sh", "-c", "notify-send -a Apsis 'Timer' 'Time is up' ; for s in /usr/share/sounds/freedesktop/stereo/complete.oga /usr/share/sounds/freedesktop/stereo/bell.oga; do [ -f \"$s\" ] && { pw-play \"$s\" 2>/dev/null || paplay \"$s\" 2>/dev/null; break; }; done"])
            }
        }
    }
}
