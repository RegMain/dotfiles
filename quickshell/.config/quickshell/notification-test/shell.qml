import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Standalone notification server, also usable for isolated previews.
ShellRoot {
    NotificationServer {
        id: notifications
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true
            const items = trackedNotifications.values
            if (items.length > 3)
                items[0].expire()
        }
    }

    PanelWindow {
        id: toasts
        anchors {
            bottom: true
            right: true
        }
        margins {
            bottom: 30
            right: 15
        }
        exclusiveZone: 0
        focusable: false
        visible: notifications.trackedNotifications.values.length > 0
        implicitWidth: 360
        implicitHeight: stack.implicitHeight
        color: "transparent"

        Column {
            id: stack
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: notifications.trackedNotifications

                Rectangle {
                    id: toast
                    required property var modelData
                    readonly property var entry: modelData
                    width: stack.width
                    implicitHeight: content.implicitHeight + 20
                    height: implicitHeight
                    color: "#161616"
                    border.width: 1
                    border.color: "#ffffff"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 1
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        width: 5
                        color: "#6d73ca"
                    }

                    HoverHandler { id: hover }

                    Timer {
                        interval: toast.entry.expireTimeout > 0
                            ? Math.max(1000, toast.entry.expireTimeout) : 5000
                        running: !hover.hovered
                            && toast.entry.urgency !== NotificationUrgency.Critical
                            && toast.entry.expireTimeout !== 0
                        onTriggered: toast.entry.expire()
                    }

                    Column {
                        id: content
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        anchors.leftMargin: 15
                        spacing: 4

                        Row {
                            width: parent.width
                            spacing: 8
                            Image {
                                id: appIcon
                                readonly property string icon: toast.entry.appIcon === "-"
                                    ? "" : toast.entry.appIcon || ""
                                source: !icon ? ""
                                    : icon.startsWith("/") || icon.startsWith("file:")
                                        || icon.startsWith("image://")
                                        ? icon : Quickshell.iconPath(icon)
                                width: visible ? 20 : 0
                                height: 20
                                visible: !!icon && status === Image.Ready
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                width: parent.width - closeButton.width - appIcon.width
                                    - (appIcon.visible ? 2 : 1) * parent.spacing
                                text: toast.entry.appName || "Notification"
                                elide: Text.ElideRight
                                color: "#a2a3ad"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: closeButton
                                text: "×"
                                color: "#a2a3ad"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    onClicked: toast.entry.dismiss()
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Image {
                                id: notificationImage
                                width: visible ? 48 : 0
                                height: visible ? 48 : 0
                                source: toast.entry.image === "image://icon/-"
                                    ? "" : toast.entry.image || ""
                                visible: !!source && status === Image.Ready
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                width: parent.width - (notificationImage.visible
                                    ? notificationImage.width + parent.spacing : 0)
                                spacing: 3
                                Text {
                                    width: parent.width
                                    text: toast.entry.summary
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    color: "#f0f0f2"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }
                                Text {
                                    width: parent.width
                                    visible: !!toast.entry.body
                                    text: toast.entry.body
                                    textFormat: Text.PlainText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    color: "#a2a3ad"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8
                            visible: toast.entry.actions.length > 0
                            Repeater {
                                model: toast.entry.actions
                                Rectangle {
                                    required property var modelData
                                    readonly property var action: modelData
                                    width: caption.implicitWidth + 16
                                    height: 25
                                    color: actionMouse.containsMouse ? "#2d2d2d" : "#161616"
                                    border.color: "#444444"
                                    border.width: 1
                                    Text {
                                        id: caption
                                        anchors.centerIn: parent
                                        text: action.text
                                        color: "#f0f0f2"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: action.invoke()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
