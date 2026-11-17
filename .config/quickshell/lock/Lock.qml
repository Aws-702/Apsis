// The Apsis lockscreen: a session lock on every monitor, checked through PAM (lock/pam/).
// If the shell dies while locked, switch to a TTY and run:
//   hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'
//   hyprctl --instance 0 dispatch 'hl.dsp.exec_cmd("hyprlock")'
// Edit: what it shows is LockView.qml; the password rule is lock/pam/password.conf.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../config"
import "../services"

Scope {
    id: root

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired) {
                this.respond(LockState.buffer)
                LockState.buffer = ""
            } else if (this.message) {

                LockState.message = this.message
            }
        }
        onCompleted: function(result) {
            if (result === PamResult.Success) LockState.finished(true, "")
            else if (result === PamResult.MaxTries) LockState.finished(false, "Too many tries, wait a moment")
            else if (result === PamResult.Error) LockState.finished(false, "Authentication error")
            else LockState.finished(false, "Wrong password")
        }
    }

    property int fingerTries: 0
    PamContext {
        id: fpam
        configDirectory: "pam"
        config: "fingerprint.conf"
        onPamMessage: { if (this.message) LockState.fingerMessage = this.message }
        onCompleted: function(result) {
            LockState.fingerActive = false
            if (result === PamResult.Success) { LockState.finished(true, ""); return }
            root.fingerTries++
            LockState.fingerMessage = "Finger not recognised"
            if (LockState.locked && root.fingerTries < 3) fingerRetry.restart()
            else LockState.fingerMessage = ""
        }
    }
    Timer { id: fingerRetry; interval: 1200; onTriggered: if (LockState.locked) root.startFinger() }
    function startFinger() {
        if (fpam.active) return
        if (fpam.start()) LockState.fingerActive = true
    }

    Process {
        id: fingerCheck
        command: ["sh", "-c", "command -v fprintd-list >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -qi 'finger'"]
        onExited: (code) => { if (code === 0 && LockState.locked) root.startFinger() }
    }

    Process { id: sleeper }
    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root.fingerTries = 0
                LockState.fingerMessage = ""
                if (Settings.lockFinger) fingerCheck.running = true
                if (Settings.lockSleep) { sleeper.command = [Config.scripts + "/apsis-lock-sleep.sh", "on"]; sleeper.running = true }
            } else {
                fingerRetry.stop()
                if (fpam.active) fpam.abort()
                LockState.fingerActive = false
                LockState.fingerMessage = ""
                sleeper.command = [Config.scripts + "/apsis-lock-sleep.sh", "off"]
                sleeper.running = true
            }
        }
    }

    Component.onCompleted: LockState.submitter = function() {
        if (!pam.start()) LockState.finished(false, "Could not start authentication")
    }

    WlSessionLock {
        id: sessionLock
        locked: LockState.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.bgMain
            LockView {
                anchors.fill: parent
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { LockState.lock() }
    }
}
