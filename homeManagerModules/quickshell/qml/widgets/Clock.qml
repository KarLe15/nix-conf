import QtQuick
import "root:/"

// Left island: clock glyph + HH:mm, a hairline divider, then the date. Mirrors
// the neutral (surface) clock pill from the Screen Bars mockup.
Rectangle {
    id: root
    radius: Theme.pillRadius
    color: Theme.surface
    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + 26

    property string time: ""
    property string date: ""

    function refresh() {
        const now = new Date();
        root.time = Qt.formatDateTime(now, "HH:mm");
        root.date = Qt.formatDateTime(now, "ddd d MMM");
    }

    Component.onCompleted: refresh()

    // Tick every second; format shows to the minute.
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "" // nf-fa-clock_o
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: Theme.lavender
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.time
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: Theme.fg
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(Theme.pillHeight * 0.5)
            color: Theme.surfaceAlt
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.date
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            color: Theme.subtext0
        }
    }
}
