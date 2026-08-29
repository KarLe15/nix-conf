import QtQuick
import "root:/"

// Network throughput (Screen Bars · terminal screen): upload + download rate pills.
// A pure view over the shared Sys singleton (which samples /proc/net/dev) — no poller
// of its own. Two filled pills — sky up, green down — with fixed-width rate slots so
// they don't jitter as the rate changes magnitude.
Row {
    id: root
    spacing: 8

    readonly property real upBps: Sys.netTxBps
    readonly property real downBps: Sys.netRxBps

    function _fmt(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M";
        if (bps >= 1024)    return Math.round(bps / 1024) + "k";
        return Math.round(bps) + "B";
    }

    // Widest rate string, for constant-width number slots.
    TextMetrics {
        id: rateMetrics
        font.family: Theme.fontMono
        font.pixelSize: Theme.fontNormal
        font.bold: true
        text: "88.8M"
    }

    component RatePill: Rectangle {
        property string glyph: ""
        property string rate: ""
        property color fill: Theme.surface
        radius: Theme.pillRadius
        color: fill
        implicitHeight: Theme.pillHeight
        implicitWidth: seg.implicitWidth + 20
        Row {
            id: seg
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: glyph
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontIcon
                color: Theme.onAccent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: rateMetrics.width
                horizontalAlignment: Text.AlignRight
                text: rate
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.onAccent
            }
        }
    }

    RatePill { glyph: "\uf062"; rate: root._fmt(root.upBps);   fill: Theme.sky }    // upload (arrow-up)
    RatePill { glyph: "\uf063"; rate: root._fmt(root.downBps); fill: Theme.green }  // download (arrow-down)
}
