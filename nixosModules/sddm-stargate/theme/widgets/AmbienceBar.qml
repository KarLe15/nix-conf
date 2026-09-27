import QtQuick
import "../Config"

// The bar the two display-only screens carry: which monitor this is, what it
// shows, the time, and a plain statement that nothing here takes input — the
// keyboard belongs to the gate.
TopBar {
    id: root

    property string title
    property string timeText

    hPadding: 16

    leftContent: Component {
        Row {
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Screen.name.toUpperCase()
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                color: Theme.label
            }

            BarDivider { anchors.verticalCenter: parent.verticalCenter }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                font.family: Theme.fontUi
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.fg
            }
        }
    }

    centerContent: Component {
        Text {
            text: root.timeText
            font.family: Theme.fontMono
            font.pixelSize: 16
            font.weight: Font.DemiBold
            color: Theme.fg
        }
    }

    rightContent: Component {
        Row {
            spacing: 8

            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                text: Config.icons.readOnly
                font.pixelSize: 17
                color: Theme.dim
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "AFFICHAGE SEUL"
                font.family: Theme.fontMono
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 1.5
                color: Theme.dim
            }
        }
    }
}
