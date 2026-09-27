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
// The window is sized to the cards rather than covering the screen. A full-screen
// window would need an input mask to stay click-through, and a mask built from an
// item is computed from that item's geometry at build time: with the column empty on
// the first frame the input region comes out empty and the cards never receive a
// pointer event — no hover, so no countdown pause and no expand. Anchoring to two
// edges and letting implicit size do the rest means the surface *is* the stack, so
// everything outside it is someone else's input by construction.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property bool isTarget: modelData.name === Config.screen

    anchors { top: true; right: true }
    margins {
        top: Config.margin
        right: Config.margin
    }

    implicitWidth: Config.width
    implicitHeight: Math.max(1, column.implicitHeight)

    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"
    visible: isTarget && Toasts.visible.length > 0

    Column {
        id: column
        width: parent.width
        spacing: Config.gap

        Repeater {
            // Gated on isTarget, not just the window's visibility: an invisible stack
            // still instantiates its delegates, and each card runs its own countdown.
            // Ungated, the copies on the other two monitors keep ticking and the
            // first one to reach zero dismisses the card you are hovering.
            model: root.isTarget ? Toasts.visible : []
            Toast {
                required property var modelData
                notif: modelData
                nowTick: ticker.tick
                onDismissed: Toasts.remove(modelData)

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
