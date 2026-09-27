import QtQuick
import "../Config"
import "paint.js" as Paint

// The dial-home device. Two rings of nineteen keys around the point-of-origin
// dome, idling: roughly one key in five is lit and the whole board reshuffles
// every `dhd.shimmerMs`. Nothing here is interactive — this screen is ambience,
// the gate takes the keyboard.
Item {
    id: root

    readonly property real k: width / 760
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real r: width / 2
    readonly property int keys: Config.dhd.keys

    // Bumped on every shimmer tick; feeds the hash that picks the lit keys.
    property int seed: 0

    // One repaint per tick, not per frame.
    onSeedChanged: keyCanvas.requestPaint()

    property color litColor: Theme.peach

    width: Config.dhd.diameter
    height: width

    Timer {
        interval: Config.dhd.shimmerMs
        running: true
        repeat: true
        onTriggered: root.seed++
    }

    // Key placement, shared by the painted housings and the number labels.
    // `ring` is 0 for the outer row, 1 for the inner one.
    function keyGeometry(ring, i) {
        const step = 360 / root.keys
        return {
            "deg": (ring === 0 ? 0 : 9.47) + i * step,
            "dist": (ring === 0 ? 306 : 222) * root.k,
            "w": (ring === 0 ? 92 : 66) * root.k,
            "h": (ring === 0 ? 74 : 62) * root.k,
            "taper": ring === 0 ? 0.18 : 0.20,
            // Offset of the number's centre from the key's, along the key's axis.
            "numberDy": (ring === 0 ? -4.5 : -5.0) * root.k,
            "numberSize": (ring === 0 ? 13 : 12) * root.k,
            "label": ("0" + (ring * root.keys + i + 1)).slice(-2)
        }
    }

    function keyLit(ring, i) {
        return Paint.keyLit(root.seed, i + ring * 50)
    }

    // ---- Body ---------------------------------------------------------------
    Canvas {
        id: body
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            ctx.save()
            ctx.beginPath()
            ctx.arc(root.cx, root.cy, root.r, 0, Math.PI * 2, false)
            ctx.clip()
            Paint.ellipseGradient(ctx, root.cx, root.cy, root.r, root.r, [
                [0.00, Paint.rgba(Theme.unlit, 1)],
                [0.55, Paint.rgba(Theme.unlit, 1)],
                [0.72, Paint.rgba(Theme.base, 1)],
                [1.00, Paint.rgba(Theme.mantle, 1)]
            ], width, height)
            ctx.restore()

            Paint.ring(ctx, root.cx, root.cy, root.r - 16 * root.k, root.r - 14 * root.k,
                       Paint.rgba(Theme.surface0, 1))
            Paint.ring(ctx, root.cx, root.cy, root.r - 14 * root.k, root.r - 3 * root.k,
                       Paint.rgba(Theme.mantle, 1))
            Paint.ring(ctx, root.cx, root.cy, root.r - 3 * root.k, root.r,
                       Paint.rgba(Theme.surface1, 1))

            // The plate the keys stand on.
            const plate = root.r - 220 * root.k
            Paint.ring(ctx, root.cx, root.cy, plate, plate + 3 * root.k,
                       Paint.rgba(Theme.surface0, 1))
            Paint.disc(ctx, root.cx, root.cy, plate, Paint.rgba(Theme.mantle, 1))
        }

        onWidthChanged: requestPaint()
    }

    // ---- Keys ---------------------------------------------------------------
    Canvas {
        id: keyCanvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            for (let ring = 0; ring < 2; ring++) {
                for (let i = 0; i < root.keys; i++) {
                    const g = root.keyGeometry(ring, i)
                    const lit = root.keyLit(ring, i)

                    ctx.save()
                    ctx.translate(root.cx, root.cy)
                    ctx.rotate(g.deg * Math.PI / 180)
                    ctx.translate(0, -g.dist)

                    Paint.trapezoid(ctx, -g.w / 2, -g.h / 2, g.w, g.h, g.taper)
                    ctx.fillStyle = Paint.rgba(Theme.surface1, 1)
                    ctx.fill()

                    Paint.trapezoid(ctx,
                        -g.w / 2 + 5 * root.k, -g.h / 2 + 3 * root.k,
                        g.w - 10 * root.k, g.h - 7 * root.k, g.taper)
                    ctx.fillStyle = lit ? Paint.rgba(root.litColor, 0.85)
                                        : Paint.rgba(Theme.base, 1)
                    ctx.fill()

                    ctx.restore()
                }
            }
        }

        onWidthChanged: requestPaint()
    }

    // Numbers as Text items rather than canvas glyphs, so they render with the
    // theme's real font instead of Context2D's font-string parsing.
    Repeater {
        model: root.keys * 2

        Text {
            readonly property int ring: index < root.keys ? 0 : 1
            readonly property int slot: index % root.keys
            readonly property var g: root.keyGeometry(ring, slot)
            readonly property real rad: g.deg * Math.PI / 180

            text: g.label
            font.family: Theme.fontMono
            font.pixelSize: g.numberSize
            font.weight: Font.DemiBold
            color: root.keyLit(ring, slot) ? Theme.crust : Theme.surface2

            // Key centre, then the number's own offset rotated with the key —
            // the label itself stays upright, as it does on the prop.
            x: root.cx + g.dist * Math.sin(rad) - g.numberDy * Math.sin(rad) - width / 2
            y: root.cy - g.dist * Math.cos(rad) + g.numberDy * Math.cos(rad) - height / 2
        }
    }

    // ---- Point of origin ----------------------------------------------------
    Canvas {
        id: dome
        anchors.fill: parent

        readonly property real domeR: root.r - 262 * root.k

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            // Bloom around the dome.
            const halo = ctx.createRadialGradient(root.cx, root.cy, domeR,
                                                  root.cx, root.cy, domeR + 70 * root.k)
            halo.addColorStop(0.0, Paint.rgba(Theme.red, 0.35))
            halo.addColorStop(1.0, Paint.rgba(Theme.red, 0.0))
            ctx.fillStyle = halo
            ctx.beginPath()
            ctx.arc(root.cx, root.cy, domeR + 70 * root.k, 0, Math.PI * 2, false)
            ctx.fill()

            Paint.ring(ctx, root.cx, root.cy, domeR + 6 * root.k, domeR + 9 * root.k,
                       Paint.rgba(Theme.surface1, 1))
            Paint.ring(ctx, root.cx, root.cy, domeR, domeR + 6 * root.k,
                       Paint.rgba(Theme.base, 1))

            // Lit from the upper left, like the show's crystal dome.
            const lx = root.cx - domeR * 0.16
            const ly = root.cy - domeR * 0.28
            const g = ctx.createRadialGradient(lx, ly, 0, lx, ly, domeR * 1.3)
            g.addColorStop(0.00, Paint.rgba(Theme.flamingo, 1))
            g.addColorStop(0.38, Paint.rgba(Theme.red, 1))
            g.addColorStop(0.78, Paint.rgba(Qt.darker(Theme.red, 1.9), 1))
            g.addColorStop(1.00, Paint.rgba(Qt.darker(Theme.red, 3.0), 1))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(root.cx, root.cy, domeR, 0, Math.PI * 2, false)
            ctx.fill()
        }

        onWidthChanged: requestPaint()
    }

    Column {
        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "POINT D'ORIGINE"
            font.family: Theme.fontMono
            font.pixelSize: 13 * root.k
            font.bold: true
            font.letterSpacing: 3 * root.k
            color: Theme.crust
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Config.dhd.origin
            font.family: Theme.fontMono
            font.pixelSize: 34 * root.k
            font.bold: true
            color: Theme.crust
        }
    }
}
