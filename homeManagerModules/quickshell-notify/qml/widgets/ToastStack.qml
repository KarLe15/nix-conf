import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"

// The toast stack (Notifications · 4a): top-right, newest on top, at most
// Config.maxVisible cards with the rest queued behind them.
//
// One of these exists per screen — Variants in shell.qml — but only the one whose
// connector matches Config.screen ever shows anything.
//
// The window is a fixed full-height strip down the right edge, and never resizes.
// That is deliberate: this is a layer-shell surface, so a window sized to its
// content asks the compositor for a resize on every frame of a card's expand
// animation — seven configure round-trips per expand, measured, which is what made
// the cards judder. At a fixed size the animation never leaves the client.
//
// Input is confined to the cards by a settling mask — see below.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property bool isTarget: modelData.name === Config.screen

    anchors { top: true; bottom: true; right: true }
    implicitWidth: Config.width + Config.margin * 2

    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"
    visible: isTarget && Toasts.shown.count > 0

    // Input is confined to the cards, but the mask deliberately does NOT follow them
    // frame by frame. A mask bound to the live geometry oscillates: hovering expands
    // the card, the column grows, the input region is rewritten, the compositor
    // re-sends a pointer leave, the card collapses again — measured as hovered
    // flapping true/false three times under a stationary pointer, which also let the
    // countdown resume and expire the card being read.
    //
    // So the region settles instead: any geometry change restarts a short timer, and
    // only when it stops moving is the mask rewritten. One update per transition. The
    // region always covers at least the collapsed card, so a pointer that started
    // inside stays inside while it is catching up.
    property real maskHeight: 1
    mask: Region {
        x: column.x
        y: column.y
        width: column.width
        height: root.maskHeight
    }

    Timer {
        id: maskSettle
        interval: 60
        repeat: false
        onTriggered: root.maskHeight = Math.max(1, column.height)
    }

    Connections {
        target: column
        function onHeightChanged() { maskSettle.restart(); }
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Config.margin
        anchors.rightMargin: Config.margin
        width: Config.width
        spacing: Config.gap

        Repeater {
            // Gated on isTarget, not just the window's visibility: an invisible stack
            // still instantiates its delegates, and each card runs its own countdown.
            // Ungated, the copies on the other two monitors keep ticking and the
            // first one to reach zero dismisses the card you are hovering.
            model: root.isTarget ? Toasts.shown : null
            Toast {
                required property var model
                notif: model.notif
                nowTick: ticker.tick
                onDismissed: Toasts.remove(model.notif)

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: 160 } }
            }
        }
    }

    // One ticker for every card on this screen — each toast renders a relative age,
    // and three cards should not mean three timers.
    Timer {
        id: ticker
        property int tick: 0
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: tick++
    }
}
