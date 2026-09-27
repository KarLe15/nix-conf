import QtQuick
import "../Config"

// One of the bar's icon buttons. Disabled when the daemon says the action is not
// available (an unprivileged greeter cannot always power the machine off).
Rectangle {
    id: root

    property string glyph
    property color fg: Theme.subtext0
    property color hoverBg: Theme.surface0
    property color hoverFg: Theme.fg
    property string tip: ""

    signal activated()

    width: 38
    height: 34
    radius: 11
    color: mouse.containsMouse && enabled ? root.hoverBg : "transparent"
    opacity: enabled ? 1 : 0.35

    Glyph {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: 20
        color: mouse.containsMouse && root.enabled ? root.hoverFg : root.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
