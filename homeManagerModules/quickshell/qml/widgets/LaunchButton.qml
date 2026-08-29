import QtQuick
import Quickshell
import "root:/"

// Bar action button (Screen Bars · code screen shortcuts, next to the avatar). An
// icon-only filled pill that launches a shell command — supplied by the layout
// entry — detached, so the launched app outlives the click and the shell. Icon,
// color, and command all come from the preset (configurations/).
Rectangle {
    id: root
    property string icon: ""
    property string colorName: "surface"
    property string command: ""

    readonly property color fill:
        Theme[colorName] !== undefined ? Theme[colorName] : Theme.surface

    radius: Theme.pillRadius
    implicitHeight: Theme.pillHeight
    implicitWidth: Theme.pillHeight     // square, icon-only
    color: fill
    opacity: mouse.pressed ? 0.75 : (mouse.containsMouse ? 0.88 : 1.0)

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontIcon
        color: Theme.onAccent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.command.length > 0)
            Quickshell.execDetached(["sh", "-c", root.command])
    }
}
