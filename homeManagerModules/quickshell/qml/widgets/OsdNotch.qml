import QtQuick
import "root:/"

// OSD variant 9d — "Notch capsule". Designed for the Asahi laptop shell, where the
// black notch block itself widens to carry the level and shrinks back, so nothing
// new lands on the desktop. On a desktop there is no notch, so it reads as a
// capsule hanging from the top edge — included here for review, but 9a or 9c is
// the intended desktop choice (the artboard says so explicitly).
Item {
    id: root
    required property var osd

    readonly property int idleWidth: 168
    readonly property int openWidth: 320

    implicitWidth: capsule.width
    implicitHeight: capsule.height

    Rectangle {
        id: capsule
        width: root.osd.active ? root.openWidth : root.idleWidth
        height: Theme.barHeight
        // Darker than crust, as in the design: the notch is not part of the bar.
        color: Qt.rgba(Theme.crust.r * 0.55, Theme.crust.g * 0.55, Theme.crust.b * 0.6, 1.0)
        bottomLeftRadius: root.osd.active ? 17 : 15
        bottomRightRadius: root.osd.active ? 17 : 15
        clip: true

        // One width tween; the contents fade in behind it (design: 260 ms).
        Behavior on width {
            NumberAnimation { duration: 260; easing.type: Easing.OutQuint }
        }

        Row {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 11
            opacity: root.osd.active ? 1.0 : 0.0
            // The 260 ms width tween above is the notch's signature motion and stays a
            // design constant; only the content fade follows the configured fadeMs.
            Behavior on opacity { NumberAnimation { duration: root.osd.cfg.fadeMs } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.osd.glyph
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: root.osd.fill
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34 - valueText.implicitWidth
                height: 5
                radius: 3
                color: Theme.border
                clip: true
                Rectangle {
                    height: parent.height
                    radius: 3
                    width: parent.width * Math.max(0, Math.min(100, root.osd.pct)) / 100
                    color: root.osd.muted ? Theme.surface2 : root.osd.fill
                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }

            Text {
                id: valueText
                anchors.verticalCenter: parent.verticalCenter
                text: root.osd.muted ? "MUTE" : root.osd.pct + "%"
                font.family: Theme.fontMono
                font.pixelSize: 12   // design says 11.5; pixelSize is an int
                font.bold: true
                color: Theme.fg
            }
        }
    }
}
