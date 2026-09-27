import QtQuick
import "../Config"
import "paint.js" as Paint

// The hub the event horizon sits in, drawn over the turning ring: three stepped
// bands and then the dark well itself.
Canvas {
    id: root

    readonly property real k: width / 760
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real well: (width / 2) - 132 * k

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        Paint.ring(ctx, cx, cy, well, well + 12 * k, Paint.rgba(Theme.surface0, 1))
        Paint.ring(ctx, cx, cy, well, well + 10 * k, Paint.rgba(Theme.base, 1))
        Paint.ring(ctx, cx, cy, well, well +  3 * k, Paint.rgba(Theme.surface1, 1))
        Paint.disc(ctx, cx, cy, well, Paint.rgba(Theme.crust, 1))
    }

    onWidthChanged: requestPaint()
}
