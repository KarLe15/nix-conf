import QtQuick
import "../Config"
import "paint.js" as Paint

// A zero point module. Seven faceted crystal columns over a lit base, drawn in
// the design's 150x432 space and scaled from there; the charge shows as how much
// of the crystal is warm rather than as a number.
Item {
    id: root

    // One entry of MissionData.zpmTones — the full / low / spent palettes.
    property var tone

    readonly property real s: width / 150

    // The crystal is lit by its own colours rather than the palette, so they come
    // in as strings and are converted here for the canvas.
    readonly property color haloColor: tone ? tone.halo : "transparent"
    readonly property color coreColor: tone ? tone.core : "transparent"

    onToneChanged: {
        halo.requestPaint()
        crystal.requestPaint()
    }

    width: 150
    height: 430

    // ---- Facets, quoted from the design's SVG ------------------------------
    readonly property var facets: [
        [[12, 370], [12, 44], [20, 26], [30, 36], [30, 370]],
        [[30, 370], [30, 36], [38, 8], [48, 22], [48, 370]],
        [[48, 370], [48, 22], [55, 30], [66, 14], [66, 370]],
        [[66, 370], [66, 14], [75, 4], [84, 18], [84, 370]],
        [[84, 370], [84, 18], [92, 34], [102, 26], [102, 370]],
        [[102, 370], [102, 26], [112, 12], [120, 30], [120, 370]],
        [[120, 370], [120, 30], [130, 40], [138, 52], [138, 370]]
    ]

    // Etched lines down each facet.
    readonly property var etches: [
        [21, 30, 250], [39, 14, 262], [57, 28, 276], [75, 8, 282],
        [93, 32, 276], [111, 16, 284], [129, 42, 270]
    ]

    // The charge bands at the foot of each facet. Two of them read as status
    // lights on the prop, hence the green and red.
    readonly property var bands: [
        { "pts": [[12, 370], [12, 262], [20, 244], [30, 262], [30, 370]], "fill": "green" },
        { "pts": [[30, 370], [30, 280], [39, 258], [48, 280], [48, 370]], "fill": "arch" },
        { "pts": [[48, 370], [48, 292], [57, 272], [66, 292], [66, 370]], "fill": "arch" },
        { "pts": [[66, 370], [66, 298], [75, 280], [84, 298], [84, 370]], "fill": "arch" },
        { "pts": [[84, 370], [84, 292], [93, 272], [102, 292], [102, 370]], "fill": "arch" },
        { "pts": [[102, 370], [102, 300], [111, 282], [120, 300], [120, 370]], "fill": "red" },
        { "pts": [[120, 370], [120, 286], [129, 266], [138, 286], [138, 370]], "fill": "arch" }
    ]

    // ---- Bloom --------------------------------------------------------------
    // Drawn first and allowed to spill outside the crystal's own box.
    Canvas {
        id: halo
        x: -55 * root.s
        y: 40 * root.s
        width: 260 * root.s
        height: 380 * root.s
        visible: root.tone !== undefined && root.tone.haloAlpha > 0

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (!visible)
                return
            Paint.ellipseGradient(ctx, width / 2, height / 2, width / 2, height * 0.48, [
                [0.0, Paint.rgba(root.haloColor, root.tone.haloAlpha)],
                [0.7, Paint.rgba(root.haloColor, 0)],
                [1.0, Paint.rgba(root.haloColor, 0)]
            ], width, height)
        }

        onWidthChanged: requestPaint()
    }

    Canvas {
        id: crystal
        anchors.fill: parent

        // A horizontal gradient across one polygon's own width, which is what the
        // SVG's default objectBoundingBox gradient units give per facet.
        function facetFill(ctx, pts) {
            let minX = pts[0][0], maxX = pts[0][0]
            for (let i = 1; i < pts.length; i++) {
                minX = Math.min(minX, pts[i][0])
                maxX = Math.max(maxX, pts[i][0])
            }
            const g = ctx.createLinearGradient(minX, 0, maxX, 0)
            g.addColorStop(0.00, root.tone.facetDark)
            g.addColorStop(0.35, root.tone.facetLight)
            g.addColorStop(0.70, root.tone.facetMid)
            g.addColorStop(1.00, root.tone.facetDeep)
            return g
        }

        // The glow trapped inside the crystal: an elliptical core that fades out.
        function core(ctx, cx, cy, rx, ry, alpha) {
            if (root.tone.coreAlpha <= 0)
                return
            ctx.save()
            ctx.translate(cx, cy)
            ctx.scale(1, ry / rx)
            ctx.translate(-cx, -cy)
            const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, rx)
            g.addColorStop(0.0, Paint.rgba(root.coreColor, root.tone.coreAlpha * alpha))
            g.addColorStop(1.0, Paint.rgba(root.coreColor, 0))
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.arc(cx, cy, rx, 0, Math.PI * 2, false)
            ctx.fill()
            ctx.restore()
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (root.tone === undefined)
                return

            ctx.save()
            ctx.scale(root.s, root.s)
            ctx.lineJoin = "round"
            const edge = Paint.rgba(Theme.crust, 1)

            for (let f = 0; f < root.facets.length; f++) {
                Paint.polygon(ctx, root.facets[f])
                ctx.fillStyle = facetFill(ctx, root.facets[f])
                ctx.fill()
                ctx.strokeStyle = edge
                ctx.lineWidth = 2.6
                ctx.stroke()
            }

            ctx.globalAlpha = 0.45
            ctx.strokeStyle = edge
            ctx.lineWidth = 1.2
            for (let e = 0; e < root.etches.length; e++) {
                ctx.beginPath()
                ctx.moveTo(root.etches[e][0], root.etches[e][1])
                ctx.lineTo(root.etches[e][0], root.etches[e][2])
                ctx.stroke()
            }
            ctx.globalAlpha = 1.0

            core(ctx, 62, 140, 40, 70, 1.0)

            for (let b = 0; b < root.bands.length; b++) {
                Paint.polygon(ctx, root.bands[b].pts)
                ctx.fillStyle = root.tone[root.bands[b].fill]
                ctx.fill()
                ctx.strokeStyle = edge
                ctx.lineWidth = 2.6
                ctx.stroke()
            }

            core(ctx, 70, 318, 26, 22, 0.8)

            // Base plate, with its own indicator panel.
            Paint.polygon(ctx, [[4, 374], [20, 362], [130, 362], [146, 374],
                                [146, 420], [130, 430], [20, 430], [4, 420]])
            ctx.fillStyle = root.tone.base
            ctx.fill()
            ctx.strokeStyle = edge
            ctx.lineWidth = 2.6
            ctx.stroke()

            Paint.polygon(ctx, [[56, 362], [94, 362], [94, 430], [56, 430]])
            ctx.fillStyle = root.tone.red
            ctx.fill()
            ctx.strokeStyle = edge
            ctx.lineWidth = 2.6
            ctx.stroke()

            ctx.beginPath()
            ctx.moveTo(20, 362); ctx.lineTo(20, 430)
            ctx.moveTo(130, 362); ctx.lineTo(130, 430)
            ctx.strokeStyle = edge
            ctx.lineWidth = 2.6
            ctx.stroke()

            ctx.globalAlpha = 0.55
            ctx.beginPath()
            ctx.moveTo(4, 384); ctx.lineTo(146, 384)
            ctx.lineWidth = 1.4
            ctx.stroke()
            ctx.globalAlpha = 1.0

            ctx.restore()
        }

        onWidthChanged: requestPaint()
    }
}
