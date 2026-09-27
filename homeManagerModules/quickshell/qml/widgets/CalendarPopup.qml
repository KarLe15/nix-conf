import QtQuick

// Drop-down calendar popover under the clock trigger. Popover carries the anchor,
// the gap and the arrow; PopupWindow needs a live Wayland surface, so this can only
// be exercised on the real desktop — the CalendarView body is validated headlessly.
Popover {
    id: popup
    body: view

    CalendarView { id: view }
}
