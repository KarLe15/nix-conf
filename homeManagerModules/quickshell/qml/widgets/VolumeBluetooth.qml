import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import "root:/"
import "root:/widgets"

// Volume + Bluetooth bar pill (Volume Bluetooth Widget · 8a): sky fill showing
// the output volume and the connected Bluetooth device; click for the control
// popover. Backed by the live Pipewire sink and the BlueZ adapter.
Rectangle {
    id: root

    // ---- Audio (Pipewire) ----
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasSink: sink && sink.audio
    readonly property bool muted: hasSink ? sink.audio.muted : false
    readonly property int volPct: hasSink ? Math.round(sink.audio.volume * 100) : 0
    readonly property string sinkName: sink ? (sink.description || sink.name || "Output") : "No output"
    function setVolume(v) { if (hasSink) sink.audio.volume = Math.max(0, Math.min(1, v)); }
    function toggleMute() { if (hasSink) sink.audio.muted = !sink.audio.muted; }

    // ---- Bluetooth (BlueZ) ----
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: btAdapter ? btAdapter.enabled : false
    readonly property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []
    readonly property var btConnected: {
        const out = [];
        const ds = root.btDevices;
        for (let i = 0; i < ds.length; i++)
            if (ds[i].connected) out.push(ds[i]);
        return out;
    }
    function _short(n) {
        if (!n) return "";
        const w = n.split(" ")[0];
        return w.length > 5 ? w.slice(0, 5) : w;
    }
    // The connected device's short name, or "Off" when the adapter is disabled,
    // or "" when the adapter is on but nothing is connected.
    readonly property string btLabel:
        !btEnabled ? "Off"
        : (btConnected.length > 0 ? _short(btConnected[0].name || btConnected[0].deviceName) : "")

    // Fixed-width slots keep the pill from resizing as the volume digits or the
    // Bluetooth label change. Sized to the widest content each slot can hold.
    TextMetrics {
        id: volMetrics
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontNormal
        font.bold: true
        text: "100%"  // widest number; muted renders as "mute" (same width)
    }
    TextMetrics {
        id: btMetrics
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontNormal
        font.bold: true
        text: "MMMMM"  // 5 chars — matches the _short() cap
    }

    radius: Theme.pillRadius
    color: muted ? Theme.overlay1 : Theme.sapphire
    opacity: (pillMouse.containsMouse || panel.visible) ? 0.9 : 1.0
    implicitHeight: Theme.pillHeight
    implicitWidth: pillRow.implicitWidth + 16

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 9

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "" : ""  // volume-off / up
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontIcon
                color: Theme.onAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: volMetrics.width
                horizontalAlignment: Text.AlignLeft
                text: root.muted ? "mute" : root.volPct + "%"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.onAccent
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(Theme.pillHeight * 0.4)
            color: Qt.rgba(0, 0, 0, 0.28)
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: ""  // bluetooth
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontIcon
                // Bright when a device is connected, dimmed when idle, faint when off.
                opacity: root.btConnected.length > 0 ? 1.0 : (root.btEnabled ? 0.7 : 0.4)
                color: Theme.onAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: btMetrics.width
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: root.btLabel
                opacity: root.btEnabled ? 1.0 : 0.6
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.onAccent
            }
        }
    }

    MouseArea {
        id: pillMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.visible = !panel.visible
    }

    VolumeBtPanel {
        id: panel
        anchorItem: root
        hub: root
    }
}
