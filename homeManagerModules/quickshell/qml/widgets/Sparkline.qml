import QtQuick
import "root:/"

// A small area+line time-series chart for the gaming panel. `values` is a rolling
// array (newest last); `maxValue` = 0 auto-scales to the window's peak.
Canvas {
    id: root
    property var values: []
    property color stroke: Theme.mauve
    property real fillOpacity: 0.14
    property real maxValue: 0

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const vs = values;
        const n = vs ? vs.length : 0;
        const w = width, h = height;
        if (n < 2)
            return;

        let mx = maxValue;
        if (mx <= 0) {
            mx = 1;
            for (let i = 0; i < n; i++)
                mx = Math.max(mx, vs[i]);
        }
        const stepX = w / (n - 1);
        const px = function (i) { return i * stepX; };
        const py = function (v) {
            const c = Math.max(0, Math.min(mx, v));
            return h - (c / mx) * (h - 3) - 1.5;
        };

        // Filled area under the line.
        ctx.beginPath();
        ctx.moveTo(px(0), py(vs[0]));
        for (let j = 1; j < n; j++)
            ctx.lineTo(px(j), py(vs[j]));
        ctx.lineTo(px(n - 1), h);
        ctx.lineTo(px(0), h);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, root.fillOpacity);
        ctx.fill();

        // Line on top.
        ctx.beginPath();
        ctx.moveTo(px(0), py(vs[0]));
        for (let k = 1; k < n; k++)
            ctx.lineTo(px(k), py(vs[k]));
        ctx.lineWidth = 1.5;
        ctx.strokeStyle = root.stroke;
        ctx.stroke();
    }
}
