import QtQuick
import "root:/"

// OSD variant 9c — "Centered, ring dial". No card: a sweep around the glyph, with
// the number beneath. QML has no conic gradient, so the ring is drawn on a Canvas.
// Scales in from 96% rather than sliding (design).
Item {
    id: root
    required property var osd

    readonly property int dia: 150
    implicitWidth: dia
    implicitHeight: dia + 46

    opacity: osd.active ? 1.0 : 0.0
    scale: osd.active ? 1.0 : 0.96
    Behavior on opacity { NumberAnimation { duration: root.osd.cfg.fadeMs } }
    Behavior on scale { NumberAnimation { duration: root.osd.cfg.fadeMs; easing.type: Easing.OutCubic } }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        Item {
            width: root.dia; height: root.dia

            Canvas {
                id: ring
                anchors.fill: parent
                // Repaint whenever the sweep or its colour changes.
                property real frac: Math.max(0, Math.min(100, root.osd.pct)) / 100
                property color sweep: root.osd.fill
                onFracChanged: requestPaint()
                onSweepChanged: requestPaint()
                Behavior on frac { NumberAnimation { duration: 120 } }

                onPaint: {
                    const ctx = getContext("2d");
                    const w = width, h = height;
                    const cx = w / 2, cy = h / 2;
                    const lw = 13;                     // ring thickness (design: 13 px inset)
                    const r = (Math.min(w, h) - lw) / 2;
                    ctx.reset();

                    // Track
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.lineWidth = lw;
                    ctx.strokeStyle = Qt.rgba(Theme.surface0.r, Theme.surface0.g,
                                              Theme.surface0.b, 0.85);
                    ctx.stroke();

                    // Sweep, clockwise from 12 o'clock
                    if (ring.frac > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, -Math.PI / 2,
                                -Math.PI / 2 + Math.PI * 2 * ring.frac);
                        ctx.lineWidth = lw;
                        ctx.strokeStyle = ring.sweep;
                        ctx.stroke();
                    }
                }
            }

            // Inner disc + glyph
            Rectangle {
                anchors.centerIn: parent
                width: root.dia - 26; height: root.dia - 26
                radius: width / 2
                color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.92)
                Text {
                    anchors.centerIn: parent
                    text: root.osd.glyph
                    font.family: Theme.fontMono
                    font.pixelSize: 44
                    color: root.osd.fill
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            implicitWidth: label.implicitWidth + 26
            implicitHeight: label.implicitHeight + 10
            radius: 9
            color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.82)
            Text {
                id: label
                anchors.centerIn: parent
                text: root.osd.muted ? "MUTED" : root.osd.pct + "%"
                font.family: Theme.fontMono
                font.pixelSize: 16
                font.bold: true
                font.letterSpacing: 0.5
                color: Theme.fg
            }
        }
    }
}
