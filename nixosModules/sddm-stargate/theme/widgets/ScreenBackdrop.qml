import QtQuick
import "../Config"
import "paint.js" as Paint

// The gate room's ambient lighting: an elliptical pool of Base fading out to
// Crust. Painted rather than declared because QtQuick has no radial gradient
// fill and this theme keeps clear of Qt5Compat.GraphicalEffects.
Canvas {
    id: root

    // Centre of the pool, as a fraction of the screen. The gate screen lights
    // its middle; the two ambience screens light their left, where the DHD and
    // the E2PZ panel sit.
    property real focusX: 0.5
    property real focusY: 0.55

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        Paint.ellipseGradient(ctx,
            width * focusX, height * focusY,
            width * 0.70, height * 0.80,
            [
                [0.00, Paint.rgba(Theme.base, 1)],
                [0.45, Paint.rgba(Theme.mantle, 1)],
                [0.80, Paint.rgba(Theme.crust, 1)],
                [1.00, Paint.rgba(Theme.crust, 1)]
            ],
            width, height)
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
