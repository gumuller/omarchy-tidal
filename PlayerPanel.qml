import QtQuick
import qs.Commons
import qs.Ui as Ui

Ui.Panel {
    id: root
    moduleName: "gumuller.tidal"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property var player: null
    readonly property var playback: player ? player.playback : ({})
    function switchPanel(direction) {
        return root.bar && root.bar.switchPanelFrom ? root.bar.switchPanelFrom(root.hostWidget || root, direction) : false
    }
    Ui.KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: content
        contentWidth: panel.fittedContentWidth(Style.space(330))
        contentHeight: panel.fittedContentHeight(content.implicitHeight)

        Column {
            id: content
            width: parent.width
            spacing: Style.space(12)
            focus: true
            Keys.onEscapePressed: root.close()
            Text {
                width: parent.width
                text: "TIDAL RUST"
                textFormat: Text.PlainText
                font.family: Style.font.family
                font.pixelSize: Style.font.subtitle
                font.bold: true
                color: root.barForeground
            }
            Row {
                width: parent.width
                spacing: Style.space(12)
                Rectangle {
                    width: Style.space(84)
                    height: width
                    color: Color.background
                    Text {
                        anchors.centerIn: parent
                        visible: artwork.status !== Image.Ready
                        text: "󰝚"
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.displayLarge
                    }
                    Image {
                        id: artwork
                        anchors.fill: parent
                        source: root.playback.cover || ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }
                }
                Column {
                    width: parent.width - Style.space(96)
                    spacing: Style.space(5)
                    Text {
                        width: parent.width
                        text: root.playback.title || (root.playback.running ? "Ready to play" : "Player is closed")
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: root.barForeground
                        font.family: Style.font.family
                        font.pixelSize: Style.font.subtitle
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: root.playback.artist || "Your music, within reach"
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Color.muted
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                    }
                    Text {
                        width: parent.width
                        text: root.playback.quality || ""
                        textFormat: Text.PlainText
                        color: Color.accent
                        font.family: Style.font.family
                        font.pixelSize: Style.font.caption
                    }
                }
            }
            Ui.PanelSlider {
                width: parent.width
                bar: root.bar
                enabled: !!root.playback.can_play
                maximum: Math.max(1, root.playback.duration || 0)
                value: root.playback.position || 0
                onReleased: function(value) { if (root.player) root.player.control("seek", Math.round(value)) }
            }
            Text {
                width: parent.width
                text: root.player ? root.player.time(root.playback.position) + " / " + root.player.time(root.playback.duration) : "0:00 / 0:00"
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                horizontalAlignment: Text.AlignHCenter
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(18)
                Ui.PanelActionButton {
                    iconText: "󰒮"
                    tooltipText: "Previous track"
                    focusable: true
                    enabled: !!root.playback.can_previous
                    foreground: root.barForeground
                    onClicked: root.player.control("previous")
                }
                Ui.PanelActionButton {
                    iconText: root.playback.paused !== false ? "󰐊" : "󰏤"
                    tooltipText: root.playback.paused !== false ? "Play" : "Pause"
                    focusable: true
                    enabled: !!root.playback.can_play
                    size: Style.space(38)
                    foreground: Color.accent
                    onClicked: root.player.control("toggle-playback")
                }
                Ui.PanelActionButton {
                    iconText: "󰒭"
                    tooltipText: "Next track"
                    focusable: true
                    enabled: !!root.playback.can_next
                    foreground: root.barForeground
                    onClicked: root.player.control("next")
                }
            }
            Row {
                width: parent.width
                spacing: Style.space(10)
                Text {
                    text: "󰕾"
                    color: root.barForeground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                }
                Ui.PanelSlider {
                    width: parent.width - Style.space(64)
                    bar: root.bar
                    enabled: !!root.playback.running
                    maximum: 100
                    step: 5
                    integer: true
                    value: root.playback.volume || 0
                    onReleased: function(value) { if (root.player) root.player.control("volume", Math.round(value)) }
                }
                Text {
                    text: Math.round(root.playback.volume || 0) + "%"
                    color: Color.muted
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                }
            }
            Ui.Button {
                width: parent.width
                text: root.playback.running ? (root.playback.visible ? "Hide player" : "Show player") : "Open TIDAL Rust"
                focusable: true
                bordered: true
                enabled: root.player ? root.player.available : false
                onClicked: { root.player.control("toggle-window"); root.close() }
            }
            Text {
                width: parent.width
                visible: text !== ""
                text: root.player ? root.player.error : ""
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                color: Color.muted
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
            }
        }
    }
}
