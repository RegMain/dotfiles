import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

PopupWindow {
    id: root
    required property var barWindow
    required property Item button
    required property var palette
    signal closeRequested()

    HoverDismiss {
        popup: root
        button: root.button
        onDismissed: root.closeRequested()
    }

    readonly property var outputs: Pipewire.nodes.values.filter(
        node => node.audio && node.isSink && !node.isStream
    )
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property var streams: []

    // Do not track transient application nodes: they can disappear during a
    // PipeWire callback. Track only the default output and microphone.
    PwObjectTracker {
        objects: [root.sink, root.source].filter(Boolean)
    }

    function refreshMixer() {
        if (visible && !mixerProcess.running)
            mixerProcess.running = true
    }

    onVisibleChanged: {
        if (visible) refreshMixer()
        else streams = []
    }

    Process {
        id: mixerProcess
        command: ["pactl", "--format=json", "list", "sink-inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.streams = JSON.parse(text).filter(stream => {
                        const role = String(stream.properties["media.role"] || "").toLowerCase()
                        return !stream.corked && !["notification", "event"].includes(role)
                    }).map(stream => {
                        const channels = Object.values(stream.volume || {})
                        return {
                            index: stream.index,
                            name: stream.properties["application.name"]
                                || stream.properties["media.name"] || "Unknown application",
                            volume: channels.length ? channels[0].value / 65536 : 0,
                            mute: stream.mute
                        }
                    })
                } catch (error) {
                    root.streams = []
                    console.warn("Could not read application mixer:", error)
                }
            }
        }
    }

    Timer {
        id: mixerRefresh
        interval: 400
        onTriggered: root.refreshMixer()
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: root.refreshMixer()
    }

    anchor.window: barWindow
    // Center on "vol:", shifting only when the screen edge would clip the menu.
    anchor.rect.x: Math.round(Math.max(8, Math.min(barWindow.width - implicitWidth - 8,
        button.parent.parent.x + button.parent.x + button.x
            + (button.width - implicitWidth) / 2)))
    anchor.rect.y: barWindow.height + 2
    implicitWidth: 300
    implicitHeight: 480
    color: root.palette.surface

    Rectangle {
        anchors.fill: parent
        color: root.palette.surface
        border.color: root.palette.activeBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Audio"
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 13
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "×"
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 16
                    Layout.rightMargin: 2
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.closeRequested()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.sink ? root.sink.description || root.sink.name : "No output"
                color: root.palette.foreground
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                VolumeSlider {
                    Layout.fillWidth: true
                    node: root.sink
                    colors: root.palette
                }
                Text {
                    text: root.sink && root.sink.audio
                        ? Math.round(root.sink.audio.volume * 100) + "%" : "—"
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                ActionButton {
                    colors: root.palette
                    label: root.sink && root.sink.audio && root.sink.audio.muted
                        ? "Unmute" : "Mute"
                    onClicked: {
                        if (root.sink && root.sink.audio)
                            root.sink.audio.muted = !root.sink.audio.muted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.palette.border
            }

            Text {
                text: "Output devices"
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            ListView {
                id: outputList
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                clip: true
                model: root.outputs
                delegate: Rectangle {
                    required property var modelData
                    width: outputList.width
                    height: 28
                    color: outputMouse.containsMouse || modelData === root.sink
                        ? root.palette.hover : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 16
                        color: modelData === root.sink ? root.palette.accent : "transparent"
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.description || modelData.name
                        color: modelData === root.sink
                            ? root.palette.foreground : root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: outputMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.palette.border
            }

            Text {
                Layout.fillWidth: true
                text: root.source
                    ? "Microphone: " + (root.source.description || root.source.name)
                    : "Microphone unavailable"
                elide: Text.ElideRight
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                VolumeSlider {
                    Layout.fillWidth: true
                    node: root.source
                    colors: root.palette
                }
                ActionButton {
                    colors: root.palette
                    label: root.source && root.source.audio && root.source.audio.muted
                        ? "Unmute" : "Mute"
                    onClicked: {
                        if (root.source && root.source.audio)
                            root.source.audio.muted = !root.source.audio.muted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.palette.border
            }

            Text {
                text: "Application mixer"
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            ListView {
                id: streamList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.streams
                delegate: Column {
                    required property var modelData
                    width: streamList.width
                    height: 55
                    spacing: 4
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.name
                        color: root.palette.foreground
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }
                    RowLayout {
                        width: parent.width
                        PactlSlider {
                            Layout.fillWidth: true
                            volume: modelData.volume
                            colors: root.palette
                            onValueSelected: value => {
                                Quickshell.execDetached([
                                    "pactl", "set-sink-input-volume", String(modelData.index),
                                    Math.round(value * 100) + "%"
                                ])
                                mixerRefresh.restart()
                            }
                        }
                        ActionButton {
                            colors: root.palette
                            label: modelData.mute ? "Unmute" : "Mute"
                            onClicked: {
                                Quickshell.execDetached([
                                    "pactl", "set-sink-input-mute", String(modelData.index),
                                    modelData.mute ? "0" : "1"
                                ])
                                mixerRefresh.restart()
                            }
                        }
                    }
                }
            }

            ActionButton {
                colors: root.palette
                label: "Advanced mixer"
                onClicked: Quickshell.execDetached(["pavucontrol"])
            }
        }
    }
}
