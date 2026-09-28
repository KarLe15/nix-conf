pragma Singleton
import QtQuick
import Quickshell
import "root:/"

// What is on screen, and what is waiting (Notifications · 4a — "max 3 visible ·
// rest queue").
//
// `shown` is a ListModel rather than a JS array, and that is load-bearing. A
// Repeater over an array rebuilds every delegate whenever the array is reassigned,
// so each arrival destroyed and recreated the cards already on screen — every
// countdown restarted from full and the whole stack ran in lockstep, then blinked
// and restarted again each time one expired. A ListModel changes incrementally, so
// inserting or removing one card leaves the others, and their timers, untouched.
//
// The server's own `trackedNotifications` is the full set and keeps growing; this is
// only the presentation queue in front of it. Dropping a toast takes it off screen
// and lets the next one up — it does not close the notification, which stays tracked
// for the centre and the history.
Singleton {
    id: mgr

    // Newest first, capped at Config.maxVisible.
    readonly property ListModel shown: ListModel { dynamicRoles: true }
    // Everything that arrived while the stack was full, oldest first.
    property var queue: []

    function add(n) {
        if (shown.count < Config.maxVisible) shown.insert(0, { notif: n });
        else queue = queue.concat([n]);
    }

    function remove(n) {
        for (let i = 0; i < shown.count; i++) {
            if (shown.get(i).notif === n) {
                shown.remove(i);
                if (queue.length > 0) {
                    // Promoted to the bottom: newest stays on top.
                    shown.append({ notif: queue[0] });
                    queue = queue.slice(1);
                }
                return;
            }
        }

        // Never shown — drop it from the queue instead.
        const q = queue.indexOf(n);
        if (q !== -1) { const a = queue.slice(); a.splice(q, 1); queue = a; }
    }

    function clear() { shown.clear(); queue = []; }
}
