import QtQuick

// Let the pointer cross the small gap between a bar button and its popup.
Item {
    id: dismiss
    required property var popup
    required property Item button
    signal dismissed()

    width: 0
    height: 0

    HoverHandler {
        id: buttonHover
        parent: dismiss.button
    }

    HoverHandler {
        id: popupHover
        parent: dismiss.popup.contentItem
    }

    Timer {
        interval: 500
        running: dismiss.popup.visible && !buttonHover.hovered && !popupHover.hovered
        onTriggered: dismiss.dismissed()
    }
}
