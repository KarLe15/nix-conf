import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "root:/"
import "root:/widgets"

// Multimedia OSD (design "Volume OSD" · 9a/9c/9d). A transient overlay fired by
// volume and microphone changes.
//
// Unlike avizo it is not triggered by the keybind: it watches the Pipewire
// properties, so a change from ANY source — a media key, pavucontrol, an
// application — raises it. Design behaviour: each change restarts the hold timer,
// so a key-repeat sweep reads as one continuous OSD.
//
// Renders only on the monitor role named by Config.osd.monitor. The window is
// full-screen, transparent and input-transparent (empty mask), so it never blocks
// a click; it is torn down once the fade has finished rather than sitting above
// every window forever.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property var cfg: Config.osd
    readonly property bool isTarget:
        (Config.roles[modelData.name] || "other") === cfg.monitor

    // ---- payload (design 9b: one surface, several payloads) ----
    property string kind: "volume"          // "volume" | "mic"
    property int    pct: 0
    property bool   muted: false
    property string title: ""
    property string deviceLine: ""
    property string glyph: ""

    readonly property color accent:
        Theme[cfg.accent] !== undefined ? Theme[cfg.accent] : Theme.blue
    // Mute greys the fill; the level itself stays remembered (design 9a).
    readonly property color fill: muted ? Theme.overlay1 : accent

    property bool active: false             // logical: should be on screen
    property bool present: false            // window exists (kept alive for the fade)

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    aboveWindows: true
    focusable: false
    color: "transparent"
    visible: present
    mask: Region {}                         // click-through

    onActiveChanged: {
        if (active) { teardown.stop(); present = true; }
        else teardown.restart();
    }

    // Outlives the 180 ms fade so the window is not yanked mid-animation.
    Timer { id: teardown; interval: 260; onTriggered: root.present = false }
    Timer { id: hold; interval: root.cfg.holdMs; onTriggered: root.active = false }

    function show() {
        if (!root.isTarget) return;
        root.active = true;
        hold.restart();                     // each change restarts the hold window
    }

    // ---- sources ----
    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool hasSink: sink && sink.audio
    readonly property bool hasSource: source && source.audio

    // Ignore the first evaluation of each binding: Pipewire reports current state
    // on connect, which would otherwise pop the OSD every time the shell starts.
    property bool primed: false
    Timer { interval: 600; running: true; onTriggered: root.primed = true }

    function volumeGlyph(p, m) {
        if (m || p === 0) return root.cfg.icons.volumeMute;
        return p < root.cfg.lowThreshold ? root.cfg.icons.volumeLow
                                         : root.cfg.icons.volumeHigh;
    }

    function showVolume() {
        if (!root.primed) return;
        root.kind = "volume";
        root.pct = root.hasSink ? Math.round(root.sink.audio.volume * 100) : 0;
        root.muted = root.hasSink ? root.sink.audio.muted : false;
        root.title = root.muted ? "Muted" : "Volume";
        root.glyph = root.volumeGlyph(root.pct, root.muted);
        root.deviceLine = root.hasSink
            ? (root.sink.description || root.sink.name || "Output")
            : "No output";
        root.show();
    }

    function showMic() {
        if (!root.primed) return;
        root.kind = "mic";
        root.muted = root.hasSource ? root.source.audio.muted : false;
        // The mic payload reuses the bar at zero when muted (design 9b).
        root.pct = root.muted ? 0 : 100;
        root.title = "Microphone";
        root.glyph = root.muted ? root.cfg.icons.micMute : root.cfg.icons.micOn;
        root.deviceLine = root.hasSource
            ? (root.source.description || root.source.name || "Input")
            : "No input";
        root.show();
    }

    Connections {
        target: root.hasSink ? root.sink.audio : null
        function onVolumeChanged() { root.showVolume() }
        function onMutedChanged()  { root.showVolume() }
    }
    Connections {
        target: root.hasSource ? root.source.audio : null
        function onMutedChanged() { root.showMic() }
    }

    // ---- variants ----
    readonly property string variant: cfg.variant
    readonly property bool wantCard:  variant === "card"  || variant === "all"
    readonly property bool wantRing:  variant === "ring"  || variant === "all"
    readonly property bool wantNotch: variant === "notch" || variant === "all"

    OsdCard {
        osd: root
        visible: root.wantCard
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: root.cfg.placement === "top" ? undefined : parent.bottom
        anchors.top: root.cfg.placement === "top" ? parent.top : undefined
        anchors.bottomMargin: root.cfg.margin
        anchors.topMargin: root.cfg.margin
    }

    OsdRing {
        osd: root
        visible: root.wantRing
        anchors.centerIn: parent
    }

    OsdNotch {
        osd: root
        visible: root.wantNotch
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }
}
