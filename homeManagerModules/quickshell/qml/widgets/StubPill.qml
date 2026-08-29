import QtQuick
import "root:/"

// A static "design stub" pill (Screen Bars · Filled). Renders a filled Catppuccin
// pill straight from layout data — a Nerd Font glyph, an optional label, and a
// palette color *name* — standing in for a widget that isn't built yet. Dark-on-
// accent, matching the filled treatment. An empty label makes it an icon-only
// square. Replace a stub by adding its real widget to WidgetSlot's registry.
Rectangle {
    id: root
    property string icon: ""
    property string label: ""
    property string colorName: "surface"
    property bool dashed: false     // conditional/"troll" pills — hint with a dashed ring

    readonly property bool iconOnly: label.length === 0
    readonly property color fill:
        Theme[colorName] !== undefined ? Theme[colorName] : Theme.surface

    radius: Theme.pillRadius
    color: fill
    implicitHeight: Theme.pillHeight
    implicitWidth: iconOnly ? Theme.pillHeight : (contentRow.implicitWidth + 20)

    // Inner dashed ring for "conditional" pills (approximates the mockup's dashed
    // outline; a real widget would gate its own visibility instead).
    Canvas {
        anchors.fill: parent
        anchors.margins: 3
        visible: root.dashed
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.35);
            ctx.lineWidth = 1.5;
            ctx.setLineDash([4, 3]);
            const r = Math.max(0, root.radius - 1);
            const w = width, h = height;
            ctx.beginPath();
            ctx.moveTo(r, 0);
            ctx.arcTo(w, 0, w, h, r);
            ctx.arcTo(w, h, 0, h, r);
            ctx.arcTo(0, h, 0, 0, r);
            ctx.arcTo(0, 0, w, 0, r);
            ctx.closePath();
            ctx.stroke();
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: Theme.onAccent
        }
        Text {
            visible: !root.iconOnly
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: Theme.onAccent
        }
    }
}
