import QtQuick
import Quickshell.Hyprland
import "root:/"

// Center island: this monitor's workspace pills (id · glyph). The slot set +
// glyphs come from the generated Config singleton (the repo's workspaces preset);
// live focus and occupancy come from Hyprland. Click a pill to switch workspace.
//
// Sessions: Config.workspaces holds SLOTS (1..9), not absolute workspace ids. The
// active session is derived from the focused workspace id — no extra channel is
// needed, because the bar already tracks it:
//
//     session = ((id - 1) / band) + 1     slot = ((id - 1) % band) + 1
//
// so in session 7 the same nine slots address workspaces 61..69, keeping their
// glyphs. See docs/HYPRLAND_SESSIONS.md.
Rectangle {
    id: root
    property string screenName: ""

    radius: Theme.wsRadius
    color: Theme.wsContainer
    implicitHeight: Theme.wsHeight
    implicitWidth: strip.implicitWidth + 14

    // Screen Bars shows the full 1..9 slot strip on every monitor (sorted by slot).
    readonly property var items:
        Config.workspaces.slice().sort((a, b) => a.id - b.id)

    // Highlight the focused workspace (where input focus is), not each monitor's
    // currently-visible workspace — so every bar marks the same active workspace.
    readonly property int activeWsId:
        Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    // Special workspaces have non-positive ids and must not move the session.
    readonly property int session:
        activeWsId > 0 ? Math.floor((activeWsId - 1) / Config.sessionBand) + 1 : 1

    function absId(slot) {
        return (root.session - 1) * Config.sessionBand + slot;
    }

    function isOccupied(id) {
        const vs = Hyprland.workspaces.values;
        for (let i = 0; i < vs.length; i++)
            if (vs[i].id === id) return true;
        return false;
    }

    Row {
        id: strip
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: root.items

            Rectangle {
                id: pill
                required property var modelData
                // modelData.id is the slot; the workspace it addresses depends on
                // the active session.
                readonly property int wsId: root.absId(pill.modelData.id)
                readonly property bool focused: pill.wsId === root.activeWsId
                readonly property bool occupied: root.isOccupied(pill.wsId)
                readonly property color fgColor:
                      pill.focused  ? Theme.onAccent
                    : pill.occupied ? Theme.wsActive
                    : Theme.wsIdleFg

                height: Theme.wsHeight - 4
                radius: Theme.wsRadius - 2
                implicitWidth: cell.implicitWidth + 22
                color: pill.focused ? Theme.wsActive
                     : pill.occupied ? Theme.wsOccupied
                     : "transparent"

                Row {
                    id: cell
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pill.wsId
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontNormal
                        font.bold: true
                        color: pill.fgColor
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ":"
                        opacity: 0.45
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontNormal
                        font.bold: true
                        color: pill.fgColor
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pill.modelData.icon
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontIcon
                        opacity: pill.occupied || pill.focused ? 1.0 : 0.7
                        color: pill.fgColor
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    // Since the Hyprland Lua migration, dispatch() is shorthand for
                    // hl.dispatch(<arg>), so the argument must be a Lua expression —
                    // "workspace 1" now parses as hl.dispatch(workspace 1) and fails.
                    onClicked: Hyprland.dispatch(
                        'hl.dsp.focus({ workspace = "' + pill.wsId + '" })')
                }
            }
        }
    }
}
