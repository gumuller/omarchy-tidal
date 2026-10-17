import QtQuick
import qs.Commons

Canvas {
    id: root
    property var bins: []
    property bool live: false
    property bool active: false
    property var bars: Array(64).fill(0)
    property var peaks: Array(64).fill(0)
    property color spectrumColor: Color.accent
    property color peakColor: Color.foreground
    property color gridColor: Color.muted
    Accessible.role: Accessible.Graphic
    Accessible.name: "Live audio spectrum analyzer"
    Accessible.description: "64 frequency bands from the player's real audio; 60 fps animation"

    function tick(dt) {
        dt = Math.max(0, Math.min(0.1, dt))
        for (let i = 0; i < 64; ++i) {
            let target = root.live && i < root.bins.length ? root.bins[i] : 0
            let speed = target > root.bars[i] ? 35 : 10
            root.bars[i] += (target - root.bars[i]) * (1 - Math.exp(-speed * dt))
            root.peaks[i] = Math.max(root.bars[i], root.peaks[i] - dt * 0.28)
        }
        requestPaint()
    }
    FrameAnimation {
        running: root.active
        onTriggered: root.tick(frameTime)
    }
    onActiveChanged: if (!active) { bars = Array(64).fill(0); peaks = Array(64).fill(0) }
    onSpectrumColorChanged: requestPaint()
    onPeakColorChanged: requestPaint()
    onGridColorChanged: requestPaint()
    onPaint: {
        let ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.fillStyle = root.gridColor
        ctx.globalAlpha = 0.15
        for (let line = 1; line < 4; ++line) ctx.fillRect(0, Math.round(height * line / 4), width, 1)
        ctx.globalAlpha = 1
        let step = width / 64
        let barWidth = Math.max(1, step - 1)
        let usable = height - 3
        for (let i = 0; i < 64; ++i) {
            let barHeight = Math.max(1, root.bars[i] * usable)
            ctx.fillStyle = root.spectrumColor
            ctx.globalAlpha = root.bars[i] > 0.01 ? 0.85 : 0.18
            ctx.fillRect(i * step, height - barHeight, barWidth, barHeight)
            if (root.peaks[i] > 0.02) {
                ctx.globalAlpha = 0.9
                ctx.fillStyle = root.peakColor
                ctx.fillRect(i * step, Math.max(0, height - root.peaks[i] * usable - 2), barWidth, 1)
            }
        }
        ctx.globalAlpha = 1
    }
}
