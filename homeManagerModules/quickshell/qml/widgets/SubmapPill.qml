import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/"

// Active-submap indicator. Hyprland submaps are modal: while one is active ONLY
// its binds fire, so knowing you are in one matters — this is the pill that says
// so. Always visible, showing the `default` entry when no submap is active, so
// the bar layout stays put.
//
// Name, icon and colour come from Config.submaps, generated from the `submaps`
// attrset in the shortcuts preset — the same preset that defines the submaps by
// having entries name them, so there is one source of truth.
//
// Quickshell has no submap property, so the active name comes from the raw IPC
// event stream: Hyprland posts `submap` with the name on entry and an empty
// payload on reset (Actions::setSubmap). An initial `hyprctl submap` covers the
// case where the bar starts while a submap is already active — note that command
// spells the idle state "default", the Lua API spells it "", and the dispatcher
// "reset".
Rectangle {
    id: root

    property string submap: ""
    readonly property bool active: submap !== ""

    readonly property string key: active ? submap : "default"
    readonly property var meta: Config.submaps[root.key] || null

    // Fall back gracefully when a submap has no entry in the preset: show its raw
    // name rather than nothing, so a new submap is visible before it is styled.
    readonly property string label: meta && meta.name ? meta.name : root.key
    readonly property string glyph: meta && meta.icon ? meta.icon : ""
    readonly property color fill:
        (meta && meta.color && Theme[meta.color] !== undefined)
            ? Theme[meta.color]
            : (active ? Theme.peach : Theme.surface)

    radius: Theme.pillRadius
    color: root.fill
    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + 20

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "submap")
                return;
            // Empty payload means "back to default".
            const name = event.data ? event.data.trim() : "";
            root.submap = (name === "default") ? "" : name;
        }
    }

    Process {
        running: true
        command: ["hyprctl", "submap"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = this.text.trim();
                root.submap = (s === "" || s === "default") ? "" : s;
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            opacity: root.active ? 1.0 : 0.6
            color: root.active ? Theme.onAccent : Theme.fg
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: root.active
            opacity: root.active ? 1.0 : 0.6
            color: root.active ? Theme.onAccent : Theme.fg
        }
    }
}
