import QtQuick
import Quickshell.Io
import "root:/"

// Adaptive system monitor (System Widget · 6a). A context-colored pill on the bar
// showing the top context's headline metric, precedence gaming → llm → container
// → standard. Click it to drop the unified system panel. Data comes from two
// pollers: fast numeric metrics (/proc, /sys) and a slower context probe
// (GameMode dbus, ollama api, docker, systemd).
Rectangle {
    id: root

    // ---- Numeric metrics ----
    property int cpu: 0
    property int cpuTemp: 0
    property real memUsed: 0        // GB
    property real memTotal: 0
    property int gpu: 0
    property int gpuTemp: 0
    property int gpuWatts: 0        // W, GPU package power
    property real vramUsed: 0       // GB
    property real vramTotal: 0
    property real netDown: 0        // MB/s
    property real netUp: 0

    // Rolling history for the gaming sparklines (newest last).
    readonly property int _histN: 40
    property var cpuHist: []
    property var gpuHist: []
    property var ramHist: []
    property var netHist: []
    function _push(arr, v) {
        const a = arr.slice();
        a.push(v);
        if (a.length > root._histN) a.shift();
        return a;
    }
    // Net-rate state (cumulative bytes + timestamp of the previous sample).
    property real _prevRx: -1
    property real _prevTx: -1
    property real _prevT: 0

    // ---- Context ----
    property string context: "standard"
    property int sysRunning: 0
    property int sysFailed: 0
    property var llmModels: []      // [{ name, param, quant, family, vram(GB) }] all loaded models
    property string llmModel: ""    // primary (first) model name — pill headline
    property real llmVram: 0        // GB, total VRAM across all loaded models — pill headline
    property int llmLoaded: 0       // count of loaded models
    property int containers: 0
    property var containerList: []  // [{ name, cpu, mem, uptime }] running containers
    property var procs: []          // [{ name, pct }] top CPU processes (standard panel)

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

    // ---- Fast metrics poller (~2s) ----
    Process {
        id: metricsProc
        running: false
        command: ["sh", "-c",
            "read _ a b c d e f g _ < /proc/stat; t1=$((a+b+c+d+e+f+g)); id1=$((d+e)); "
          + "sleep 0.25; "
          + "read _ a b c d e f g _ < /proc/stat; t2=$((a+b+c+d+e+f+g)); id2=$((d+e)); "
          + "dt=$((t2-t1)); [ \"$dt\" -le 0 ] && dt=1; cpu=$(( (100*(dt-(id2-id1)))/dt )); "
          + "cput=0; gput=0; gpuw=0; for h in /sys/class/hwmon/hwmon*; do n=$(cat \"$h/name\" 2>/dev/null); "
          + "case \"$n\" in k10temp) v=$(cat \"$h/temp1_input\" 2>/dev/null); [ -n \"$v\" ] && cput=$((v/1000));; "
          + "amdgpu) v=$(cat \"$h/temp1_input\" 2>/dev/null); [ -n \"$v\" ] && gput=$((v/1000)); "
          + "p=$(cat \"$h/power1_average\" 2>/dev/null); [ -n \"$p\" ] && gpuw=$((p/1000000));; esac; done; "
          + "mt=$(awk '/^MemTotal/{print $2}' /proc/meminfo); ma=$(awk '/^MemAvailable/{print $2}' /proc/meminfo); mu=$((mt-ma)); "
          + "gpu=0; vu=0; vt=0; for d in /sys/class/drm/card*/device; do [ -r \"$d/gpu_busy_percent\" ] || continue; "
          + "gpu=$(cat \"$d/gpu_busy_percent\" 2>/dev/null); vu=$(cat \"$d/mem_info_vram_used\" 2>/dev/null); "
          + "vt=$(cat \"$d/mem_info_vram_total\" 2>/dev/null); break; done; "
          + "set -- $(awk 'NR>2{sub(/:/,\" \"); if($1!=\"lo\"){r+=$2;t+=$10}} END{print r+0,t+0}' /proc/net/dev); rx=$1; tx=$2; "
          + "echo \"$cpu $cput $mu $mt $gpu $gput $vu $vt $rx $tx $gpuw\""
        ]
        stdout: StdioCollector { onStreamFinished: root._parseMetrics(this.text) }
    }

    // ---- Context poller (~5s) ----
    Process {
        id: ctxProc
        running: false
        command: ["sh", "-c",
            "sh \"${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/context.sh\""]
        stdout: StdioCollector { onStreamFinished: root._parseContext(this.text) }
    }

    // ---- Top processes poller (~5s; used by the standard panel) ----
    Process {
        id: procsProc
        running: false
        command: ["sh", "-c",
            "ps --no-headers -eo comm,pcpu 2>/dev/null | "
          + "awk '{n=$1; sub(/^\\./,\"\",n); sub(/-wrapped$/,\"\",n); "
          + "if(n==\"ps\"||n==\"awk\"||n==\"sort\"||n==\"head\"||n==\"sh\"||n==\"wc\")next; c[n]+=$2} "
          + "END{for(k in c) if(c[k]>0.4) printf \"%s %.1f\\n\", k, c[k]}' | sort -k2 -rn | head -n 3"]
        stdout: StdioCollector { onStreamFinished: root._parseProcs(this.text) }
    }

    function _parseMetrics(t) {
        const p = t.trim().split(/\s+/);
        if (p.length < 10) return;
        root.cpu = parseInt(p[0]) || 0;
        root.cpuTemp = parseInt(p[1]) || 0;
        root.memUsed = (parseInt(p[2]) || 0) / 1048576;   // kB → GB
        root.memTotal = (parseInt(p[3]) || 0) / 1048576;
        root.gpu = parseInt(p[4]) || 0;
        root.gpuTemp = parseInt(p[5]) || 0;
        root.vramUsed = (parseInt(p[6]) || 0) / 1073741824; // bytes → GB
        root.vramTotal = (parseInt(p[7]) || 0) / 1073741824;
        const rx = parseInt(p[8]) || 0;
        const tx = parseInt(p[9]) || 0;
        const now = Date.now();
        if (root._prevRx >= 0 && root._prevT > 0) {
            const dt = (now - root._prevT) / 1000;
            if (dt > 0) {
                root.netDown = Math.max(0, (rx - root._prevRx) / dt / 1e6);
                root.netUp = Math.max(0, (tx - root._prevTx) / dt / 1e6);
            }
        }
        root._prevRx = rx;
        root._prevTx = tx;
        root._prevT = now;
        root.gpuWatts = parseInt(p[10]) || 0;

        // Append to the sparkline history.
        root.cpuHist = root._push(root.cpuHist, root.cpu);
        root.gpuHist = root._push(root.gpuHist, root.gpu);
        root.ramHist = root._push(root.ramHist, root.memTotal > 0 ? (root.memUsed / root.memTotal * 100) : 0);
        root.netHist = root._push(root.netHist, root.netDown + root.netUp);
    }

    function _parseContext(t) {
        const lines = t.trim().split(/\n+/);
        const models = [];
        const clist = [];
        for (let i = 0; i < lines.length; i++) {
            const eq = lines[i].indexOf("=");
            if (eq < 0) continue;
            const k = lines[i].slice(0, eq);
            const v = lines[i].slice(eq + 1);
            if (k === "context") root.context = v || "standard";
            else if (k === "sysrunning") root.sysRunning = parseInt(v) || 0;
            else if (k === "sysfailed") root.sysFailed = parseInt(v) || 0;
            else if (k === "containers") root.containers = parseInt(v) || 0;
            else if (k === "llmmodel") {
                const f = v.split("|");
                if (f[0]) models.push({
                    name: f[0], param: f[1] || "", quant: f[2] || "",
                    family: f[3] || "", vram: (parseInt(f[4]) || 0) / 1073741824
                });
            }
            else if (k === "container") {
                const f = v.split("|");
                if (f[0]) clist.push({ name: f[0], cpu: f[1] || "", mem: f[2] || "", uptime: f[3] || "" });
            }
        }
        root.containerList = clist;
        root.llmModels = models;
        root.llmLoaded = models.length;
        root.llmModel = models.length ? models[0].name : "";
        let sum = 0;
        for (let j = 0; j < models.length; j++) sum += models[j].vram;
        root.llmVram = sum;
    }

    function _parseProcs(t) {
        const lines = t.trim().split(/\n+/);
        const out = [];
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].trim().match(/^(.+?)\s+([\d.]+)$/);
            if (m) out.push({ name: m[1], pct: m[2] });
        }
        root.procs = out;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: metricsProc.running = true
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { ctxProc.running = true; procsProc.running = true; }
    }

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
        onClicked: panel.visible = !panel.visible
    }

    SystemPanel {
        id: panel
        anchorItem: root
        info: root
    }
}
