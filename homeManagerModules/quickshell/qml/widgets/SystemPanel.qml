import QtQuick
import Quickshell
import "root:/"

// Drop-down system panel, anchored under the system pill. Like the calendar, the
// PopupWindow positioning needs the live compositor; the SystemPanelView body is
// validated headlessly.
PopupWindow {
    id: popup
    property Item anchorItem
    property var info

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight
    color: "transparent"
    visible: false

    SystemPanelView {
        id: view
        info: popup.info
    }
}
