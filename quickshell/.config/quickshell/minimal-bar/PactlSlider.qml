import QtQuick

// An application stream is changed only when the user releases the pointer.
Rectangle {
    id: slider
    required property var colors
    required property real volume
    signal valueSelected(real value)

    implicitHeight: 18
    color: colors.hover

    Rectangle {
        width: Math.round(slider.width * Math.max(0, Math.min(1, slider.volume)))
        height: parent.height
        color: slider.colors.accent
    }

    MouseArea {
        anchors.fill: parent
        onReleased: mouse => {
            if (containsMouse)
                slider.valueSelected(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }
}
