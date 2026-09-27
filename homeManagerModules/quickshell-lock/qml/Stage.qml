import QtQuick
import Quickshell
import "Auth"
import "Config"
import "screens"

// One screen of the gate room, scaled into place. Instantiated once per lock
// surface and once per preview window, so the two paths render identically.
//
// The role logic is the greeter's, kept deliberately in step with
// nixosModules/sddm-stargate/theme/Main.qml — including the connector
// normalisation, since a lock running under Hyprland sees DRM names while the
// greeter running under X11 sees the X server's.
Item {
    id: root

    property string screenName: ""

    readonly property real uiScale: height > 0 ? height / Theme.designHeight : 1

    // STARGATE_PREVIEW forces a screen so any of the three can be worked on without
    // three monitors, or a session lock.
    readonly property string forced: String(Quickshell.env("STARGATE_PREVIEW") || "auto")

    function connector(name) {
        return String(name).replace(/-[AB]-(\d+)$/, "-$1")
    }

    readonly property bool gateConnected: {
        const list = Quickshell.screens
        for (let i = 0; i < list.length; i++)
            if (connector(list[i].name) === connector(Config.screens.gate))
                return true
        return false
    }

    readonly property bool widest: {
        const list = Quickshell.screens
        let best = null
        for (let i = 0; i < list.length; i++)
            if (!best || list[i].width > best.width)
                best = list[i]
        return !best || connector(best.name) === connector(root.screenName)
    }

    // If the monitor the preset names for the gate is not attached, the widest one
    // that is takes it — a lock with no password field on any screen is a lockout.
    readonly property string role: {
        if (forced !== "auto" && forced.length > 0)
            return forced
        const name = connector(root.screenName)
        if (gateConnected) {
            if (name === connector(Config.screens.gate))
                return "gate"
        } else if (widest) {
            return "gate"
        }
        if (name === connector(Config.screens.dhd))
            return "dhd"
        if (name === connector(Config.screens.telemetry))
            return "telemetry"
        return "none"
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Item {
        width: root.uiScale > 0 ? root.width / root.uiScale : root.width
        height: Theme.designHeight
        scale: root.uiScale
        transformOrigin: Item.TopLeft

        Loader {
            anchors.fill: parent
            sourceComponent: root.role === "gate" ? gateScreen
                           : root.role === "dhd" ? dhdScreen
                           : root.role === "telemetry" ? telemetryScreen
                           : null
        }
    }

    // Typing on an ambience screen still dials. The SDDM greeter can never do this
    // — its three screens are separate QML engines — but the lock is one process,
    // so whichever surface the compositor hands the keyboard to, the address ends
    // up in the same place.
    Item {
        anchors.fill: parent
        focus: root.role !== "gate"

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                Auth.submit()
            } else if (event.key === Qt.Key_Escape) {
                Auth.reset()
            } else if (event.key === Qt.Key_Backspace) {
                Auth.password = Auth.password.slice(0, -1)
            } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20) {
                if (Auth.failed)
                    Auth.failed = false
                Auth.password += event.text
            } else {
                return
            }
            event.accepted = true
        }
    }

    Component { id: gateScreen; GateScreen { } }
    Component { id: dhdScreen; DhdScreen { } }
    Component { id: telemetryScreen; TelemetryScreen { } }
}
