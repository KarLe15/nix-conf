import QtQuick
import "root:/"

// CPU + GPU temperature pill (Screen Bars · code screen). A peach dark-on-accent
// pill showing the CPU (k10temp) and GPU (amdgpu) package temperatures. A pure view
// over the shared Sys singleton — no polling of its own. Fixed-width degree slots so
// it doesn't jitter as a reading moves between two and three digits.
Rectangle {
    id: root
    readonly property int cpuTemp: Sys.cpuTemp
    readonly property int gpuTemp: Sys.gpuTemp

    radius: Theme.pillRadius
    color: Theme.peach
    implicitHeight: Theme.pillHeight
    implicitWidth: pillRow.implicitWidth + 20

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
