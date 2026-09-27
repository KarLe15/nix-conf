import QtQuick
import "../Config"
import "../widgets"

// Ambience: the dial-home device idling next to the gate's address book. No
// input and no SDDM state — each monitor has its own QML engine, so this screen
// knows nothing about what is being typed on the gate.
Item {
    id: root

    ScreenBackdrop {
        anchors.fill: parent
        focusX: 0.35
    }

    Clock { id: clock }

    AmbienceBar {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.barMargin
        title: "Dispositif de composition"
        timeText: clock.timeSec
    }

    Item {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Theme.barMargin + Theme.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Dhd {
            id: dhd
            x: 80
            anchors.verticalCenter: parent.verticalCenter
            litColor: Theme[Config.colors.chevron]
        }

        Column {
            id: side
            anchors.left: parent.left
            anchors.leftMargin: 80 + dhd.width + 72
            anchors.right: parent.right
            anchors.rightMargin: 80
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            SectionHeader {
                width: Math.min(620, side.width)
                label: "Adresses enregistrées"
                value: MissionData.addresses.length.toString()
            }

            Item { width: 1; height: 6 }

            AddressList {
                width: Math.min(620, side.width)
            }

            Item { width: 1; height: 34 }

            SectionHeader {
                width: Math.min(620, side.width)
                label: "Dernière connexion"
            }

            Item { width: 1; height: 18 }

            Row {
                spacing: 16

                Rectangle {
                    width: 50
                    height: 50
                    radius: 25
                    color: Theme.surface0
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "RK"
                        font.family: Theme.fontUi
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        color: Theme.lavender
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        text: MissionData.lastLogin.who
                        font.family: Theme.fontUi
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }

                    Text {
                        text: MissionData.lastLogin.when
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: Theme.dim
                    }
                }
            }
        }
    }

    ScreenTag {
        anchors.right: parent.right
        anchors.rightMargin: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
    }
}
