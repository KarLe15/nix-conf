import QtQuick

// Drop-down control centre under the bar avatar (Avatar Widget · 9b). Popover carries
// the anchor, the gap and the arrow; the PopupWindow positioning needs the live
// compositor, while AvatarPanelView holds the whole body and is validated headlessly.
Popover {
    id: popup
    body: view

    AvatarPanelView {
        id: view
        // Lets the body scan for wifi only while it is on screen.
        open: popup.visible
    }
}
