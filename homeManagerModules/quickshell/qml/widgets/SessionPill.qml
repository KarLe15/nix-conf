import QtQuick
import Quickshell
import Quickshell.Hyprland
import "root:/"

// Workspace-session indicator: the active session, followed by the other open
// ones. A session is "open" when it holds at least one window, so it appears and
// disappears on its own (docs/HYPRLAND_SESSIONS.md, S13/S17).
//
// Both numbers are derived from the workspace ids Hyprland already reports —
// session = ((id - 1) / band) + 1 — so this needs no IPC of its own.
//
// Click a number to switch to that session.
Rectangle {
    id: root

    readonly property int band: Config.sessionBand

    readonly property int activeWsId:
        Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    readonly property int session:
        activeWsId > 0 ? Math.floor((activeWsId - 1) / band) + 1 : 1

    // Sessions holding at least one window, ascending. Special workspaces have
    // non-positive ids and are ignored.
    readonly property var openSessions: {
        const seen = ({});
        const out = [];
        const vs = Hyprland.workspaces.values;
        for (let i = 0; i < vs.length; i++) {
            const w = vs[i];
            if (w.id <= 0)
                continue;
            if (!w.toplevels || w.toplevels.values.length === 0)
                continue;
            const s = Math.floor((w.id - 1) / band) + 1;
            if (!seen[s]) {
                seen[s] = true;
                out.push(s);
            }
        }
        out.sort((a, b) => a - b);
        return out;
    }

    radius: Theme.pillRadius
    color: Theme.surface
    implicitHeight: Theme.pillHeight
    implicitWidth: row.implicitWidth + 20

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""  // nf-fa-th_large — the session grid
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            opacity: 0.7
            color: Theme.fg
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Repeater {
                // The active session is always shown, even before it holds a window.
                model: {
                    const open = root.openSessions.slice();
                    if (open.indexOf(root.session) === -1) {
                        open.push(root.session);
                        open.sort((a, b) => a - b);
                    }
                    return open;
                }

                Rectangle {
                    id: num
                    required property var modelData
                    readonly property bool current: num.modelData === root.session

                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(Theme.fontNormal + 8, label.implicitWidth + 8)
                    height: Theme.fontNormal + 8
                    radius: 4
                    color: num.current ? Theme.accent : "transparent"

                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: num.modelData
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontNormal
                        font.bold: num.current
                        color: num.current ? Theme.onAccent : Theme.fg
                        opacity: num.current ? 1.0 : 0.55
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // hyprctl's Lua REPL shares the compositor's config state, so this
                        // calls the very same sessions.lua the keybinds use — the
                        // switching logic is not duplicated here.
                        onClicked: Quickshell.execDetached([
                            "hyprctl", "repl",
                            "require(\"sessions\").switchTo(" + num.modelData + ")"
                        ])
                    }
                }
            }
        }
    }
}
