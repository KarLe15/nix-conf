import QtQuick
import "../Config"

// The dial sequence, chevron by chevron. It reads out the same state the gate
// shows, in words — which is also what tells you a login failed when the gate's
// own colour change is easy to miss.
Column {
    id: root

    property int lit: 0
    property bool failed: false
    property bool locked: false

    property color chevronColor: Theme.peach
    property color horizonColor: Theme.blue
    property color errorColor: Theme.red

    Repeater {
        model: 7

        Item {
            readonly property int order: index + 1
            readonly property bool engaged: order <= root.lit

            readonly property string stateText:
                !engaged ? "VEILLE"
                         : root.failed ? "ANNULÉ"
                         : (root.locked && order === 7) ? "VERROUILLÉ"
                         : "ENCLENCHÉ"

            readonly property color stateColor:
                !engaged ? Theme.surface2
                         : root.failed ? root.errorColor
                         : (root.locked && order === 7) ? root.horizonColor
                         : root.chevronColor

            width: root.width
            height: label.height + 22 + 1

            // A diamond, echoing the chevron's own shape at list scale.
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: label.verticalCenter
                width: 10
                height: 10
                rotation: 45
                color: engaged ? stateColor : Theme.surface0

                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }

            Text {
                id: label
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.top: parent.top
                anchors.topMargin: 11
                text: "Chevron " + order
                font.family: Theme.fontMono
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: engaged ? Theme.fg : Theme.dim
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.baseline: label.baseline
                text: stateText
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                color: stateColor

                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.hairline
            }
        }
    }
}
