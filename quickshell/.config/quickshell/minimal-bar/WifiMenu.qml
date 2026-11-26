import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

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

    property string page: "list"
    property var selectedNetwork: null
    property string message: ""

    function reset() {
        page = "list"
        selectedNetwork = null
        passwordInput.text = ""
        message = ""
    }

    function selectNetwork(network) {
        message = ""
        if (network.connected) return
        if (network.known || network.security === WifiSecurityType.Open) {
            selectedNetwork = network
            network.connect()
            message = "Connecting to " + network.name + "…"
        } else if (network.security === WifiSecurityType.Wpa2Psk
                   || network.security === WifiSecurityType.WpaPsk
                   || network.security === WifiSecurityType.Sae) {
            selectedNetwork = network
            page = "password"
        } else {
            message = "This network needs another authentication method."
        }
    }

    function connectSelected() {
        if (!selectedNetwork || !passwordInput.text) return
        selectedNetwork.connectWithPsk(passwordInput.text)
        passwordInput.text = ""
        page = "list"
        message = "Connecting to " + selectedNetwork.name + "…"
    }

    onVisibleChanged: if (!visible) reset()

    Connections {
        target: root.selectedNetwork
        function onConnectionFailed(reason) {
            root.message = "Connection failed: " + ConnectionFailReason.toString(reason)
        }
        function onConnectedChanged() {
            if (root.selectedNetwork && root.selectedNetwork.connected) {
                root.message = "Connected to " + root.selectedNetwork.name
                root.page = "list"
            }
        }
    }

    anchor.window: barWindow
    anchor.rect.x: Math.max(8, Math.min(barWindow.width - implicitWidth - 8,
        button.parent.parent.x + button.parent.x + button.x
            + (button.width - implicitWidth) / 2))
    anchor.rect.y: barWindow.height + 2
    implicitWidth: 310
    implicitHeight: 350
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
                    text: root.page === "list" ? "Wi-Fi" : root.page === "password"
                        ? "Connect" : "Forget network"
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
                visible: root.page === "list"
                Text {
                    text: "Wi-Fi " + (Networking.wifiEnabled ? "on" : "off")
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    colors: root.palette
                    label: Networking.wifiEnabled ? "Turn off" : "Turn on"
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.page === "list"
                text: barWindow.activeNetwork
                    ? "Connected: " + barWindow.activeNetwork.name : "Not connected"
                elide: Text.ElideRight
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.palette.border
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.page === "list"
                Text {
                    text: "Available networks"
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    colors: root.palette
                    label: "Rescan"
                    onClicked: {
                        if (barWindow.wifiDevice)
                            Quickshell.execDetached([
                                "nmcli", "device", "wifi", "rescan", "ifname",
                                barWindow.wifiDevice.name
                            ])
                    }
                }
            }

            ListView {
                id: networks
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: root.page === "list" && Networking.wifiEnabled
                model: barWindow.wifiDevice ? barWindow.wifiDevice.networks : null
                delegate: Rectangle {
                    required property var modelData
                    width: networks.width
                    height: modelData.name ? 32 : 0
                    visible: height > 0
                    color: modelData.connected || rowMouse.containsMouse
                        ? root.palette.hover : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (modelData.known ? 63 : 32)
                        elide: Text.ElideRight
                        text: modelData.name
                        color: modelData.connected ? root.palette.foreground : root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 16
                        color: modelData.connected ? root.palette.accent : "transparent"
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.left: parent.left
                        anchors.right: forgetButton.visible ? forgetButton.left : parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        hoverEnabled: true
                        onClicked: root.selectNetwork(modelData)
                    }
                    Text {
                        id: forgetButton
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "×"
                        visible: modelData.known
                        color: root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            onClicked: {
                                root.selectedNetwork = modelData
                                root.page = "forget"
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.page === "password"
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    text: root.selectedNetwork ? root.selectedNetwork.name : ""
                    elide: Text.ElideRight
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 13
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    color: root.palette.hover
                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: 7
                        echoMode: TextInput.Password
                        color: root.palette.foreground
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                        focus: root.page === "password"
                        Keys.onReturnPressed: root.connectSelected()
                    }
                }
                Text {
                    text: "Enter the Wi-Fi password"
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillHeight: true }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.page === "forget"
                Text {
                    Layout.fillWidth: true
                    text: root.selectedNetwork
                        ? "Forget " + root.selectedNetwork.name + "?" : ""
                    elide: Text.ElideRight
                    color: root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    text: "The saved connection will be removed."
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                }
                Item { Layout.fillHeight: true }
            }

            Text {
                Layout.fillWidth: true
                visible: root.message.length > 0
                text: root.message
                elide: Text.ElideRight
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 11
            }

            ActionButton {
                visible: root.page === "list"
                colors: root.palette
                label: "Advanced settings"
                onClicked: Quickshell.execDetached([
                    "alacritty", "--class", "nmtui_floating", "-e", "nmtui"
                ])
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.page !== "list"
                Item { Layout.fillWidth: true }
                Text {
                    text: "Cancel"
                    color: root.palette.muted
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.reset()
                    }
                }
                Item { width: 14 }
                Text {
                    text: root.page === "forget" ? "Forget" : "Connect"
                    color: root.page === "forget" ? root.palette.warning : root.palette.foreground
                    font.family: root.palette.fontFamily
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: {
                            if (root.page === "forget") {
                                if (root.selectedNetwork) root.selectedNetwork.forget()
                                root.reset()
                            } else root.connectSelected()
                        }
                    }
                }
            }
        }
    }
}
