import QtQuick
import Quickshell
import "root:/"

// Shared chrome for the bar's drop-down popovers (calendar, system, volume/BT,
// avatar control centre). Two things a bare PopupWindow does not give us:
//
//   * a gap — the window is Theme.popoverGap taller than its body and the body is
//     pushed down by it, so the panel floats clear of the bar. `anchor.margins`
//     cannot do this: it shrinks the *anchor rect*, and trimming the top of the
//     bar's rect leaves the bottom edge the popup hangs from exactly where it was.
//   * an arrow — a notch continuing the panel's fill and border, pointing back at
//     the chip that opened it, so a panel far wider than its trigger still reads
//     as belonging to it.
//
// Only the arrow and the panel take clicks; the gap is masked out of the window so
// a click there reaches the desktop and dismisses the popover through the focus
// grab, instead of landing on dead pixels.
//
// Like any PopupWindow this needs the live compositor — the *View bodies inside
// are what gets validated headlessly.
PopupWindow {
    id: popup

    // The bar item the popover hangs from — and what the arrow points at.
    property Item anchorItem
    // The panel body (a *View). Each popover assigns its own; drives the size.
    property Item body

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    readonly property int gap: Theme.popoverGap
    readonly property int arrowW: Theme.popoverArrowW
    readonly property int arrowH: Theme.popoverArrowH

    implicitWidth: body ? body.implicitWidth : 1
    implicitHeight: (body ? body.implicitHeight : 1) + gap + arrowH
    color: "transparent"
    visible: Popovers.active === popup

    mask: Region {
        Region {
            x: Math.round(popup.arrowCenter - popup.arrowW / 2)
            y: popup.gap
            width: popup.arrowW
            height: popup.arrowH
        }
        Region {
            x: 0
            y: popup.gap + popup.arrowH
            width: popup.width
            height: popup.height - popup.gap - popup.arrowH
        }
    }

    // Drop the body below the gap + arrow.
    Binding { target: popup.body; property: "y"; value: popup.gap + popup.arrowH }

    // The trigger's centre in the bar's coordinates. Re-read on open (Quickshell
    // only computes placement when the popup is shown) and when the trigger moves
    // or resizes — bar pills reflow as their text changes.
    readonly property real triggerCenter: {
        if (!anchorItem) return 0;
        popup.visible; anchorItem.x; anchorItem.width;   // binding dependencies
        return anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
    }

    // Where the window actually lands. Centring it on the trigger would push the
    // avatar's 372 px panel off the left edge, so the compositor slides it back on
    // screen (PopupAdjustment.Slide) — the arrow has to follow, not the window.
    readonly property real windowX: {
        const bar = popup.anchor.window;
        const screenW = bar ? bar.width : 0;
        return Math.max(0, Math.min(screenW - popup.width, triggerCenter - popup.width / 2));
    }

    // Arrow centre in window coordinates, kept off the rounded corners.
    readonly property real arrowCenter: Math.max(
        Theme.popoverRadius + arrowW / 2,
        Math.min(popup.width - Theme.popoverRadius - arrowW / 2, triggerCenter - windowX))

    Canvas {
        // Above the body, so the last pixel row covers the panel's top border.
        z: 1
        x: Math.round(popup.arrowCenter - width / 2)
        y: popup.gap
        width: popup.arrowW
        height: popup.arrowH + 1
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = popup.arrowW, h = popup.arrowH;
            // Fill the notch, one pixel past the panel edge so the border under it goes.
            ctx.beginPath();
            ctx.moveTo(0, h + 1);
            ctx.lineTo(w / 2, 0);
            ctx.lineTo(w, h + 1);
            ctx.closePath();
            ctx.fillStyle = Theme.mantle;
            ctx.fill();
            // Then stroke only the two slanted sides, continuing the panel's border.
            ctx.beginPath();
            ctx.moveTo(0.5, h + 1);
            ctx.lineTo(w / 2, 0.5);
            ctx.lineTo(w - 0.5, h + 1);
            ctx.lineWidth = 1;
            ctx.strokeStyle = Theme.surface;
            ctx.stroke();
        }
    }
}
