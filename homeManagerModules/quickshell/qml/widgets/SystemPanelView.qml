import QtQuick
import "root:/"

// The expanded system panel body (System Widget · 6b, unified/adaptive). Cool
// meters (mauve/blue/teal) that span the width, a context badge + adaptive middle
// section (top processes for standard, a context hero otherwise), and a systemd
// status row. Scaled to sit consistently with the bar (not the mockup's raw 1x).
// Reads live data from `info` (the SystemModule pill).
Rectangle {
    id: root
    property var info
    property bool containersExpanded: false

    readonly property int inner: 336

    color: Theme.mantle
    border.color: Theme.surface
    border.width: 1
    radius: 16
    implicitWidth: inner + 36
    implicitHeight: layout.implicitHeight + 36

    // Fixed-width, space-padded (mono) so values don't reflow across digit counts.
    function pad(v, w) {
        let s = String(v);
        while (s.length < w) s = " " + s;
        return s;
    }
    function meterColor(k) {
        return k === "cpu" ? Theme.mauve : k === "mem" ? Theme.teal : Theme.blue;
    }
    function meterPct(k) {
        if (k === "cpu") return info.cpu;
        if (k === "gpu") return info.gpu;
        return info.memTotal > 0 ? (info.memUsed / info.memTotal * 100) : 0;
    }
    function meterValue(k) {
        if (k === "cpu") return pad(info.cpu, 3) + "% " + pad(info.cpuTemp, 2) + "°";
        if (k === "gpu") return pad(info.gpu, 3) + "% " + pad(info.gpuTemp, 2) + "°";
        return pad(info.memUsed.toFixed(1), 4) + " / " + Math.round(info.memTotal) + "G";
    }

    function sparkData(k) {
        return k === "cpu" ? info.cpuHist : k === "gpu" ? info.gpuHist
             : k === "ram" ? info.ramHist : info.netHist;
    }
    function sparkColor(k) {
        return k === "cpu" ? Theme.mauve : k === "gpu" ? Theme.blue
             : k === "ram" ? Theme.teal : Theme.yellow;
    }
    function sparkValue(k) {
        if (k === "cpu") return pad(info.cpu, 3) + "% · " + pad(info.cpuTemp, 2) + "°";
        if (k === "gpu") return pad(info.gpu, 3) + "% · " + pad(info.gpuTemp, 2) + "°";
        if (k === "ram") return pad(info.memUsed.toFixed(1), 4) + " / " + Math.round(info.memTotal) + "G";
        return "↓" + pad(info.netDown.toFixed(1), 4) + " ↑" + pad(info.netUp.toFixed(1), 4);
    }

    Column {
        id: layout
        x: 18
        y: 18
        width: root.inner
        spacing: 14

        // ---- Header: "System" + context badge ----
        Item {
            width: parent.width
            height: 24
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "System"
                font.family: Theme.fontUi
                font.pixelSize: 18
                font.bold: true
                color: Theme.fg
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                radius: 7
                color: root.info.ctxColor
                implicitWidth: badge.implicitWidth + 20
                implicitHeight: 24
                Text {
                    id: badge
                    anchors.centerIn: parent
                    text: root.info.ctxLabel
                    font.family: Theme.fontUi
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.onAccent
                }
            }
        }

        // ---- Meters: CPU / MEM / GPU (gaming uses sparklines instead) ----
        Repeater {
            model: root.info.context === "gaming" ? []
                 : root.info.context === "llm" ? ["cpu", "gpu"]
                 : root.info.context === "container" ? ["cpu", "mem"]
                 : ["cpu", "mem", "gpu"]
            Item {
                width: root.inner
                height: 22
                property string k: modelData
                Text {
                    id: lbl
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    text: parent.k.toUpperCase()
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    color: Theme.subtext0
                }
                Text {
                    id: valTxt
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.meterValue(parent.k)
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }
                Rectangle {
                    anchors.left: lbl.right
                    anchors.right: valTxt.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    height: 11
                    radius: 6
                    color: Theme.surface
                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.max(0, Math.min(1, root.meterPct(lbl.parent.k) / 100))
                        radius: 6
                        color: root.meterColor(lbl.parent.k)
                    }
                }
            }
        }

        // ---- Gaming → sparklines (CPU / GPU / RAM / NET) ----
        Column {
            visible: root.info.context === "gaming"
            width: root.inner
            spacing: 8

            Repeater {
                model: ["cpu", "gpu", "ram", "net"]
                Item {
                    width: root.inner
                    height: 40
                    property string k: modelData
                    Text {
                        id: slbl
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        text: parent.k.toUpperCase()
                        font.family: Theme.fontUi
                        font.pixelSize: 14
                        color: Theme.subtext0
                    }
                    Text {
                        id: sval
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.sparkValue(parent.k)
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.fg
                    }
                    Sparkline {
                        anchors.left: slbl.right
                        anchors.right: sval.left
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30
                        values: root.sparkData(slbl.parent.k)
                        stroke: root.sparkColor(slbl.parent.k)
                        maxValue: slbl.parent.k === "net" ? 0 : 100
                    }
                }
            }
        }

        // ---- NET (hidden in the LLM + container + gaming layouts) ----
        Item {
            visible: root.info.context !== "llm" && root.info.context !== "container"
                     && root.info.context !== "gaming"
            width: root.inner
            height: 20
            Text {
                id: netLbl
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                text: "NET"
                font.family: Theme.fontUi
                font.pixelSize: 14
                color: Theme.subtext0
            }
            Text {
                anchors.left: netLbl.right
                anchors.verticalCenter: parent.verticalCenter
                text: "↓ " + root.info.netDown.toFixed(1) + " MB/s     ↑ " + root.info.netUp.toFixed(1) + " MB/s"
                font.family: Theme.fontMono
                font.pixelSize: 15
                font.bold: true
                color: Theme.fg
            }
        }

        // ---- Adaptive middle: top processes (standard) or context hero ----
        Column {
            width: root.inner
            spacing: 10

            Rectangle { width: parent.width; height: 1; color: Theme.surface }

            // Standard → top processes.
            Column {
                visible: root.info.context === "standard"
                width: parent.width
                spacing: 6
                Repeater {
                    model: root.info.procs
                    Item {
                        width: root.inner
                        height: 18
                        required property var modelData
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData.name
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.subtext1
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(parent.modelData.pct) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.subtext1
                        }
                    }
                }
            }

            // LLM → one model card per loaded model.
            Column {
                visible: root.info.context === "llm"
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.info.llmModels
                    Rectangle {
                        id: mcard
                        required property var modelData
                        width: parent.width
                        radius: 12
                        color: Theme.base
                        border.color: Theme.surface
                        border.width: 1
                        implicitHeight: card.implicitHeight + 24

                        Column {
                            id: card
                            x: 12
                            y: 12
                            width: parent.width - 24
                            spacing: 10

                            Row {
                                width: parent.width
                                spacing: 12
                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 11
                                    color: Theme.mauve
                                    Text {
                                        anchors.centerIn: parent
                                        text: "AI"
                                        font.family: Theme.fontUi
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.onAccent
                                    }
                                }
                                Column {
                                    width: parent.width - 52
                                    spacing: 2
                                    Text {
                                        text: "ollama"
                                        font.family: Theme.fontUi
                                        font.pixelSize: 12
                                        color: Theme.subtext0
                                    }
                                    Text {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: mcard.modelData.name
                                        font.family: Theme.fontUi
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: Theme.fg
                                    }
                                    Text {
                                        text: {
                                            const m = mcard.modelData, parts = [];
                                            if (m.param) parts.push(m.param);
                                            if (m.quant) parts.push(m.quant);
                                            if (m.family) parts.push(m.family);
                                            return parts.join(" · ");
                                        }
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: Theme.overlay0
                                    }
                                }
                            }

                            // VRAM meter (this model's footprint / total GPU VRAM).
                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    id: vlbl
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 46
                                    text: "VRAM"
                                    font.family: Theme.fontUi
                                    font.pixelSize: 13
                                    color: Theme.subtext0
                                }
                                Text {
                                    id: vval
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: mcard.modelData.vram.toFixed(1) + " / " + Math.round(root.info.vramTotal) + "G"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.fg
                                }
                                Rectangle {
                                    anchors.left: vlbl.right
                                    anchors.right: vval.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 9
                                    radius: 5
                                    color: Theme.surface
                                    Rectangle {
                                        height: parent.height
                                        width: parent.width * (root.info.vramTotal > 0
                                            ? Math.max(0, Math.min(1, mcard.modelData.vram / root.info.vramTotal)) : 0)
                                        radius: 5
                                        color: Theme.mauve
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Container → container list (name · cpu · mem · uptime, collapsible).
            Rectangle {
                visible: root.info.context === "container"
                width: parent.width
                radius: 11
                color: Theme.base
                border.color: Theme.surface
                border.width: 1
                implicitHeight: clist.implicitHeight + 24

                Column {
                    id: clist
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 6

                    Text {
                        text: "Containers · docker — " + root.info.containers + " running"
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        color: Theme.subtext0
                        bottomPadding: 3
                    }

                    Repeater {
                        model: root.containersExpanded
                            ? root.info.containerList
                            : root.info.containerList.slice(0, 4)
                        Item {
                            id: crow
                            required property var modelData
                            width: clist.width
                            height: 20
                            Text {
                                anchors.left: parent.left
                                anchors.right: stats.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: crow.modelData.name
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: Theme.subtext1
                            }
                            Row {
                                id: stats
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Text {
                                    width: 52
                                    horizontalAlignment: Text.AlignRight
                                    text: crow.modelData.cpu
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: Theme.subtext1
                                }
                                Text {
                                    width: 66
                                    horizontalAlignment: Text.AlignRight
                                    text: crow.modelData.mem
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: Theme.subtext1
                                }
                                Text {
                                    width: 40
                                    horizontalAlignment: Text.AlignRight
                                    text: crow.modelData.uptime
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: Theme.overlay0
                                }
                            }
                        }
                    }

                    // Collapse toggle when there are more than 4.
                    Item {
                        visible: root.info.containerList.length > 4
                        width: clist.width
                        height: 24
                        Rectangle { width: parent.width; height: 1; color: Theme.surface; anchors.top: parent.top }
                        Row {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            spacing: 6
                            Text {
                                text: root.containersExpanded ? "▴" : "▾"
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                color: Theme.teal
                            }
                            Text {
                                text: root.containersExpanded
                                    ? "less"
                                    : (root.info.containerList.length - 4) + " more"
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                color: Theme.teal
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.containersExpanded = !root.containersExpanded
                        }
                    }
                }
            }

            // Gaming → context chips (GPU % · temp · watts · VRAM).
            Rectangle {
                visible: root.info.context === "gaming"
                width: parent.width
                radius: 11
                color: Theme.base
                border.color: Theme.surface
                border.width: 1
                implicitHeight: hero.implicitHeight + 22

                Column {
                    id: hero
                    x: 13
                    y: 11
                    width: parent.width - 26
                    spacing: 9
                    Text {
                        text: "Gaming context"
                        font.family: Theme.fontUi
                        font.pixelSize: 13
                        color: Theme.subtext0
                    }
                    Flow {
                        width: parent.width
                        spacing: 7
                        Repeater {
                            model: {
                                const i = root.info;
                                return [
                                    "GPU " + i.gpu + "%",
                                    i.gpuTemp + "°",
                                    i.gpuWatts + " W",
                                    "VRAM " + i.vramUsed.toFixed(1) + " / " + Math.round(i.vramTotal) + "G"
                                ];
                            }
                            Rectangle {
                                required property var modelData
                                radius: 7
                                color: Theme.surface
                                implicitWidth: chipTxt.implicitWidth + 18
                                implicitHeight: 26
                                Text {
                                    id: chipTxt
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.subtext1
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- systemd status (hidden for gaming — calm & glanceable) ----
        Rectangle {
            visible: root.info.context !== "gaming"
            width: root.inner
            radius: 11
            color: Theme.base
            border.color: root.info.sysFailed > 0 ? Theme.red : Theme.surface
            border.width: 1
            implicitHeight: 46

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "systemd"
                font.family: Theme.fontUi
                font.pixelSize: 14
                color: Theme.subtext0
            }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 92
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.info.sysFailed > 0 ? Theme.red : Theme.green
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.info.sysFailed > 0 ? "degraded" : "running"
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    color: root.info.sysFailed > 0 ? Theme.red : Theme.green
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: root.info.sysRunning + " · " + root.info.sysFailed + " failed"
                font.family: Theme.fontMono
                font.pixelSize: 14
                color: root.info.sysFailed > 0 ? Theme.red : Theme.overlay0
            }
        }
    }
}
