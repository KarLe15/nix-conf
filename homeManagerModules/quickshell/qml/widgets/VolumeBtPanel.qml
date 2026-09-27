import QtQuick

// Drop-down audio + Bluetooth control popover under the volume pill. Popover carries
// the anchor, the gap and the arrow; the PopupWindow needs the live compositor, while
// VolumeBtPanelView is validated headlessly.
Popover {
    id: popup
    property var hub

    body: view

    VolumeBtPanelView {
        id: view
        hub: popup.hub
    }
}
