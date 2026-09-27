import QtQuick
import "../Config"

// One of the two standing indicators next to the telemetry: iris state and the
// base's alert level.
Rectangle {
    id: root

    property string kicker
    property string glyph
    property string value
    property color tint: Theme.blue

    implicitHeight: 18 + kickerText.height + 12 + valueRow.height + 18
    radius: 16
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    Text {
        id: kickerText
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.top: parent.top
        anchors.topMargin: 18
        text: root.kicker.toUpperCase()
        font.family: Theme.fontMono
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 2
        color: Theme.dim
    }

    Row {
        id: valueRow
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.top: kickerText.bottom
        anchors.topMargin: 12
        spacing: 10

        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            font.pixelSize: 24
            color: root.tint
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.value
            font.family: Theme.fontMono
            font.pixelSize: 22
            font.bold: true
            color: root.tint
        }
    }
}
