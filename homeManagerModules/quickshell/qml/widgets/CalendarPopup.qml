import QtQuick
import Quickshell
import "root:/"

// Drop-down calendar popover, anchored just under the clock trigger. PopupWindow
// needs a live Wayland layer-shell surface, so this can only be exercised on the
// real desktop — the CalendarView body inside it is validated headlessly.
PopupWindow {
    id: popup
    property Item anchorItem

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight
    color: "transparent"
    visible: false

    CalendarView { id: view }
}
