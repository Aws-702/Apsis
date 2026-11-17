// Pending updates, pinned groups and snapshot support, from apsis-updates.sh.
// Also checks the Apsis repo for a newer Apsis once a day (update.sh newer).
// Edit: check timing in the Timers here; group rules in lib/Updates.js and apsis-updates.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/Updates.js" as U

Singleton {
    id: root

    property var repo: []
    property var aur: []
    readonly property int heldCount: repo.filter(u => u.held).length + aur.filter(u => u.held).length
    readonly property int total: repo.length + aur.length - heldCount
    property bool qtRisk: false
    property var baseGroups: []
    property var pinState: ({})
    readonly property var groups: U.applyPins(baseGroups, pinState)
    property var protection: U.protection("")
    property bool missing: false
    property bool checking: lister.running
    property real checkedAt: 0
    property var self: U.selfStatus("")
    readonly property bool selfNew: self.status === "new"
    readonly property var selfCard: U.selfCard(self)
    readonly property int badge: total + (selfNew ? 1 : 0)
    property string version: ""

    function check() { if (!lister.running) lister.running = true }

    function checkSelf(now) {
        if (selfProc.running || Settings.data.apsisUpdateCheck === false) return
        selfProc.command = ["sh", Config.home + "/.config/apsis/update.sh", "newer"].concat(now ? ["--now"] : [])
        selfProc.running = true
    }

    function updateSelf() {
        Quickshell.execDetached([Config.scripts + "/apsis-updates.sh", "apsis"])
        selfRecheck.restart()
    }

    function update(keep, snapshot) {
        var ch = U.changes(root.groups, keep || {})
        Quickshell.execDetached([Config.scripts + "/apsis-updates.sh"].concat(U.runArgs(ch, snapshot === true)))

        recheck.restart()
    }

    Process {
        id: lister
        command: [Config.scripts + "/apsis-updates.sh", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.missing = this.text.trim() === "missing"
                var u = U.parse(root.missing ? "" : this.text)
                root.repo = u.repo
                root.aur = u.aur
                root.qtRisk = u.qtRisk
                root.baseGroups = u.groups
                root.checkedAt = Date.now()
                if (!root.missing && !stat.running) stat.running = true
                if (!root.missing && !pinsProc.running) pinsProc.running = true
            }
        }
    }
    Process {
        id: pinsProc
        command: [Config.scripts + "/apsis-updates.sh", "pins"]
        stdout: StdioCollector { onStreamFinished: root.pinState = U.pinStates(this.text) }
    }
    Process {
        id: selfProc
        stdout: StdioCollector { onStreamFinished: root.self = U.selfStatus(this.text) }
    }
    FileView {
        path: Config.home + "/.config/apsis/VERSION"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.version = text().trim()
    }
    Timer { running: true; interval: 120000; onTriggered: root.checkSelf(false) }
    Timer { running: true; repeat: true; interval: 3600000; onTriggered: root.checkSelf(false) }
    Timer { id: selfRecheck; interval: 5 * 60000; onTriggered: root.checkSelf(true) }
    Process {
        id: stat
        command: [Config.scripts + "/apsis-updates.sh", "status"]
        stdout: StdioCollector { onStreamFinished: root.protection = U.protection(this.text) }
    }
    Timer { running: true; interval: 60000; onTriggered: root.check() }
    Timer { running: true; repeat: true; interval: 30 * 60000; onTriggered: root.check() }
    Timer { id: recheck; interval: 5 * 60000; onTriggered: root.check() }
}
