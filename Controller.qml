import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import "SourceModel.js" as Sources

// The app owns playback and credentials. This controller only calls its public
// session D-Bus interface through the installed CLI, with an argv array.
Item {
    id: root
    property string executable: "tidal-rs"
    property var nativePlayback: ({ running: false, visible: false })
    property bool nativeAvailable: false
    property string nativeError: ""
    property string choice: "auto"
    property var sources: []
    property var selected: null
    property string previousAuto: ""
    property var playStates: ({})
    property var started: ({})
    property int serial: 0
    property int clockTick: 0
    readonly property bool usingWeb: !!selected && selected.kind === "web"
    signal selectionRequested(string value)
    function chooseSource(value) { selectionRequested(value) }
    readonly property bool available: usingWeb || nativeAvailable
    readonly property var sourceOptions: {
        let list = [{ value: "auto", label: "Auto · identified TIDAL sources" }]
        for (let source of sources) list.push({ value: source.id, label: source.label })
        if (choice !== "auto" && !sources.some(function(s) { return s.id === choice }))
            list.push({ value: choice, label: "Selected session is unavailable" })
        return list
    }
    readonly property string sourceLabel: selected ? selected.label : "No selected TIDAL source"
    readonly property var playback: {
        let tick = clockTick
        if (usingWeb) {
            let p = selected.player
            return { running: true, visible: false, title: p.trackTitle || "", artist: p.trackArtist || "",
                album: p.trackAlbum || "", cover: p.trackArtUrl || "", paused: !p.isPlaying,
                position: p.positionSupported ? p.position : 0, duration: p.lengthSupported ? p.length : 0,
                volume: p.volumeSupported ? p.volume * 100 : 0, quality: "TIDAL web",
                can_play: p.canTogglePlaying, can_next: p.canGoNext, can_previous: p.canGoPrevious,
                can_seek: p.canSeek && p.positionSupported, can_volume: !Sources.browser(p.identity, p.dbusName) && p.volumeSupported,
                spectrum_available: false, can_show: !!selected.window || p.canRaise }
        }
        if (selected && selected.kind === "rust") {
            let state = Object.assign({}, nativePlayback)
            state.can_seek = !!state.can_play
            state.can_volume = !!state.running
            state.can_show = nativeAvailable
            return state
        }
        return { running: false, visible: false, paused: true, can_play: false, can_show: false }
    }
    readonly property string error: {
        if (choice !== "auto" && !selected) return "Selected session closed. Choose Auto or another source."
        if (usingWeb) return selected.verified ? "" : "This browser does not identify its site. Controls target the browser session you selected."
        if (selected && selected.kind === "rust" && nativeAvailable) {
            if (nativePlayback.running && !nativePlayback.spectrum_available) return "Update TIDAL Rust to 0.6.1 for the live spectrum."
            if (sources.some(function(s) { return s.kind === "web" && !s.verified })) return "A browser session needs an explicit source choice."
            return ""
        }
        return "Open TIDAL web and start playback, or install TIDAL Rust."
    }
    property string output: ""
    property bool spectrumActive: false
    property var frequencies: []
    property bool spectrumLive: false
    onSpectrumActiveChanged: if (!spectrumActive) { frequencies = []; spectrumLive = false }

    function discover() {
        let windows = []
        for (let window of Hyprland.toplevels.values) {
            let ipc = window.lastIpcObject || {}
            windows.push({ pid: ipc.pid, appId: ipc.class || "", window: window })
        }
        let list = []
        if (nativeAvailable || nativePlayback.running)
            list.push({ id: "rust", kind: "rust", verified: true, label: "TIDAL Rust", playing: nativePlayback.running && nativePlayback.can_play && !nativePlayback.paused, can_play: nativePlayback.can_play })
        for (let player of Mpris.players.values) {
            let candidate = Sources.classify(player, windows)
            if (candidate) list.push(candidate)
        }
        let nextStates = {}, nextStarted = {}
        for (let source of list) {
            nextStates[source.id] = source.playing
            nextStarted[source.id] = started[source.id] || 0
            if (source.playing && !playStates[source.id]) nextStarted[source.id] = ++serial
            source.started = nextStarted[source.id]
        }
        playStates = nextStates; started = nextStarted; sources = list
        selected = Sources.select(list, choice, previousAuto)
        if (choice === "auto" && selected) previousAuto = selected.id
    }
    onChoiceChanged: discover()
    function refresh() {
        discover()
        if (!poll.running) poll.running = true
    }
    function control(action, value) {
        if (usingWeb) {
            let p = selected.player
            if (action === "toggle-playback" && p.canTogglePlaying) p.togglePlaying()
            else if (action === "next" && p.canGoNext) p.next()
            else if (action === "previous" && p.canGoPrevious) p.previous()
            else if (action === "seek" && playback.can_seek) p.position = Math.max(0, Math.min(p.length, Number(value)))
            else if (action === "volume" && playback.can_volume) p.volume = Math.max(0, Math.min(1, Number(value) / 100))
            else if (action === "toggle-window" || action === "show") {
                if (selected.window && /^0x[0-9a-f]+$/i.test(selected.window.address))
                    Hyprland.dispatch("hl.dsp.focus({window=" + JSON.stringify("address:" + selected.window.address) + "})")
                else if (selected.window && selected.window.wayland) selected.window.wayland.activate()
                else if (p.canRaise) p.raise()
            }
            return
        }
        if (!selected || selected.kind !== "rust" || command.running) return
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
        interval: 1000
        repeat: true
        running: true
        onTriggered: { root.clockTick++; root.refresh() }
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
                if (exitCode !== 0) throw new Error("TIDAL Rust 0.6.1+ is unavailable. Check the executable in widget settings.")
                let next = JSON.parse(root.output)
                if (next.running && !next.version) throw new Error("Upgrade TIDAL Rust to 0.6.1 or newer.")
                root.nativePlayback = next
                root.nativeAvailable = true
                root.nativeError = ""
            } catch (failure) {
                root.nativePlayback = { running: false, visible: false }
                root.nativeAvailable = false
                root.nativeError = String(failure.message || failure)
            }
            root.discover()
        }
    }
    Process {
        id: spectrumStream
        command: ["env", root.executable, "control", "spectrum"]
        running: !root.usingWeb && root.spectrumActive && root.available && root.playback.running === true && root.playback.spectrum_available === true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    let frame = JSON.parse(line)
                    if (!Array.isArray(frame.bins) || frame.bins.length !== 64) return
                    root.frequencies = frame.bins.map(function(value) { return Math.max(0, Math.min(1, Number(value) || 0)) })
                    root.spectrumLive = frame.live === true
                } catch (ignored) { root.spectrumLive = false }
            }
        }
        stderr: StdioCollector {}
        onExited: { root.spectrumLive = false; root.frequencies = [] }
    }
    Process {
        id: command
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.nativeError = text.trim()
        }
        onExited: root.refresh()
    }
}
