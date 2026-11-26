import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root
    required property var barWindow
    required property Item button
    required property var palette
    required property date date
    signal closeRequested()

    property date displayedMonth: new Date(date.getFullYear(), date.getMonth(), 1)
    readonly property string monthTitle: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ][displayedMonth.getMonth()] + ", " + displayedMonth.getFullYear()
    readonly property int firstWeekday: (displayedMonth.getDay() + 6) % 7
    readonly property int daysInMonth: new Date(
        displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 0
    ).getDate()
    property var rangeStart: null
    property var rangeEnd: null
    property var foundDate: null
    property bool searching: false
    property bool searchError: false
    readonly property string todayTitle: "Today: "
        + ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][(date.getDay() + 6) % 7]
        + ", " + date.getDate() + " "
        + ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][date.getMonth()]
        + " " + date.getFullYear()
    readonly property int selectedDays: rangeStart && rangeEnd
        ? Math.abs(dayNumber(rangeEnd) - dayNumber(rangeStart)) + 1 : 0
    readonly property var span: rangeStart && rangeEnd
        ? calendarSpan(rangeStart, rangeEnd) : null

    // UTC calendar ordinals avoid 23/25-hour days around daylight-saving changes.
    function dayNumber(value) {
        return Date.UTC(value.getFullYear(), value.getMonth(), value.getDate()) / 86400000
    }

    function selectDay(day) {
        const chosen = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), day)
        if (!rangeStart || rangeEnd) {
            rangeStart = chosen
            rangeEnd = null
        } else {
            rangeEnd = chosen
        }
    }

    function calendarSpan(first, second) {
        const start = dayNumber(first) <= dayNumber(second) ? first : second
        const end = dayNumber(first) <= dayNumber(second) ? second : first
        const endExclusive = new Date(Date.UTC(
            end.getFullYear(), end.getMonth(), end.getDate() + 1
        ))
        let months = (endExclusive.getUTCFullYear() - start.getFullYear()) * 12
            + endExclusive.getUTCMonth() - start.getMonth()
        let anchor = Date.UTC(start.getFullYear(), start.getMonth() + months, start.getDate())
        while (anchor > endExclusive.getTime()) {
            months--
            anchor = Date.UTC(start.getFullYear(), start.getMonth() + months, start.getDate())
        }
        return {
            years: Math.floor(months / 12),
            months: months % 12,
            days: Math.round((endExclusive.getTime() - anchor) / 86400000)
        }
    }

    function shiftMonth(offset) {
        displayedMonth = new Date(
            displayedMonth.getFullYear(), displayedMonth.getMonth() + offset, 1
        )
    }

    function findDate(value) {
        const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value.trim())
        if (!match) {
            searchError = true
            return
        }
        const year = Number(match[1])
        const month = Number(match[2])
        const day = Number(match[3])
        const candidate = new Date(year, month - 1, day)
        if (year < 100 || candidate.getFullYear() !== year
                || candidate.getMonth() !== month - 1 || candidate.getDate() !== day) {
            searchError = true
            return
        }
        foundDate = candidate
        displayedMonth = new Date(year, month - 1, 1)
        searchError = false
        searching = false
    }

    onVisibleChanged: {
        if (visible) {
            displayedMonth = new Date(date.getFullYear(), date.getMonth(), 1)
        } else {
            searching = false
            searchError = false
            foundDate = null
        }
    }

    HoverDismiss {
        popup: root
        button: root.button
        onDismissed: root.closeRequested()
    }

    anchor.window: barWindow
    // Popup windows do not receive keyboard input unless they grab focus.
    grabFocus: true
    // The calendar stays aligned to the right edge, not the moving clock label.
    anchor.rect.x: Math.max(0, barWindow.width - implicitWidth - 8)
    anchor.rect.y: barWindow.height + 2
    implicitWidth: 300
    implicitHeight: 342
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
                    text: "Calendar"
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
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        onClicked: root.closeRequested()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                ActionButton {
                    colors: root.palette
                    label: "‹"
                    onClicked: root.shiftMonth(-1)
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    implicitWidth: 150
                    implicitHeight: 26
                    color: monthMouse.containsMouse ? root.palette.hover : "transparent"
                    visible: !root.searching
                    Text {
                        anchors.centerIn: parent
                        text: root.monthTitle
                        color: root.palette.foreground
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: monthMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.searchError = false
                            root.searching = true
                            dateInput.text = ""
                            dateInput.forceActiveFocus()
                        }
                    }
                }
                Rectangle {
                    implicitWidth: 150
                    implicitHeight: 26
                    visible: root.searching
                    color: root.palette.surface
                    border.width: 1
                    border.color: root.searchError ? root.palette.warning : root.palette.accent
                    TextInput {
                        id: dateInput
                        anchors.fill: parent
                        anchors.margins: 5
                        color: root.palette.foreground
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                        selectByMouse: true
                        maximumLength: 10
                        onAccepted: root.findDate(text)
                        Keys.onEscapePressed: root.searching = false
                    }
                    Text {
                        anchors.fill: dateInput
                        visible: !dateInput.text
                        text: "YYYY-MM-DD"
                        color: root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 12
                    }
                }
                Item { Layout.fillWidth: true }
                ActionButton {
                    colors: root.palette
                    label: "›"
                    onClicked: root.shiftMonth(1)
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property var modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: root.palette.muted
                        font.family: root.palette.fontFamily
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property int day: index - root.firstWeekday + 1
                        readonly property bool current: day > 0
                            && day <= root.daysInMonth
                            && root.displayedMonth.getMonth() === root.date.getMonth()
                            && root.displayedMonth.getFullYear() === root.date.getFullYear()
                            && day === root.date.getDate()
                        readonly property bool found: day > 0 && day <= root.daysInMonth
                            && root.foundDate
                            && root.displayedMonth.getFullYear() === root.foundDate.getFullYear()
                            && root.displayedMonth.getMonth() === root.foundDate.getMonth()
                            && day === root.foundDate.getDate()
                        readonly property bool inRange: day > 0
                            && day <= root.daysInMonth && root.rangeStart
                            && root.dayNumber(new Date(
                                root.displayedMonth.getFullYear(),
                                root.displayedMonth.getMonth(), day
                            )) >= Math.min(
                                root.dayNumber(root.rangeStart),
                                root.dayNumber(root.rangeEnd || root.rangeStart)
                            )
                            && root.dayNumber(new Date(
                                root.displayedMonth.getFullYear(),
                                root.displayedMonth.getMonth(), day
                            )) <= Math.max(
                                root.dayNumber(root.rangeStart),
                                root.dayNumber(root.rangeEnd || root.rangeStart)
                            )
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: inRange ? root.palette.accent
                            : found || (current && !root.foundDate) ? root.palette.hover
                            : dayMouse.containsMouse ? "#252525" : "transparent"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 16
                            color: (parent.found || (parent.current && !root.foundDate))
                                && !parent.inRange
                                ? root.palette.accent : "transparent"
                        }
                        Text {
                            anchors.centerIn: parent
                            text: parent.day > 0 && parent.day <= root.daysInMonth
                                ? parent.day : ""
                            color: parent.found || (parent.current && !root.foundDate)
                                || parent.inRange
                                ? root.palette.foreground : root.palette.muted
                            font.family: root.palette.fontFamily
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            enabled: parent.day > 0 && parent.day <= root.daysInMonth
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton)
                                    root.selectDay(parent.day)
                                else {
                                    root.rangeStart = null
                                    root.rangeEnd = null
                                    root.foundDate = new Date(
                                        root.displayedMonth.getFullYear(),
                                        root.displayedMonth.getMonth(), parent.day
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: root.todayTitle
                color: root.palette.muted
                font.family: root.palette.fontFamily
                font.pixelSize: 12
            }
            Text {
                text: root.searching ? (root.searchError
                        ? "Invalid date; use YYYY-MM-DD" : "Enter date and press Enter")
                    : root.span
                    ? "Selected: " + root.selectedDays + " days\n"
                        + "Span: " + root.span.years + " years, " + root.span.months
                        + " months, " + root.span.days + " days"
                    : root.rangeStart ? "Right-click an end date"
                        : "Right-click two dates to select"
                color: root.palette.foreground
                font.family: root.palette.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
