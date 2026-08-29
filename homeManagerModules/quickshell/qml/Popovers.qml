pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Coordinates the bar's drop-down popovers (calendar, system, volume/bluetooth).
// Two behaviours the raw PopupWindows lack:
//   * one-open-at-a-time — each popup binds `visible: Popovers.active === <self>`,
//     so opening one closes any other automatically;
//   * click-outside dismiss — a Hyprland focus grab over the open popover *and*
//     every bar closes it when the user clicks anything else, on any monitor.
Singleton {
    id: mgr

    // The currently-open popup wrapper (a PopupWindow), or null when none is open.
    property var active: null

    // Every Bar registers its PanelWindow here. Including the bars in the grab means
    // clicking another chip is *not* an outside-click: it reaches that chip and
    // swaps the popover in one click, instead of the grab eating the first click.
    property var bars: []

    function toggle(p) { active = (active === p) ? null : p; }
    function open(p)   { active = p; }
    function close(p)  { if (active === p) active = null; }
    function closeAll() { active = null; }

    function registerBar(w) {
        if (bars.indexOf(w) === -1) bars = bars.concat([w]);
    }
    function unregisterBar(w) {
        const i = bars.indexOf(w);
        if (i !== -1) { const a = bars.slice(); a.splice(i, 1); bars = a; }
    }

    // Grab focus over the open popover + all bars; clicking anything else clears it.
    HyprlandFocusGrab {
        active: mgr.active !== null
        windows: mgr.active ? [mgr.active].concat(mgr.bars) : []
        onCleared: mgr.closeAll()
    }
}
