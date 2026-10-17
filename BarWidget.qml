import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "gumuller.tidal"
    readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing : false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    function open() { if (panelLoader.item) { player.refresh(); panelLoader.item.open() } }
    function close() { if (panelLoader.item) panelLoader.item.close() }
    function toggle() { opened ? close() : open() }
    function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }
    function injectPanel() {
        if (!panelLoader.item) return
        panelLoader.item.bar = root.bar
        panelLoader.item.anchorItem = button
        panelLoader.item.hostWidget = root
        panelLoader.item.player = player
    }
    onBarChanged: injectPanel()

    Controller {
        id: player
        executable: String(root.setting("executable", "tidal-rs"))
        spectrumActive: root.opened
    }
    Loader {
        id: panelLoader
        active: true
        visible: false
        source: Qt.resolvedUrl("PlayerPanel.qml")
        onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
    }
    Ui.WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.vertical ? "󰝚" : "󰝚  TIDAL" + (player.playback.running && player.playback.can_play ? (player.playback.paused ? "  Ⅱ" : "  ▶") : "")
        tooltipText: player.playback.title ? player.playback.artist + " — " + player.playback.title : "TIDAL Rust · click for controls; right-click to show/hide"
        dimmed: !player.playback.running
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.RightButton) player.control("toggle-window")
            else if (buttonCode === Qt.MiddleButton && player.playback.can_play) player.control("toggle-playback")
            else root.toggle()
        }
    }
}
