pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for system metrics, shared across every bar/screen (a
// Quickshell singleton is process-global). Widgets read Sys.<prop> and stay pure
// views; nothing polls per-instance. The *internal* source is Process pollers
// today — /proc, /sys, and a context probe — but this boundary is deliberately the
// only thing that talks to the system: a future socket/DBus daemon can feed these
// same properties (push instead of poll) without touching a single widget.
Singleton {
    id: sys

    // ---- Numeric metrics ----
    property int cpu: 0              // %
    property int cpuTemp: 0          // °C
    property real memUsed: 0         // GB
    property real memTotal: 0
    property int gpu: 0              // %
    property int gpuTemp: 0          // °C
    property int gpuWatts: 0         // W, GPU package power
    property real vramUsed: 0        // GB
    property real vramTotal: 0
    property real netRxBps: 0        // bytes/s (download) — canonical unit
    property real netTxBps: 0        // bytes/s (upload)

    // ---- Rolling history for the gaming sparklines (newest last) ----
    readonly property int _histN: 40
    property var cpuHist: []
    property var gpuHist: []
    property var ramHist: []
    property var netHist: []         // MB/s (rx+tx), for the sparkline
    function _push(arr, v) {
        const a = arr.slice();
        a.push(v);
        if (a.length > sys._histN) a.shift();
        return a;
    }

    // Net-rate state (cumulative bytes + timestamp of the previous sample).
    property real _prevRx: -1
    property real _prevTx: -1
    property real _prevT: 0

    // ---- Context (gaming / llm / container / standard) ----
    property string context: "standard"
    property int sysRunning: 0
    property int sysFailed: 0
    property var llmModels: []       // [{ name, param, quant, family, vram(GB) }] loaded models
    property string llmModel: ""     // primary (first) model name
    property real llmVram: 0         // GB, total VRAM across loaded models
    property int llmLoaded: 0        // count of loaded models
    property int containers: 0
    property var containerList: []   // [{ name, cpu, mem, uptime }] running containers
    property var procs: []           // [{ name, pct }] top CPU processes

    // ---- Host facts (avatar popover · facts block) ----
    property int uptimeSec: 0        // seconds since boot
    property string kernel: ""       // uname -r
    property string host: ""         // uname -n
    property var ipv4: ({})          // interface name → IPv4 address

    // ---- Fast metrics poller (~2s): one shell one-shot returns every number in a
    // single line, so the snapshot is internally consistent. ----
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
        stdout: StdioCollector { onStreamFinished: sys._parseMetrics(this.text) }
    }

    // ---- Context poller (~5s): GameMode / ollama / docker / systemd probe. ----
    Process {
        id: ctxProc
        running: false
        command: ["sh", "-c",
            "sh \"${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/context.sh\""]
        stdout: StdioCollector { onStreamFinished: sys._parseContext(this.text) }
    }

    // ---- Top processes poller (~5s; used by the standard panel). ----
    Process {
        id: procsProc
        running: false
        command: ["sh", "-c",
            "ps --no-headers -eo comm,pcpu 2>/dev/null | "
          + "awk '{n=$1; sub(/^\\./,\"\",n); sub(/-wrapped$/,\"\",n); "
          + "if(n==\"ps\"||n==\"awk\"||n==\"sort\"||n==\"head\"||n==\"sh\"||n==\"wc\")next; c[n]+=$2} "
          + "END{for(k in c) if(c[k]>0.4) printf \"%s %.1f\\n\", k, c[k]}' | sort -k2 -rn | head -n 3"]
        stdout: StdioCollector { onStreamFinished: sys._parseProcs(this.text) }
    }

    // ---- Host facts poller (~30s): uptime moves, the rest is effectively static
    // but costs nothing to re-read, and the IPv4 map follows a reconnect. ----
    Process {
        id: factsProc
        running: false
        command: ["sh", "-c",
            "read up _ < /proc/uptime; echo \"uptime ${up%%.*}\"; "
          + "echo \"kernel $(uname -r)\"; echo \"host $(uname -n)\"; "
          + "ip -4 -o addr show 2>/dev/null | awk '{split($4,a,\"/\"); print \"ip4 \" $2 \" \" a[1]}'"]
        stdout: StdioCollector { onStreamFinished: sys._parseFacts(this.text) }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: factsProc.running = true
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

    function _parseMetrics(t) {
        const p = t.trim().split(/\s+/);
        if (p.length < 10) return;
        sys.cpu = parseInt(p[0]) || 0;
        sys.cpuTemp = parseInt(p[1]) || 0;
        sys.memUsed = (parseInt(p[2]) || 0) / 1048576;    // kB → GB
        sys.memTotal = (parseInt(p[3]) || 0) / 1048576;
        sys.gpu = parseInt(p[4]) || 0;
        sys.gpuTemp = parseInt(p[5]) || 0;
        sys.vramUsed = (parseInt(p[6]) || 0) / 1073741824; // bytes → GB
        sys.vramTotal = (parseInt(p[7]) || 0) / 1073741824;
        const rx = parseInt(p[8]) || 0;
        const tx = parseInt(p[9]) || 0;
        const now = Date.now();
        if (sys._prevRx >= 0 && sys._prevT > 0) {
            const dt = (now - sys._prevT) / 1000;
            if (dt > 0) {
                sys.netRxBps = Math.max(0, (rx - sys._prevRx) / dt);
                sys.netTxBps = Math.max(0, (tx - sys._prevTx) / dt);
            }
        }
        sys._prevRx = rx;
        sys._prevTx = tx;
        sys._prevT = now;
        sys.gpuWatts = parseInt(p[10]) || 0;

        // Append to the sparkline history.
        sys.cpuHist = sys._push(sys.cpuHist, sys.cpu);
        sys.gpuHist = sys._push(sys.gpuHist, sys.gpu);
        sys.ramHist = sys._push(sys.ramHist, sys.memTotal > 0 ? (sys.memUsed / sys.memTotal * 100) : 0);
        sys.netHist = sys._push(sys.netHist, (sys.netRxBps + sys.netTxBps) / 1e6);
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
            if (k === "context") sys.context = v || "standard";
            else if (k === "sysrunning") sys.sysRunning = parseInt(v) || 0;
            else if (k === "sysfailed") sys.sysFailed = parseInt(v) || 0;
            else if (k === "containers") sys.containers = parseInt(v) || 0;
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
        sys.containerList = clist;
        sys.llmModels = models;
        sys.llmLoaded = models.length;
        sys.llmModel = models.length ? models[0].name : "";
        let sum = 0;
        for (let j = 0; j < models.length; j++) sum += models[j].vram;
        sys.llmVram = sum;
    }

    function _parseProcs(t) {
        const lines = t.trim().split(/\n+/);
        const out = [];
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].trim().match(/^(.+?)\s+([\d.]+)$/);
            if (m) out.push({ name: m[1], pct: m[2] });
        }
        sys.procs = out;
    }

    function _parseFacts(t) {
        const lines = t.trim().split(/\n+/);
        const ips = {};
        for (let i = 0; i < lines.length; i++) {
            const f = lines[i].trim().split(/\s+/);
            if (f[0] === "uptime") sys.uptimeSec = parseInt(f[1]) || 0;
            else if (f[0] === "kernel") sys.kernel = f[1] || "";
            else if (f[0] === "host") sys.host = f[1] || "";
            else if (f[0] === "ip4" && f[1] && f[1] !== "lo") ips[f[1]] = f[2];
        }
        sys.ipv4 = ips;
    }

    // "4h 12m" / "3d 4h" — the popover's uptime row. A property, not a
    // function: the row has to re-render when uptimeSec moves.
    readonly property string uptimeText: {
        const s = sys.uptimeSec;
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0) return d + "d " + h + "h";
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }
}
