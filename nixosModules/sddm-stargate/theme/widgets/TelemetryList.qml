import QtQuick
import "../Config"

// MALP environment readout: a glyph, a label over its own meter, and the value.
Column {
    id: root

    Repeater {
        model: MissionData.telemetry

        Item {
            readonly property color tint: Theme[modelData.color]

            width: root.width
            height: label.height + 10 + 5 + 30 + 1

            Glyph {
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: label.verticalCenter
                width: 28
                text: modelData.icon
                font.pixelSize: 21
                color: tint
            }

            Text {
                id: label
                anchors.left: parent.left
                anchors.leftMargin: 44
                anchors.right: value.left
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 15
                text: modelData.label
                elide: Text.ElideRight
                font.family: Theme.fontUi
                font.pixelSize: 17
                font.weight: Font.DemiBold
                color: Theme.fg
            }

            Rectangle {
                id: track
                anchors.left: label.left
                anchors.right: label.right
                anchors.top: label.bottom
                anchors.topMargin: 10
                height: 5
                radius: 3
                color: Theme.hairline

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * modelData.fill
                    radius: 3
                    color: tint
                }
            }

            Text {
                id: value
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: label.verticalCenter
                text: modelData.value
                font.family: Theme.fontMono
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: Theme.fg
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
