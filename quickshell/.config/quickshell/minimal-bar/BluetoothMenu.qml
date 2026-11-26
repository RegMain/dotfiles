import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

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

    readonly property var adapter: Bluetooth.defaultAdapter
    property var selectedDevice: null
    property bool scanOwned: false

    onVisibleChanged: {
        if (!visible) {
            if (scanOwned && adapter && adapter.discovering)
                adapter.discovering = false
            scanOwned = false
            selectedDevice = null
        }
    }

    Timer {
        id: scanTimeout
        interval: 15000
        onTriggered: {
            if (root.scanOwned && root.adapter && root.adapter.discovering)
                root.adapter.discovering = false
            root.scanOwned = false
        }
    }

    anchor.window: barWindow
    anchor.rect.x: Math.max(8, Math.min(barWindow.width - implicitWidth - 8,
        button.parent.parent.x + button.parent.x + button.x
            + (button.width - implicitWidth) / 2))
    anchor.rect.y: barWindow.height + 2
    implicitWidth: 310
    implicitHeight: 352
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
                    text: root.selectedDevice ? "Forget device" : "Bluetooth"
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

            RowLayout {
                Layout.fillWidth: true
                visible: !root.selectedDevice
                Text {
                    text: root.adapter
                        ? "Bluetooth " + (root.adapter.enabled ? "on" : "off")
                        : "No adapter"
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    visible: !!root.adapter
                    colors: root.palette
                    label: root.adapter && root.adapter.enabled ? "Turn off" : "Turn on"
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.palette.border
            }

            RowLayout {
                Layout.fillWidth: true
                visible: !root.selectedDevice && root.adapter && root.adapter.enabled
                Text {
                    text: "Devices"
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    colors: root.palette
                    label: root.adapter && root.adapter.discovering ? "Stop scan" : "Scan"
                    onClicked: {
                        if (!root.adapter) return
                        if (root.adapter.discovering) {
                            root.adapter.discovering = false
                            root.scanOwned = false
                            scanTimeout.stop()
                        } else {
                            root.adapter.discovering = true
                            root.scanOwned = true
                            scanTimeout.restart()
                        }
                    }
                }
            }

            ListView {
                id: devices
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: !root.selectedDevice && root.adapter && root.adapter.enabled
                model: root.adapter ? root.adapter.devices : null
                delegate: Rectangle {
                    required property var modelData
                    width: devices.width
                    height: 38
                    color: modelData.connected || deviceMouse.containsMouse
                        ? root.palette.hover : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 16
                        color: modelData.connected ? root.palette.accent : "transparent"
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.right: batteryPercent.visible ? batteryPercent.left
                            : forgetButton.visible ? forgetButton.left : parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: modelData.name || modelData.deviceName || modelData.address
                        color: modelData.connected
                            ? root.palette.foreground : root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }

                    Text {
                        id: batteryPercent
                        anchors.right: forgetButton.visible ? forgetButton.left : parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.batteryAvailable
                        text: "(" + Math.round(modelData.battery * 100) + "%)"
                        color: root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: deviceMouse
                        anchors.left: parent.left
                        anchors.right: forgetButton.visible ? forgetButton.left : parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (modelData.paired) modelData.connect()
                            else modelData.pair()
                        }
                    }

                    Text {
                        id: forgetButton
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.paired
                        text: "×"
                        color: root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            onClicked: root.selectedDevice = modelData
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !!root.selectedDevice
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.selectedDevice
                        ? "Forget " + root.selectedDevice.name + "?" : ""
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "The device will need pairing again."
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        colors: root.palette
                        label: "Cancel"
                        onClicked: root.selectedDevice = null
                    }
                    ActionButton {
                        colors: root.palette
                        label: "Forget"
                        onClicked: {
                            if (root.selectedDevice) root.selectedDevice.forget()
                            root.selectedDevice = null
                        }
                    }
                }
            }

            ActionButton {
                visible: !root.selectedDevice
                colors: root.palette
                label: "Advanced settings"
                onClicked: Quickshell.execDetached(["blueman-manager"])
            }
        }
    }
}
