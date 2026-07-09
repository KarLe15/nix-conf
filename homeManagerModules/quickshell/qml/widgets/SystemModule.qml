import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import "root:/"

// Right island group (Stage 2, non-adaptive): a CPU/temp pill and a volume pill.
// CPU/temp are polled from sysfs; volume is event-driven via the Pipewire service
// so it reflects changes instantly. The adaptive multi-context system module +
// hover panel from the mockup arrives in Stage 3; this is the always-on baseline.
Row {
    id: root
    spacing: 10

    property string cpu:  "--"
    property string temp: "--"

    // ---- Volume (reactive; no polling) ----
    // Keep the default sink "bound" so its volume/mute stay live-updated.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property int volPct:
        (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0

    // ---- CPU% (idle+iowait excluded) + hottest sane temp, sampled together ----
    Process {
        id: sysProc
        running: false
        command: ["sh", "-c",
            "read _ a b c d e f g _ < /proc/stat; t1=$((a+b+c+d+e+f+g)); id1=$((d+e)); "
          + "sleep 0.25; "
          + "read _ a b c d e f g _ < /proc/stat; t2=$((a+b+c+d+e+f+g)); id2=$((d+e)); "
          + "dt=$((t2-t1)); [ \"$dt\" -le 0 ] && dt=1; "
          // busy = total - (idle+iowait); iowait is NOT CPU work (matches btop/htop).
          + "cpu=$(( (100*(dt-(id2-id1)))/dt )); "
          // Hottest sane sensor across thermal zones + hwmon (thermal_zone0 is not
          // the CPU on AMD; k10temp shows up as a hwmon temp*_input).
          + "m=0; for z in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do "
          + "[ -r \"$z\" ] || continue; v=$(cat \"$z\" 2>/dev/null); "
          + "case \"$v\" in ''|*[!0-9]*) continue;; esac; "
          + "[ \"$v\" -ge 1000 ] && [ \"$v\" -le 150000 ] && [ \"$v\" -gt \"$m\" ] && m=$v; done; "
          + "temp=$((m/1000)); "
          + "echo \"$cpu $temp\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(/\s+/);
                if (parts.length >= 2) { root.cpu = parts[0]; root.temp = parts[1]; }
            }
        }
    }

    // Re-poll CPU/temp every 2s (and once at startup).
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sysProc.running = true
    }

    // CPU · temp pill.
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.pillRadius
        color: Theme.peach
        implicitHeight: Theme.pillHeight
        implicitWidth: cpuRow.implicitWidth + 24

        Row {
            id: cpuRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf2db" // nf-fa-microchip
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontIcon
                color: Theme.onAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.cpu + "% · " + root.temp + "°"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.onAccent
            }
        }
    }

    // Volume pill (dims when muted).
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.pillRadius
        color: Theme.sapphire
        opacity: root.muted ? 0.55 : 1.0
        implicitHeight: Theme.pillHeight
        implicitWidth: volRow.implicitWidth + 24

        Row {
            id: volRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "\uf026" : "\uf028" // nf-fa-volume_off / volume_up
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontIcon
                color: Theme.onAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.volPct + "%"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.onAccent
            }
        }
    }
}
