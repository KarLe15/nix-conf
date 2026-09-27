import QtQuick

// Drop-down system panel under the system pill. Popover carries the anchor, the gap
// and the arrow; like the calendar, the PopupWindow positioning needs the live
// compositor, while the SystemPanelView body is validated headlessly.
Popover {
    id: popup
    property var info

    body: view

    SystemPanelView {
        id: view
        info: popup.info
    }
}
