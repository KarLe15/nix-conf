import QtQuick
import "../Config"
import "paint.js" as Paint

// The gate's outer body: the naquadah ring and the three bands stepped into its
// rim. Static — it never repaints after the first frame.
//
// Radii are quoted for the design's 760px gate and scaled by `k`, so changing
// gate.diameter in the preset rescales the whole assembly.
Canvas {
    id: root

    readonly property real k: width / 760
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real r: width / 2

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        // Body, lit from the middle outwards. Clipped, because the gradient fills
        // its whole rect and the gate is round.
        ctx.save()
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
        ctx.clip()
        Paint.ellipseGradient(ctx, cx, cy, r, r, [
            [0.00, Paint.rgba(Theme.surface0, 1)],
            [0.60, Paint.rgba(Theme.surface0, 1)],
            [0.70, Paint.rgba(Theme.unlit, 1)],
            [1.00, Paint.rgba(Theme.base, 1)]
        ], width, height)
        ctx.restore()

        // The rim, stepped inwards: a bright outer lip, a deep shadow channel,
        // then the shoulder the inner ring turns against.
        Paint.ring(ctx, cx, cy, r - 18 * k, r - 16 * k, Paint.rgba(Theme.surface0, 1))
        Paint.ring(ctx, cx, cy, r - 16 * k, r -  3 * k, Paint.rgba(Theme.base, 1))
        Paint.ring(ctx, cx, cy, r -  3 * k, r,          Paint.rgba(Theme.surface1, 1))
    }

    onWidthChanged: requestPaint()
}
