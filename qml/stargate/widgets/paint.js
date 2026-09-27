.pragma library

// Canvas helpers shared by every painted widget in this theme.
//
// The theme deliberately sticks to plain QtQuick — no QtQuick.Shapes, no
// Qt5Compat.GraphicalEffects — so that a missing QML plugin can never stop the
// greeter from loading and SDDM never has to fall back to its embedded theme.
// Everything that is not a rectangle is therefore drawn here.

// Colour as a string QML's Context2D parses unambiguously. Passing a QColor
// straight to fillStyle works, but addColorStop is stricter, so both go through
// this for consistency.
function rgba(c, a) {
    var alpha = (a === undefined) ? c.a : a
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255)
         + "," + Math.round(c.b * 255) + "," + alpha + ")"
}

// CSS angles run clockwise from twelve o'clock; canvas angles run clockwise from
// three o'clock. Every angle in this theme is quoted the CSS way, matching the
// design, and converted here.
function rad(cssDeg) {
    return (cssDeg - 90) * Math.PI / 180
}

// Filled annulus between two radii, centred on (cx, cy).
function ring(ctx, cx, cy, inner, outer, style) {
    ctx.beginPath()
    ctx.arc(cx, cy, outer, 0, Math.PI * 2, false)
    ctx.arc(cx, cy, inner, 0, Math.PI * 2, true)
    ctx.fillStyle = style
    ctx.fill()
}

// Filled disc.
function disc(ctx, cx, cy, r, style) {
    ctx.beginPath()
    ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
    ctx.fillStyle = style
    ctx.fill()
}

// Wedge of an annulus, from `fromDeg` to `toDeg` (CSS angles).
function sector(ctx, cx, cy, inner, outer, fromDeg, toDeg, style) {
    var a0 = rad(fromDeg), a1 = rad(toDeg)
    ctx.beginPath()
    ctx.arc(cx, cy, outer, a0, a1, false)
    ctx.arc(cx, cy, inner, a1, a0, true)
    ctx.closePath()
    ctx.fillStyle = style
    ctx.fill()
}

// An elliptical radial gradient, which Context2D cannot express directly: the
// canvas is squashed around the focus so a circular gradient comes out as the
// ellipse the design asks for. `stops` is [[offset, cssColour], ...].
function ellipseGradient(ctx, cx, cy, rx, ry, stops, w, h) {
    ctx.save()
    ctx.translate(cx, cy)
    ctx.scale(1, ry / rx)
    ctx.translate(-cx, -cy)
    var g = ctx.createRadialGradient(cx, cy, 0, cx, cy, rx)
    for (var i = 0; i < stops.length; i++)
        g.addColorStop(stops[i][0], stops[i][1])
    ctx.fillStyle = g
    ctx.fillRect(-w, -h, w * 3, h * 3)
    ctx.restore()
}

// Path through a list of [x, y] points, closed.
function polygon(ctx, points) {
    ctx.beginPath()
    ctx.moveTo(points[0][0], points[0][1])
    for (var i = 1; i < points.length; i++)
        ctx.lineTo(points[i][0], points[i][1])
    ctx.closePath()
}

// A chevron/DHD-key housing: a rectangle whose bottom edge is pulled in by
// `taper` on each side, as a fraction of the width.
function trapezoid(ctx, x, y, w, h, taper) {
    polygon(ctx, [
        [x, y],
        [x + w, y],
        [x + w - w * taper, y + h],
        [x + w * taper, y + h]
    ])
}

// Idle shimmer of the DHD keys, reproduced from the design so the two match:
// a hash of (time bucket, key index) lights roughly one key in five, and the
// whole board reshuffles when the bucket changes.
function keyLit(seed, index) {
    var x = Math.sin(seed * 97.13 + index * 13.7) * 43758.5
    return (x - Math.floor(x)) > 0.8
}

// Up to two initials for an avatar disc. Falls back to the first two letters
// when the name is a single word, which is the usual case for a login name.
function initials(name) {
    if (!name)
        return "?"
    var parts = name.trim().split(/[\s._-]+/).filter(function (p) { return p.length > 0 })
    if (parts.length === 0)
        return "?"
    if (parts.length === 1)
        return parts[0].substring(0, 2).toUpperCase()
    return (parts[0][0] + parts[1][0]).toUpperCase()
}
