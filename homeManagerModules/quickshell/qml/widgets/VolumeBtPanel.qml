import QtQuick
import Quickshell
import "root:/"

// Drop-down audio + Bluetooth control popover, anchored under the volume pill.
// PopupWindow needs the live compositor; VolumeBtPanelView is validated headlessly.
PopupWindow {
    id: popup
    property Item anchorItem
    property var hub

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight
    color: "transparent"
    visible: false

    VolumeBtPanelView {
        id: view
        hub: popup.hub
    }
}
