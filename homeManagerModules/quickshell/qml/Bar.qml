import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/widgets"

// A single monitor's status bar — a solid Crust strip hugging the top edge with a
// hairline bottom border. The three zones (left / center / right) are data-driven:
// their widget lists come from Config.barLayout, keyed by this screen's role, so
// each monitor carries a different composition (Screen Bars · Filled). Each entry is
// dispatched by WidgetSlot to a real widget or a design StubPill.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    // This screen's role ("code" | "terminal" | "browser") and whether it's the hub,
    // derived from the monitors disposition (see Config.qml). The role selects the
    // per-screen layout below.
    readonly property string role: Config.roles[modelData.name] || "other"
    readonly property bool isHub: modelData.name === Config.hubMonitor
    readonly property var layout: Config.barLayout[role] || Config.barLayout["other"]

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.bg

    // Register with the popover manager so clicks on any bar (e.g. another chip)
    // don't dismiss an open popover — they swap it instead.
    Component.onCompleted: Popovers.registerBar(bar)
    Component.onDestruction: Popovers.unregisterBar(bar)

    // Hairline under the bar.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    // LEFT zone.
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Repeater {
            model: bar.layout.left
            WidgetSlot {
                entry: modelData
                screenName: bar.modelData.name
                isHub: bar.isHub
                role: bar.role
            }
        }
    }

    // CENTER zone.
    Row {
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            model: bar.layout.center
            WidgetSlot {
                entry: modelData
                screenName: bar.modelData.name
                isHub: bar.isHub
                role: bar.role
            }
        }
    }

    // RIGHT zone.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Repeater {
            model: bar.layout.right
            WidgetSlot {
                entry: modelData
                screenName: bar.modelData.name
                isHub: bar.isHub
                role: bar.role
            }
        }
    }
}
