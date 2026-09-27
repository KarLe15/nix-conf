import QtQuick
import "../Config"

// A column heading: spaced-out uppercase kicker on the left, an optional status
// or count on the right, and a rule underneath.
Item {
    id: root

    property string label
    property string value: ""
    property color valueColor: Theme.dim

    implicitHeight: kicker.height + 14 + 1

    Text {
        id: kicker
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.label.toUpperCase()
        font.family: Theme.fontMono
        font.pixelSize: 14
        font.bold: true
        font.letterSpacing: 3
        color: Theme.label
    }

    Text {
        anchors.right: parent.right
        anchors.baseline: kicker.baseline
        visible: text.length > 0
        text: root.value
        font.family: Theme.fontMono
        font.pixelSize: 14
        font.bold: true
        font.letterSpacing: 2
        color: root.valueColor
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.border
    }
}
