import QtQuick
import "../Config"
import "../widgets"

// Ambience: the gate's power budget and what the MALP is reporting from the
// other side. Display only, like the DHD screen.
Item {
    id: root

    readonly property real columnWidth: (width - 180 - 80) / 2

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
        title: "Alimentation · Télémétrie"
        timeText: clock.timeSec
    }

    Item {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Theme.barMargin + Theme.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        // ---- Left: the zero point modules -----------------------------------
        Column {
            id: power
            x: 90
            anchors.verticalCenter: parent.verticalCenter
            width: root.columnWidth
            spacing: 0

            SectionHeader {
                width: power.width
                label: "E2PZ · Module de point zéro"
                value: MissionData.zpmActive
                valueColor: Theme.yellow
            }

            Item { width: 1; height: 10 }

            Rectangle {
                width: power.width
                height: crystals.height + 70
                radius: 22
                border.width: 1
                border.color: Theme.border

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.mantle }
                    GradientStop { position: 1.0; color: Theme.crust }
                }

                Row {
                    id: crystals
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 40
                    spacing: 40

                    Repeater {
                        model: MissionData.zpms

                        Column {
                            id: zpmCol
                            readonly property var tone: MissionData.zpmTones[modelData.tone]

                            spacing: 18

                            Zpm {
                                anchors.horizontalCenter: parent.horizontalCenter
                                tone: zpmCol.tone
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.pct
                                font.family: Theme.fontMono
                                font.pixelSize: 26
                                font.bold: true
                                color: Theme[zpmCol.tone.tone]
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label.toUpperCase()
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.letterSpacing: 2
                                color: Theme.dim
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 22 }

            Row {
                spacing: 12

                Glyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MissionData.autonomyIcon
                    font.pixelSize: 20
                    color: Theme.yellow
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MissionData.zpmAutonomyLead
                    font.family: Theme.fontUi
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: Theme.subtext0
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: MissionData.zpmAutonomy
                    font.family: Theme.fontUi
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.fg
                }
            }
        }

        // ---- Right: what the MALP sees --------------------------------------
        Column {
            id: probe
            x: 90 + root.columnWidth + 80
            anchors.verticalCenter: parent.verticalCenter
            width: root.columnWidth
            spacing: 0

            SectionHeader {
                width: probe.width
                label: "Télémétrie MALP"
                value: MissionData.telemetryState
                valueColor: Theme.green
            }

            Item { width: 1; height: 6 }

            TelemetryList {
                width: probe.width
            }

            Item { width: 1; height: 28 }

            Row {
                spacing: 14

                Repeater {
                    model: MissionData.cards

                    StatCard {
                        width: (probe.width - 14) / 2
                        kicker: modelData.kicker
                        glyph: modelData.icon
                        value: modelData.value
                        tint: Theme[modelData.color]
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
