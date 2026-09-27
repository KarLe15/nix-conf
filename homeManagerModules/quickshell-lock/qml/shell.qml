import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Auth"
import "Config"

// The Stargate lock screen.
//
// Runs as its own resident quickshell instance, separate from the bar: a crash in
// bar code must not be able to take the lock down, and a windowless instance stays
// alive, so the gate is already loaded when the screen locks rather than
// cold-starting into a blank compositor.
//
// `ext-session-lock` is unforgiving — if this process dies while locked, the
// compositor stays blocked with no way to type a password. See the module README
// for the recovery path, and note the LockedHint check below.
ShellRoot {
    id: root

    readonly property bool previewing:
        String(Quickshell.env("STARGATE_PREVIEW") || "").length > 0

    Component.onCompleted: {
        Auth.previewing = root.previewing
        // A restart while the session is locked — a rebuild over SSH, say — would
        // otherwise come back idle and leave the compositor blocked with nothing to
        // type into. logind knows the truth, so ask it.
        if (!root.previewing)
            lockedHint.running = true
    }

    Process {
        id: lockedHint
        command: [ "sh", "-c", "loginctl show-session \"$XDG_SESSION_ID\" -p LockedHint --value" ]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() === "yes") Auth.lock()
        }
    }

    // hypridle, wleave and wlogout all reach the lock through this, via the
    // `stargate-lock` wrapper the defaults preset names.
    IpcHandler {
        target: "lock"

        function lock(): void {
            Auth.lock()
        }

        function status(): string {
            return Auth.locked ? "locked" : "idle";
        }
    }

    // Keep logind's hint honest, so the check above stays meaningful and anything
    // else asking the session whether it is locked gets the right answer.
    //
    // SetLockedHint, not `loginctl lock-session`: that sends the Lock *signal*,
    // which hypridle answers by running lock_cmd — which is what got us here. The
    // hint is the fact; the signal is the request.
    Process {
        id: setHint
    }

    Connections {
        target: Auth
        function onLockedChanged() {
            if (root.previewing)
                return
            setHint.command = [
                "busctl", "call", "org.freedesktop.login1",
                "/org/freedesktop/login1/session/auto",
                "org.freedesktop.login1.Session", "SetLockedHint", "b",
                Auth.locked ? "true" : "false"
            ]
            setHint.running = true
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: Auth.locked && !root.previewing

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            Stage {
                anchors.fill: parent
                screenName: surface.screen ? surface.screen.name : ""
            }
        }
    }

    // Preview: the same screens in ordinary windows, so the design can be worked on
    // and screenshotted without ever grabbing the session.
    Variants {
        model: root.previewing ? Quickshell.screens : []

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            color: Theme.bg
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay

            Stage {
                anchors.fill: parent
                screenName: modelData.name
            }
        }
    }
}
