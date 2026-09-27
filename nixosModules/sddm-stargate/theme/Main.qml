import QtQuick
import QtQuick.Window
import "Config"
import "screens"

// Entry point, loaded once per monitor. SDDM builds a separate QQuickView — and
// therefore a separate QML engine — for every screen, so this file's only real
// job is to work out which of the three screens this view is and to make sure
// the one that takes input actually holds the keyboard.
Item {
    id: root

    // Every screen is authored in a 1080px-tall space and scaled to the monitor,
    // so the ultrawide draws the same layout as a 1080p panel, only wider.
    readonly property real uiScale: height > 0 ? height / Theme.designHeight : 1

    // The Window attached property only resolves on an Item, so the view is
    // captured here for the Timer and Connections below to use.
    readonly property var view: Window.window

    // theme.conf's previewScreen, so `--test-mode` can bring up any of the three
    // on a single display.
    readonly property string forced:
        (typeof config !== "undefined" && config.previewScreen) ? config.previewScreen : "auto"

    // Xorg names a connector differently from the kernel: DRM calls the ultrawide
    // HDMI-A-2, the X server calls it HDMI-2. The preset quotes DRM names, the same
    // ones the monitors preset uses, so both sides are normalised here and one
    // preset works whether the greeter runs on X11 or on Wayland.
    function connector(name) {
        return String(name).replace(/-[AB]-(\d+)$/, "-$1")
    }

    readonly property bool gateConnected: {
        const list = Qt.application.screens
        for (let i = 0; i < list.length; i++)
            if (connector(list[i].name) === connector(Config.screens.gate))
                return true
        return false
    }

    readonly property bool widest: {
        const list = Qt.application.screens
        let best = null
        for (let i = 0; i < list.length; i++)
            if (!best || list[i].width > best.width)
                best = list[i]
        return !best || best.name === Screen.name
    }

    // Connector -> screen, with one safeguard: if the monitor the preset names
    // for the gate is not attached, the widest one that is takes the greeter
    // rather than leaving the machine with no way to log in.
    readonly property string role: {
        if (forced !== "auto")
            return forced
        const name = connector(Screen.name)
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
            id: screen
            anchors.fill: parent
            sourceComponent: root.role === "gate" ? gateScreen
                           : root.role === "dhd" ? dhdScreen
                           : root.role === "telemetry" ? telemetryScreen
                           : null
        }
    }

    Component { id: gateScreen; GateScreen { } }
    Component { id: dhdScreen; DhdScreen { } }
    Component { id: telemetryScreen; TelemetryScreen { } }

    // SDDM only activates the view on the DRM-primary screen, and at greeter
    // time that is whatever the kernel picked — not necessarily the monitor the
    // preset puts the gate on. So the gate view asks for activation itself, and
    // keeps asking until the compositor grants it. The other two screens hold
    // nothing clickable, so taking focus back from them is the right outcome.
    Timer {
        interval: 250
        repeat: true
        running: root.role === "gate" && (!root.view || !root.view.active)
        triggeredOnStart: true
        onTriggered: {
            if (root.view)
                root.view.requestActivate()
        }
    }

    Connections {
        target: root.view
        enabled: root.role === "gate" && root.view !== null
        function onActiveChanged() {
            if (root.view.active && screen.item && screen.item.takeFocus)
                screen.item.takeFocus()
        }
    }

    Component.onCompleted: {
        if (role === "gate" && screen.item && screen.item.takeFocus)
            screen.item.takeFocus()
    }
}
