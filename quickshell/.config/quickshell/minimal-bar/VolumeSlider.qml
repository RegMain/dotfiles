import QtQuick

// Writes to PipeWire only while the user drags or clicks the slider.
Rectangle {
    id: slider
    required property var node
    required property var colors
    implicitHeight: 18
    color: colors.hover

    Rectangle {
        width: slider.node && slider.node.audio
            ? Math.round(slider.width * Math.max(0, Math.min(1, slider.node.audio.volume))) : 0
        height: parent.height
        color: slider.colors.accent
    }

    MouseArea {
        anchors.fill: parent
        enabled: !!slider.node && !!slider.node.audio
        onPressed: mouse => slider.node.audio.volume =
            Math.max(0, Math.min(1, mouse.x / width))
        onPositionChanged: mouse => {
            if (pressed)
                slider.node.audio.volume = Math.max(0, Math.min(1, mouse.x / width))
        }
    }
}
