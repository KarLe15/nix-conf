import QtQuick
import Quickshell.Io
import "root:/"

// CPU + GPU temperature pill (Screen Bars · code screen). A peach dark-on-accent
// pill showing the CPU (k10temp) and GPU (amdgpu) package temperatures, read from
// hwmon every 2s. Fixed-width degree slots so it doesn't jitter as a reading moves
// between two and three digits.
Rectangle {
    id: root
    property int cpuTemp: 0
    property int gpuTemp: 0

    radius: Theme.pillRadius
    color: Theme.peach
    implicitHeight: Theme.pillHeight
    implicitWidth: pillRow.implicitWidth + 20

    // Poll the two hwmon sensors (same sources as SystemModule's metrics probe).
    Process {
        id: proc
        running: false
        command: ["sh", "-c",
            "cput=0; gput=0; for h in /sys/class/hwmon/hwmon*; do "
          + "n=$(cat \"$h/name\" 2>/dev/null); case \"$n\" in "
          + "k10temp) v=$(cat \"$h/temp1_input\" 2>/dev/null); [ -n \"$v\" ] && cput=$((v/1000));; "
          + "amdgpu) v=$(cat \"$h/temp1_input\" 2>/dev/null); [ -n \"$v\" ] && gput=$((v/1000));; "
          + "esac; done; echo \"$cput $gput\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/);
                root.cpuTemp = parseInt(p[0]) || 0;
                root.gpuTemp = parseInt(p[1]) || 0;
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    // Widest degree reading, for constant-width number slots.
    TextMetrics {
        id: degMetrics
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontNormal
        font.bold: true
        text: "88°"
    }

    component TempSeg: Row {
        property string tag: ""
        property int value: 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tag
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            opacity: 0.7
            color: Theme.onAccent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: degMetrics.width
            horizontalAlignment: Text.AlignRight
            text: value + "°"
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: Theme.onAccent
        }
    }

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 9

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf2c9"  // nf-fa-thermometer_half
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: Theme.onAccent
        }

        TempSeg { tag: "CPU"; value: root.cpuTemp }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: Math.round(Theme.pillHeight * 0.4)
            color: Qt.rgba(0, 0, 0, 0.28)
        }

        TempSeg { tag: "GPU"; value: root.gpuTemp }
    }
}
