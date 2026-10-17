// Conservative identification and source selection; no I/O or browser heuristics
// based on song names. Shared browsers require an explicit source choice.
function tidalUrl(value) {
    return /^https?:\/\/(?:[a-z0-9-]+\.)*tidal\.com(?::\d+)?(?:[\/?#]|$)/i.test(String(value || ""))
}
function tidalWindow(value) {
    return /^(?:chrome|msedge|chromium)-(?:listen|play)\.tidal\.com(?:__|_|-)/i.test(String(value || ""))
}
function browser(identity, bus) {
    return /chromium|chrome|firefox|microsoft edge|brave|vivaldi|opera/i.test(String(identity || "") + " " + String(bus || ""))
}
function classify(player, windows) {
    if (!player || !player.dbusName || !(player.trackTitle || player.trackArtist)) return null
    let metadata = player.metadata || {}
    let identified = /^tidal(?:\s|$)/i.test(String(player.identity || ""))
        || tidalUrl(metadata["xesam:url"]) || tidalUrl(player.trackArtUrl)
    if (!identified && !browser(player.identity, player.dbusName)) return null
    let match = String(player.dbusName).match(/\.instance(\d+)$/)
    let own = match ? windows.filter(function(w) { return Number(w.pid) === Number(match[1]) }) : []
    let tidal = own.filter(function(w) { return tidalWindow(w.appId) })
    if (!identified && tidal.length && own.every(function(w) { return tidalWindow(w.appId) })) identified = true
    return {
        id: "web:" + player.dbusName, kind: "web", player: player,
        window: tidal.length ? tidal[0].window : null,
        verified: identified, playing: !!player.isPlaying, can_play: !!player.canTogglePlaying,
        label: identified ? "TIDAL web · " + player.identity : "Browser · " + player.identity + " (manual)"
    }
}
function select(sources, choice, previous) {
    if (choice && choice !== "auto") return sources.find(function(s) { return s.id === choice }) || null
    let eligible = sources.filter(function(s) { return s.kind === "rust" || s.verified })
    let playing = eligible.filter(function(s) { return s.playing })
    playing.sort(function(a, b) { return (b.started || 0) - (a.started || 0) })
    if (playing.length) return playing[0]
    let last = eligible.find(function(s) { return s.id === previous })
    if (last) return last
    return eligible.find(function(s) { return s.can_play }) || eligible[0] || null
}
