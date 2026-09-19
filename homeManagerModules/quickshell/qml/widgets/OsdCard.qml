import QtQuick
import "root:/"

// OSD variant 9a — "On screen, live". A card carrying icon tile, title, value,
// level bar and device line. Proportions from the design; colours and fonts come
// from Theme rather than the mockup's own palette/typography.
Item {
    id: root
    required property var osd

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    opacity: osd.active ? 1.0 : 0.0
    // 180 ms fade + 6 px rise (design).
    transform: Translate { y: root.osd.active ? 0 : 6
        Behavior on y { NumberAnimation { duration: root.osd.cfg.fadeMs; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: root.osd.cfg.fadeMs } }

    Rectangle {
        id: card
        implicitWidth: Math.max(root.osd.cfg.cardWidth, row.implicitWidth + 32)
        implicitHeight: row.implicitHeight + 28
        radius: 18
        color: Theme.mantle
        border.color: Theme.surface0
        border.width: 1

        Row {
            id: row
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 13

            // Icon tile
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40
                radius: 11
                color: root.osd.fill
                Text {
                    anchors.centerIn: parent
                    text: root.osd.glyph
                    font.family: Theme.fontMono
                    font.pixelSize: 21
                    color: Theme.onAccent
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 53
                spacing: 8

                Item {
                    width: parent.width
                    height: titleText.implicitHeight
                    Text {
                        id: titleText
                        anchors.left: parent.left
                        text: root.osd.title.toUpperCase()
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.4
                        color: Theme.overlay1
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.osd.muted && root.osd.kind === "mic" ? "MUTED"
                            : root.osd.muted ? "MUTED"
                            : root.osd.pct + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        font.bold: true
                        color: root.osd.muted ? Theme.overlay1 : Theme.fg
                    }
                }

                // Level bar — 8 px, fill tweens, mute greys it but keeps the level
                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Theme.surface0
                    clip: true
                    Rectangle {
                        height: parent.height
                        radius: 4
                        width: parent.width * Math.max(0, Math.min(100, root.osd.pct)) / 100
                        color: root.osd.muted ? Theme.surface2 : root.osd.fill
                        Behavior on width { NumberAnimation { duration: 120 } }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.osd.cfg.showDevice
                    height: visible ? implicitHeight : 0
                    text: root.osd.deviceLine
                    elide: Text.ElideRight
                    font.family: Theme.fontUi
                    font.pixelSize: 11
                    color: Theme.overlay0
                }
            }
        }
    }
}
