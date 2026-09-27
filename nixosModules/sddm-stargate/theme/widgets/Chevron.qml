import QtQuick
import "../Config"
import "paint.js" as Paint

// One of the nine chevrons. The canvas is deliberately larger than the chevron
// so an engaged one has room to bloom: the glow is painted into the same canvas
// with a `lighter` composite instead of a blur effect, which keeps the theme on
// plain QtQuick.
Canvas {
    id: root

    // The chevron's own footprint, in design pixels; the canvas pads it.
    readonly property real k: width / 122
    readonly property real boxW: 62 * k
    readonly property real boxH: 58 * k
    readonly property real ox: (width - boxW) / 2
    readonly property real oy: (height - boxH) / 2

    property bool lit: false
    property color litColor: Theme.peach

    width: 122
    height: 118

    onWidthChanged: requestPaint()
    onLitChanged: requestPaint()
    onLitColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        // Housing, then the recess the light sits in.
        Paint.trapezoid(ctx, ox, oy, boxW, boxH, 0.22)
        ctx.fillStyle = Paint.rgba(Theme.surface1, 1)
        ctx.fill()

        Paint.trapezoid(ctx, ox + 6 * k, oy + 4 * k, boxW - 12 * k, boxH - 12 * k, 0.22)
        ctx.fillStyle = Paint.rgba(Theme.mantle, 1)
        ctx.fill()

        // The light itself: a downward triangle.
        const lx = ox + 15 * k
        const ly = oy + 9 * k
        const lw = boxW - 30 * k
        const lh = 30 * k
        Paint.polygon(ctx, [
            [lx, ly],
            [lx + lw, ly],
            [lx + lw / 2, ly + lh]
        ])
        ctx.fillStyle = lit ? Paint.rgba(litColor, 1) : Paint.rgba(Theme.unlit, 1)
        ctx.fill()

        if (!lit)
            return

        // Bloom over the housing, the way the show's chevrons wash out their own
        // casing when they engage.
        const gx = lx + lw / 2
        const gy = ly + lh / 2
        const gr = 44 * k
        const g = ctx.createRadialGradient(gx, gy, 0, gx, gy, gr)
        g.addColorStop(0.0, Paint.rgba(litColor, 0.38))
        g.addColorStop(0.45, Paint.rgba(litColor, 0.16))
        g.addColorStop(1.0, Paint.rgba(litColor, 0.0))
        ctx.globalCompositeOperation = "lighter"
        ctx.fillStyle = g
        ctx.fillRect(0, 0, width, height)
        ctx.globalCompositeOperation = "source-over"
    }
}
