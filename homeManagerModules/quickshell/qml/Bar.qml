import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/widgets"

// A single monitor's status bar — a solid Crust strip hugging the top edge with
// a hairline bottom border. Three zones follow the "Screen Bars · Filled" mockup:
// clock (left), workspaces (center), system module (right).
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    // This screen's role, derived from the monitors disposition (see Config.qml).
    // Later stages branch module composition on these — e.g. `visible: bar.isHub`
    // for global modules, or `role === "terminal"` for a bandwidth pill. Content is
    // intentionally identical across screens for now.
    readonly property string role: Config.roles[modelData.name] || "other"
    readonly property bool isHub: modelData.name === Config.hubMonitor

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Theme.bg

    // Hairline under the bar.
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.border
    }

    Clock {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
    }

    Workspaces {
        anchors.centerIn: parent
        screenName: bar.modelData.name
    }

    SystemModule {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
    }
}
