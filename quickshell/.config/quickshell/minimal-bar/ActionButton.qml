import QtQuick

Rectangle {
    id: button
    required property var colors
    required property string label
    signal clicked()

    implicitWidth: caption.implicitWidth + 18
    implicitHeight: 26
    color: mouse.containsMouse ? colors.hover : colors.surface
    border.color: colors.border
    border.width: 1

    Text {
        id: caption
        anchors.centerIn: parent
        text: button.label
        color: button.colors.foreground
        font.family: button.colors.fontFamily
        font.pixelSize: 12
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()
    }
}
