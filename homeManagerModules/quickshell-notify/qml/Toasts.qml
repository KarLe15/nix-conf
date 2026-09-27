pragma Singleton
import QtQuick
import Quickshell
import "root:/"

// What is on screen, and what is waiting (Notifications · 4a — "max 3 visible ·
// rest queue").
//
// The server's own `trackedNotifications` is the full set and keeps growing; this is
// only the presentation queue in front of it. Dismissing a toast takes it off screen
// and lets the next one up — it does not close the notification, which stays tracked
// for the centre and the history.
Singleton {
    id: mgr

    // Newest first, capped at Config.maxVisible.
    property var visible: []
    // Everything that arrived while the stack was full, oldest first.
    property var queue: []

    function add(n) {
        if (visible.length < Config.maxVisible) {
            visible = [n].concat(visible);
        } else {
            queue = queue.concat([n]);
        }
    }

    function remove(n) {
        const i = visible.indexOf(n);
        if (i === -1) {
            // Never shown — drop it from the queue instead.
            const q = queue.indexOf(n);
            if (q !== -1) { const a = queue.slice(); a.splice(q, 1); queue = a; }
            return;
        }

        const a = visible.slice();
        a.splice(i, 1);
        if (queue.length > 0) {
            const next = queue[0];
            queue = queue.slice(1);
            a.push(next);              // promoted to the bottom: newest stays on top
        }
        visible = a;
    }

    function clear() { visible = []; queue = []; }
}
