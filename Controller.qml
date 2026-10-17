import QtQuick
import Quickshell.Io

// The app owns playback and credentials. This controller only calls its public
// session D-Bus interface through the installed CLI, with an argv array.
Item {
    id: root
    property string executable: "tidal-rs"
    property var playback: ({ running: false, visible: false })
    property bool available: false
    property string error: "Install TIDAL Rust 0.6.0 or newer to enable controls."
    property string output: ""

    function refresh() {
        if (!poll.running) poll.running = true
    }
    function control(action, value) {
        if (command.running) return
        let args = ["env", root.executable, "control", action]
        if (value !== undefined) args.push(String(value))
        command.command = args
        command.running = true
    }
    function time(seconds) {
        let n = Math.max(0, Math.floor(Number(seconds) || 0))
        return Math.floor(n / 60) + ":" + String(n % 60).padStart(2, "0")
    }
    Component.onCompleted: refresh()
    onExecutableChanged: refresh()
    Timer {
        interval: root.playback.running ? 1000 : 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }
    Process {
        id: poll
        command: ["env", root.executable, "control", "status"]
        onStarted: root.output = ""
        stdout: StdioCollector {
            onStreamFinished: root.output = text
        }
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            try {
                if (exitCode !== 0) throw new Error("TIDAL Rust 0.6.0+ is unavailable. Check the executable in widget settings.")
                let next = JSON.parse(root.output)
                if (next.running && !next.version) throw new Error("Upgrade TIDAL Rust to 0.6.0 or newer.")
                root.playback = next
                root.available = true
                root.error = ""
            } catch (failure) {
                root.playback = { running: false, visible: false }
                root.available = false
                root.error = String(failure.message || failure)
            }
        }
    }
    Process {
        id: command
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.error = text.trim()
        }
        onExited: root.refresh()
    }
}
