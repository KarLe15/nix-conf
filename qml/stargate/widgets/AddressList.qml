import QtQuick
import "../Config"

// The DHD's address book. Content comes from Config/MissionData.qml — the
// greeter has no session history and no network, so these are set dressing.
Column {
    id: root

    Repeater {
        model: MissionData.addresses

        Item {
            readonly property color stateColor: Theme[modelData.color]

            width: root.width
            height: name.height + 10 + code.height + 32 + 1

            Text {
                id: name
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.top: parent.top
                anchors.topMargin: 16
                text: modelData.name
                font.family: Theme.fontUi
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: Theme.fg
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: name.verticalCenter
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 9
                    height: 9
                    rotation: 45
                    color: stateColor
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.state.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.5
                    color: stateColor
                }
            }

            Text {
                id: code
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.top: name.bottom
                anchors.topMargin: 10
                text: modelData.code
                font.family: Theme.fontMono
                font.pixelSize: 15
                font.weight: Font.Medium
                font.letterSpacing: 1
                color: Theme.label
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.baseline: code.baseline
                text: modelData.note
                font.family: Theme.fontUi
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Theme.dim
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
