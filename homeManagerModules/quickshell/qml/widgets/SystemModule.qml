import QtQuick
import "root:/"

// Adaptive system monitor (System Widget · 6a). A context-colored pill on the bar
// showing the top context's headline metric, precedence gaming → llm → container →
// standard. Click it to drop the unified system panel. This is a pure view over the
// Sys singleton (the single source of truth for metrics + context); the panel reads
// these same aliases through `info`, so it stays unchanged.
Rectangle {
    id: root

    // ---- Data (aliased from the shared Sys singleton) ----
    readonly property int cpu: Sys.cpu
    readonly property int cpuTemp: Sys.cpuTemp
    readonly property real memUsed: Sys.memUsed
    readonly property real memTotal: Sys.memTotal
    readonly property int gpu: Sys.gpu
    readonly property int gpuTemp: Sys.gpuTemp
    readonly property int gpuWatts: Sys.gpuWatts
    readonly property real vramUsed: Sys.vramUsed
    readonly property real vramTotal: Sys.vramTotal
    readonly property real netDown: Sys.netRxBps / 1e6   // MB/s (panel display)
    readonly property real netUp: Sys.netTxBps / 1e6
    readonly property var cpuHist: Sys.cpuHist
    readonly property var gpuHist: Sys.gpuHist
    readonly property var ramHist: Sys.ramHist
    readonly property var netHist: Sys.netHist
    readonly property string context: Sys.context
    readonly property int sysRunning: Sys.sysRunning
    readonly property int sysFailed: Sys.sysFailed
    readonly property var llmModels: Sys.llmModels
    readonly property string llmModel: Sys.llmModel
    readonly property real llmVram: Sys.llmVram
    readonly property int llmLoaded: Sys.llmLoaded
    readonly property int containers: Sys.containers
    readonly property var containerList: Sys.containerList
    readonly property var procs: Sys.procs

    // Right-align a value to a fixed width with leading spaces (mono font) so the
    // pill/panel don't resize as a number gains or loses a digit.
    function pad(v, w) {
        let s = String(v);
        while (s.length < w) s = " " + s;
        return s;
    }

    // ---- Derived pill appearance ----
    readonly property color ctxColor:
          context === "gaming"    ? Theme.maroon
        : context === "llm"       ? Theme.mauve
        : context === "container" ? Theme.teal
        : Theme.blue
    readonly property string ctxBadge:
          context === "gaming"    ? "G"
        : context === "llm"       ? "AI"
        : context === "container" ? "▢"
        : "C"
    readonly property string ctxLabel:
        context.charAt(0).toUpperCase() + context.slice(1)
    readonly property string headline: {
        if (context === "gaming")    return "GPU " + pad(gpu, 3) + "% · " + pad(gpuTemp, 2) + "°";
        if (context === "llm")       return "VRAM " + pad((llmVram > 0 ? llmVram : vramUsed).toFixed(1), 4) + " / " + Math.round(vramTotal) + "G";
        if (context === "container") return pad(containers, 2) + " running";
        return pad(cpu, 3) + "% · " + pad(cpuTemp, 2) + "°";
    }

    radius: Theme.pillRadius
    color: root.ctxColor
    opacity: (pillMouse.containsMouse || panel.visible) ? 0.9 : 1.0
    implicitHeight: Theme.pillHeight
    implicitWidth: pillRow.implicitWidth + 20

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 8

        // Context badge (letter placeholder — swap for a Nerd Font glyph later).
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.16)
            Text {
                anchors.centerIn: parent
                text: root.ctxBadge
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: Theme.onAccent
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.headline
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: Theme.onAccent
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Popovers.toggle(panel)
    }

    SystemPanel {
        id: panel
        anchorItem: root
        info: root
    }
}
