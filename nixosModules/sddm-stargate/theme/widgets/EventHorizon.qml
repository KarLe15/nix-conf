import QtQuick
import "../Config"
import "paint.js" as Paint

// What sits in the gate's well. Idle it is a dark pool with a slow shimmer on the
// rim; once chevron seven locks it becomes the vortex — an unstable surge, then
// standing ripples.
//
// Every layer paints once and is then only transformed, so the animation costs a
// scale and an opacity rather than a canvas repaint per frame.
Item {
    id: root

    property bool active: false
    property color horizon: Theme.blue

    readonly property real r: width / 2

    // ---- The pool -----------------------------------------------------------
    Canvas {
        id: pool
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const stops = root.active
                ? [[0.00, Paint.rgba(root.horizon, 0.55)],
                   [0.45, Paint.rgba(root.horizon, 0.32)],
                   [0.85, Paint.rgba(Theme.crust, 0.92)],
                   [1.00, Paint.rgba(Theme.crust, 0.92)]]
                : [[0.00, Paint.rgba(Theme.mantle, 1)],
                   [0.70, Paint.rgba(Theme.crust, 1)],
                   [1.00, Paint.rgba(Theme.crust, 1)]]
            ctx.save()
            ctx.beginPath()
            ctx.arc(root.r, root.r, root.r, 0, Math.PI * 2, false)
            ctx.clip()
            Paint.ellipseGradient(ctx, root.r, root.r, root.r, root.r, stops,
                                  width, height)
            ctx.restore()
        }

        onWidthChanged: requestPaint()
    }

    onActiveChanged: {
        pool.requestPaint()
        if (active)
            surge.restart()
    }

    onHorizonChanged: {
        pool.requestPaint()
        shimmer.requestPaint()
        ripple.requestPaint()
        kawoosh.requestPaint()
    }

    // ---- Idle shimmer on the rim -------------------------------------------
    Canvas {
        id: shimmer
        anchors.fill: parent
        visible: !root.active
        opacity: 0.5

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const g = ctx.createRadialGradient(root.r, root.r, 0, root.r, root.r, root.r)
            g.addColorStop(0.00, Paint.rgba(root.horizon, 0.0))
            g.addColorStop(0.55, Paint.rgba(root.horizon, 0.0))
            g.addColorStop(0.80, Paint.rgba(root.horizon, 0.08))
            g.addColorStop(1.00, Paint.rgba(root.horizon, 0.0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(root.r, root.r, root.r, 0, Math.PI * 2, false)
            ctx.fill()
        }

        onWidthChanged: requestPaint()

        SequentialAnimation on opacity {
            running: !root.active
            loops: Animation.Infinite
            NumberAnimation { from: 0.5; to: 0.85; duration: 3000; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.85; to: 0.5; duration: 3000; easing.type: Easing.InOutQuad }
        }
    }

    // ---- Standing ripples, once the vortex is up ---------------------------
    // Drawn short of the edge so that breathing out to 1.07 still lands inside
    // the well — QtQuick cannot clip to a circle without an effect.
    Canvas {
        id: ripple
        anchors.fill: parent
        visible: root.active
        opacity: 0.55
        transformOrigin: Item.Center

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const limit = root.r * 0.935
            for (let a = 0; a + 5 < limit; a += 24)
                Paint.ring(ctx, root.r, root.r, a, a + 5, Paint.rgba(root.horizon, 0.22))
            for (let b = 12; b + 4 < limit; b += 34)
                Paint.ring(ctx, root.r, root.r, b, b + 4, Paint.rgba(Theme.lavender, 0.12))
        }

        onWidthChanged: requestPaint()

        SequentialAnimation {
            running: root.active
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation { target: ripple; property: "scale"; from: 1.0; to: 1.07; duration: 1800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: ripple; property: "opacity"; from: 0.55; to: 0.9; duration: 1800; easing.type: Easing.InOutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: ripple; property: "scale"; from: 1.07; to: 1.0; duration: 1800; easing.type: Easing.InOutQuad }
                NumberAnimation { target: ripple; property: "opacity"; from: 0.9; to: 0.55; duration: 1800; easing.type: Easing.InOutQuad }
            }
        }
    }

    // ---- The unstable vortex ------------------------------------------------
    // Mostly for previewState=success: SDDM closes every view the moment the
    // login is accepted, so on a real login this barely gets a frame.
    Canvas {
        id: kawoosh
        anchors.fill: parent
        visible: root.active
        opacity: 0
        scale: 0.15
        transformOrigin: Item.Center

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const g = ctx.createRadialGradient(root.r, root.r, 0, root.r, root.r, root.r)
            g.addColorStop(0.00, Paint.rgba(Theme.rosewater, 1))
            g.addColorStop(0.40, Paint.rgba(root.horizon, 0.9))
            g.addColorStop(0.70, Paint.rgba(root.horizon, 0.0))
            g.addColorStop(1.00, Paint.rgba(root.horizon, 0.0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(root.r, root.r, root.r, 0, Math.PI * 2, false)
            ctx.fill()
        }

        onWidthChanged: requestPaint()
    }

    SequentialAnimation {
        id: surge
        ParallelAnimation {
            NumberAnimation { target: kawoosh; property: "scale"; from: 0.15; to: 1.4; duration: 242; easing.type: Easing.OutQuad }
            NumberAnimation { target: kawoosh; property: "opacity"; from: 0; to: 1; duration: 242 }
        }
        ParallelAnimation {
            NumberAnimation { target: kawoosh; property: "scale"; from: 1.4; to: 1.0; duration: 858; easing.type: Easing.OutQuad }
            NumberAnimation { target: kawoosh; property: "opacity"; from: 1; to: 0; duration: 858 }
        }
    }
}
