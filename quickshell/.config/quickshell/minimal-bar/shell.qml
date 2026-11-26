import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

// Run with `qs -p ~/dotfiles/quickshell/.config/quickshell/minimal-bar`.
ShellRoot {
QtObject {
    id: theme
    readonly property color surface: "#161616"
    readonly property color hover: "#2d2d2d"
    readonly property color border: "#444444"
    readonly property color activeBorder: "#ffffff"
    readonly property color foreground: "#f0f0f2"
    readonly property color muted: "#a2a3ad"
    readonly property color accent: "#6d73ca"
    readonly property color warning: "#f38ba8"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}

PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 30
    color: theme.surface
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var wifiDevice: Networking.devices.values.find(
        device => device.type === DeviceType.Wifi
    )
    readonly property var activeNetwork: wifiDevice
        ? wifiDevice.networks.values.find(network => network.connected) : null
    property string layoutCode: "EN"
    property bool trayExpanded: false
    property bool batteryMenuOpen: false
    property bool networkMenuOpen: false
    property bool audioMenuOpen: false
    property bool bluetoothMenuOpen: false
    property bool calendarOpen: false

    onBatteryMenuOpenChanged: {
        if (batteryMenuOpen) {
            networkMenuOpen = false
            audioMenuOpen = false
            bluetoothMenuOpen = false
            calendarOpen = false
            thresholds.reload()
        }
    }

    onNetworkMenuOpenChanged: {
        if (networkMenuOpen) {
            batteryMenuOpen = false
            audioMenuOpen = false
            bluetoothMenuOpen = false
            calendarOpen = false
        }
        if (wifiDevice) wifiDevice.scannerEnabled = networkMenuOpen
    }

    onAudioMenuOpenChanged: {
        if (audioMenuOpen) {
            batteryMenuOpen = false
            networkMenuOpen = false
            bluetoothMenuOpen = false
            calendarOpen = false
        }
    }

    onBluetoothMenuOpenChanged: {
        if (bluetoothMenuOpen) {
            batteryMenuOpen = false
            networkMenuOpen = false
            audioMenuOpen = false
            calendarOpen = false
        }
    }

    onCalendarOpenChanged: {
        if (calendarOpen) {
            batteryMenuOpen = false
            networkMenuOpen = false
            audioMenuOpen = false
            bluetoothMenuOpen = false
        }
    }

    // PipeWire only subscribes to volume changes for tracked nodes.
    PwObjectTracker {
        objects: bar.sink ? [bar.sink] : []
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        command: ["hyprctl", "devices", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboard = JSON.parse(text).keyboards.find(device => device.main)
                    if (keyboard)
                        bar.layoutCode = keyboard.active_layout_index === 1 ? "RU" : "EN"
                } catch (error) {
                    console.warn("Could not read the keyboard layout:", error)
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                bar.layoutCode = event.data.split(",").pop() === "Russian" ? "RU" : "EN"
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 10
        spacing: 0

        Row {
            id: workspaces
            spacing: 0

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    readonly property int workspaceId: index + 1
                    readonly property bool active: Hyprland.focusedWorkspace
                        && Hyprland.focusedWorkspace.id === workspaceId

                    width: 44
                    height: 30
                    color: workspaceMouse.containsMouse ? theme.hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.workspaceId
                        color: theme.foreground
                        font.family: theme.fontFamily
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 3
                        color: parent.active ? theme.accent : "transparent"
                    }

                    MouseArea {
                        id: workspaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        // Hyprland runs Lua dispatchers, not hyprland.conf commands.
                        onClicked: Hyprland.dispatch(
                            "hl.dsp.focus({ workspace = " + parent.workspaceId + " })"
                        )
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        Row {
            spacing: 5
            height: 30

            Text {
                id: trayToggle
                anchors.verticalCenter: parent.verticalCenter
                text: bar.trayExpanded ? "▶" : "◀"
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
                visible: SystemTray.items.values.length > 0

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -5
                    onClicked: bar.trayExpanded = !bar.trayExpanded
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                visible: bar.trayExpanded

                Repeater {
                    model: SystemTray.items

                    Image {
                        required property var modelData
                        width: 18
                        height: 18
                        fillMode: Image.PreserveAspectFit
                        source: /blueman|bluetooth/i.test(modelData.id + " " + modelData.title)
                            ? "file:///usr/share/icons/Papirus-Dark/16x16/devices/bluetooth.svg"
                            : (modelData.icon.startsWith("image://")
                                ? modelData.icon : Quickshell.iconPath(modelData.icon))

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                                    const position = parent.mapToItem(bar.contentItem, 0, parent.height)
                                    modelData.display(bar, position.x, position.y)
                                }
                                else
                                    modelData.activate()
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: networkButton
            Layout.leftMargin: 10
            implicitWidth: networkContents.implicitWidth
            height: 30

            Row {
                id: networkContents
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !!bar.activeNetwork
                    text: ""
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bar.activeNetwork ? bar.activeNetwork.name : "offline"
                    width: Math.min(implicitWidth, 220)
                    elide: Text.ElideRight
                    color: bar.activeNetwork ? theme.foreground : theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bar.networkMenuOpen = !bar.networkMenuOpen
            }
        }

        Item {
            id: bluetoothButton
            Layout.leftMargin: 10
            implicitWidth: bluetoothContents.implicitWidth
            height: 30
            visible: !!Bluetooth.defaultAdapter

            Row {
                id: bluetoothContents
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property int connectedCount: Bluetooth.devices.values
                        .filter(device => device.connected).length
                    text: Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.enabled
                        ? "off" : connectedCount > 0 ? "(" + connectedCount + ")" : "on"
                    color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                        ? theme.foreground : theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bar.bluetoothMenuOpen = !bar.bluetoothMenuOpen
            }
        }

        Text {
            Layout.leftMargin: 12
            text: "|"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 13
        }

        Item {
            id: batteryButton
            Layout.leftMargin: 12
            height: 30
            implicitWidth: batteryInfo.implicitWidth

            Row {
                id: batteryInfo
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    visible: bar.battery && bar.battery.isPresent
                    text: {
                        const charging = bar.battery.state === UPowerDeviceState.Charging
                        const percent = Math.round(bar.battery.percentage * 100)
                        const profile = PowerProfiles.profile === PowerProfile.PowerSaver ? "E"
                            : PowerProfiles.profile === PowerProfile.Balanced ? "B"
                            : PowerProfiles.profile === PowerProfile.Performance ? "P" : "?"
                        return "bat: " + percent + "%" + (charging ? "+" : "")
                            + " (" + profile + ")"
                    }
                    color: bar.battery && bar.battery.percentage <= 0.15
                        ? theme.warning : theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: bar.batteryMenuOpen = !bar.batteryMenuOpen
            }
        }

        Text {
            Layout.leftMargin: 12
            text: "|"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            Layout.leftMargin: 12
            text: "key: " + bar.layoutCode
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            id: volumeButton
            Layout.leftMargin: 12
            text: "vol: " + (bar.sink && bar.sink.audio
                ? (bar.sink.audio.muted ? "mute"
                    : Math.round(bar.sink.audio.volume * 100) + "%")
                : "—")
            color: bar.sink && bar.sink.audio && bar.sink.audio.muted
                ? theme.muted : theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                onClicked: bar.audioMenuOpen = !bar.audioMenuOpen
            }
        }

        Text {
            Layout.leftMargin: 12
            text: "|"
            color: theme.muted
            font.family: theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            id: dateButton
            Layout.leftMargin: 12
            text: Qt.formatDateTime(clock.date, "yyyy-MM-dd HH:mm")
            color: theme.foreground
            font.family: theme.fontFamily
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                onClicked: bar.calendarOpen = !bar.calendarOpen
            }
        }
    }
}

// Read the Huawei driver directly; UPower can report a different threshold.
FileView {
    id: thresholds
    path: "/sys/devices/platform/huawei-wmi/charge_control_thresholds"
    preload: true
    watchChanges: false
    printErrors: false
}

Timer {
    id: thresholdRefresh
    interval: 800
    onTriggered: thresholds.reload()
}

PopupWindow {
    id: batteryMenu
    visible: bar.batteryMenuOpen
    HoverDismiss {
        popup: batteryMenu
        button: batteryButton
        onDismissed: bar.batteryMenuOpen = false
    }
    anchor.window: bar
    // Center the popup on the battery label, keeping it on-screen.
    anchor.rect.x: Math.max(8, Math.min(bar.width - implicitWidth - 8,
        batteryButton.parent.parent.x + batteryButton.parent.x + batteryButton.x
            + (batteryButton.width - implicitWidth) / 2))
    anchor.rect.y: bar.height + 2
    implicitWidth: 260
    implicitHeight: 246
    color: theme.surface

    Rectangle {
        anchors.fill: parent
        color: theme.surface
        border.color: theme.activeBorder
        border.width: 1
        radius: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                height: 24

                Text {
                    text: "Battery"
                    color: theme.foreground
                    font.family: theme.fontFamily
                    font.pixelSize: 13
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "×"
                    color: theme.muted
                    font.family: theme.fontFamily
                    font.pixelSize: 16
                    Layout.rightMargin: 2
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: bar.batteryMenuOpen = false
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: bar.battery && bar.battery.isPresent
                    ? "Charge          " + Math.round(bar.battery.percentage * 100) + "%"
                    : "Battery unavailable"
                color: theme.foreground
                font.family: theme.fontFamily
                font.pixelSize: 13
            }

            Text {
                readonly property string limit: thresholds.text().trim()
                Layout.fillWidth: true
                text: "Charge limit    "
                    + (/^\d+\s+\d+$/.test(limit) ? limit.replace(/\s+/, "–") + "%" : "unavailable")
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
            }

            Text {
                Layout.fillWidth: true
                readonly property bool charging: bar.battery
                    && bar.battery.state === UPowerDeviceState.Charging
                readonly property bool discharging: bar.battery
                    && bar.battery.state === UPowerDeviceState.Discharging
                readonly property real seconds: !bar.battery ? 0
                    : charging ? bar.battery.timeToFull
                    : discharging ? bar.battery.timeToEmpty : 0
                readonly property int minutes: Math.round(seconds / 60)
                text: (charging ? "Until full      " : "Time remaining  ")
                    + (seconds > 0
                        ? Math.floor(minutes / 60) + "h " + (minutes % 60) + "m"
                        : "unavailable")
                color: theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: theme.border
            }

            Repeater {
                model: [
                    { name: "Power saver", profile: PowerProfile.PowerSaver },
                    { name: "Balanced", profile: PowerProfile.Balanced },
                    { name: "Performance", profile: PowerProfile.Performance }
                ]

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 30
                    radius: 0
                    color: PowerProfiles.profile === modelData.profile
                        ? theme.hover : (profileMouse.containsMouse ? theme.hover : "transparent")

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: PowerProfiles.profile === modelData.profile
                            ? theme.foreground : theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 12
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 16
                        color: PowerProfiles.profile === modelData.profile
                            ? theme.accent : "transparent"
                    }

                    MouseArea {
                        id: profileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            PowerProfiles.profile = modelData.profile
                            thresholdRefresh.restart()
                        }
                    }
                }
            }
        }
    }
}

WifiMenu {
    id: networkMenu
    visible: bar.networkMenuOpen
    barWindow: bar
    button: networkButton
    palette: theme
    onCloseRequested: bar.networkMenuOpen = false
}

AudioMenu {
    visible: bar.audioMenuOpen
    barWindow: bar
    button: volumeButton
    palette: theme
    onCloseRequested: bar.audioMenuOpen = false
}

BluetoothMenu {
    visible: bar.bluetoothMenuOpen
    barWindow: bar
    button: bluetoothButton
    palette: theme
    onCloseRequested: bar.bluetoothMenuOpen = false
}

CalendarMenu {
    visible: bar.calendarOpen
    barWindow: bar
    button: dateButton
    palette: theme
    date: clock.date
    onCloseRequested: bar.calendarOpen = false
}
}
