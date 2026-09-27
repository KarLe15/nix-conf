import QtQuick
import "../Config"
import "paint.js" as Paint

// The inner ring that carries the gate's glyphs. It turns 40 degrees per coded
// character (gate.degPerChar), so its rotation is the one moving part of the
// dial; the painting itself is static and only the item is transformed.
Canvas {
    id: root

    readonly property real k: width / 760
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real r: width / 2

    // 39 slots on the show's gate, one per glyph.
    readonly property int slots: Config.gate.symbolSlots
    readonly property real slotDeg: 360 / slots

    Behavior on rotation {
        NumberAnimation {
            duration: Config.gate.dialMs
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.3, 0.7, 0.2, 1.0, 1.0, 1.0]
        }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        // Outer band: one bright glyph tick per slot against a dark ground.
        const bandIn = r - 50 * k
        const bandOut = r - 44 * k
        Paint.ring(ctx, cx, cy, bandIn, bandOut, Paint.rgba(Theme.base, 1))
        for (let i = 0; i < slots; i++) {
            const from = -1 + i * slotDeg
            Paint.sector(ctx, cx, cy, bandIn, bandOut, from, from + 1.4,
                         Paint.rgba(Theme.surface2, 1))
        }

        // Inner face, with the hairline separating each slot.
        const faceIn = (r - 50 * k) * 0.575
        const faceOut = r - 50 * k
        Paint.ring(ctx, cx, cy, faceIn, faceOut, Paint.rgba(Theme.mantle, 1))
        for (let j = 0; j < slots; j++) {
            const base = 3.6 + j * slotDeg
            Paint.sector(ctx, cx, cy, faceIn, faceOut, base + 2.6, base + 3.2,
                         Paint.rgba(Theme.surface0, 1))
        }
    }

    onWidthChanged: requestPaint()
}
