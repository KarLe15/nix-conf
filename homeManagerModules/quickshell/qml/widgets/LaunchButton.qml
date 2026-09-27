import QtQuick
import Quickshell
import "root:/"

// Bar action button (Screen Bars · code screen shortcuts, next to the avatar). An
// icon-only filled pill that launches a shell command — supplied by the layout
// entry — through `uwsm app`, so the launched app outlives the click *and* the
// shell. Icon, color, and command all come from the preset (configurations/).
Rectangle {
    id: root
    property string icon: ""
    property string colorName: "surface"
    property string command: ""

    readonly property color fill:
        Theme[colorName] !== undefined ? Theme[colorName] : Theme.surface

    // Names the scope after the binary, so it lands as `app-<name>-<id>.scope`
    // instead of `app-sh-<id>.scope` — the preset's quoting still needs `sh -c`,
    // which is all uwsm would otherwise see.
    readonly property string appName:
        (command.trim().split(/\s+/)[0] || "app").split("/").pop()

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
        // `uwsm app` puts the command in its own scope under app-graphical.slice.
        // execDetached alone only detaches from the *process* — the child inherits
        // this unit's cgroup, and `KillMode=mixed` then SIGKILLs it every time a
        // rebuild restarts the shell.
        onClicked: if (root.command.length > 0)
            Quickshell.execDetached([
                "uwsm", "app", "-a", root.appName, "--", "sh", "-c", root.command
            ])
    }
}
