pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "root:/"

// Presence state behind the avatar ring (Avatar Widget · 9a) and the browser bar's
// read-only mirror pills. swaync owns the silence itself — this singleton subscribes
// to `swaync-client -swb`, so a `swaync-client -d` typed in a terminal (or the
// centre's own toggle) is reflected here within the same event, and nothing here
// caches a state the daemon disagrees with.
//
// Three presences are exposed, but today Focus and DND both mean "swaync DND on":
// they differ in label and ring colour only. swaync cannot filter per application,
// so a Focus that "mutes chat & mail" would be a lie. Real Focus rules arrive with
// the Quickshell notification centre that replaces swaync.
//
// Focus does not survive a shell restart: swaync reports silenced/not-silenced and
// nothing finer, so a restart while silenced comes back as DND.
Singleton {
    id: presence

    // "available" | "focus" | "dnd"
    property string state: "available"
    // Notifications held in the centre.
    property int count: 0
    // Whether swaync is actually silenced right now (the daemon's own view).
    property bool silenced: false

    readonly property string label:
          state === "dnd"   ? "DND"
        : state === "focus" ? "Focus"
        : "Available"
    // Ring + chip colour. The preset names a Theme palette entry per state, so a
    // theme flavor change carries over without touching this file.
    readonly property color ringColor: Theme[Config.avatar.presence[state]] || Theme.green

    // Request a presence. The daemon call is fire-and-forget; the subscription below
    // is what actually moves `silenced`, so an ignored/failed call self-corrects.
    function set(s) {
        if (s !== "available" && s !== "focus" && s !== "dnd") return;
        presence.state = s;
        Quickshell.execDetached(["swaync-client", s === "available" ? "-df" : "-dn"]);
    }

    // ---- Live state from swaync ----
    // The waybar subscription emits once on connect (current state) and then on every
    // add/close/dnd change: {"text":"3","alt":"dnd-notification",...}.
    Process {
        id: sub
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser { onRead: data => presence._parse(data) }
        onExited: reconnect.start()
    }

    // swaync restarts (or starts late) drop the subscription; pick it back up.
    Timer {
        id: reconnect
        interval: 2000
        repeat: false
        onTriggered: sub.running = true
    }

    function _parse(line) {
        let o;
        try { o = JSON.parse(line); } catch (e) { return; }
        const alt = String(o.alt || "");
        const dnd = alt.indexOf("dnd") === 0;
        presence.count = parseInt(o.text) || 0;
        presence.silenced = dnd;
        // The daemon wins: un-silenced is always Available, and a silence we didn't
        // ask for (external toggle) reads as DND rather than claiming Focus.
        if (!dnd) presence.state = "available";
        else if (presence.state === "available") presence.state = "dnd";
    }
}
