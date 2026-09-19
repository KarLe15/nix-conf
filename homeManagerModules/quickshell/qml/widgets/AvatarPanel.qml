import QtQuick
import Quickshell
import "root:/"

// Drop-down control centre, anchored under the bar avatar (Avatar Widget · 9b).
// Like the other popovers, the PopupWindow positioning needs the live compositor;
// AvatarPanelView carries the whole body and is validated headlessly.
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
    visible: Popovers.active === popup

    AvatarPanelView {
        id: view
        // Lets the body scan for wifi only while it is on screen.
        open: popup.visible
    }
}
