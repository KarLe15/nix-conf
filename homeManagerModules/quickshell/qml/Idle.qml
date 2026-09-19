pragma Singleton
import QtQuick
import Quickshell
import "root:/"

// Idle-inhibitor state for the avatar popover (Avatar Widget · 9b). The wayland
// object that actually holds the machine awake needs a visible window, so it lives
// on the bars (see Bar.qml); this singleton owns the decision and the countdown so
// every surface — popover, mirror pill — reads one state.
//
// Inhibiting goes through the compositor (zwp_idle_inhibit): Hyprland stops emitting
// idle notifications, so hypridle's lock / dpms / suspend timers never fire. Nothing
// here stops the hypridle service — when the inhibitor drops, its schedule resumes
// untouched.
Singleton {
    id: idle

    property bool enabled: false
    // Selected hold, in minutes; 0 means indefinite.
    property int minutes: Config.avatar.idleDefault
    // Seconds left on a timed hold; 0 while indefinite or off.
    property int remaining: 0

    // Chip row in the popover, in order (minutes; 0 = indefinite).
    readonly property var durations: Config.avatar.idleDurations

    function durationLabel(m) {
        return m === 0 ? "∞" : (m >= 60 ? (m / 60) + "h" : m + "m");
    }

    readonly property string remainingLabel: {
        const m = Math.ceil(idle.remaining / 60);
        if (m >= 60) {
            const h = Math.floor(m / 60);
            const r = m % 60;
            return r > 0 ? h + "h " + r + "m" : h + "h";
        }
        return Math.max(m, 1) + "m";
    }

    // When the machine would sleep on its own — hypridle's lock timeout, read from
    // the same preset the hypridle module renders.
    readonly property string scheduleLabel: {
        const s = Config.avatar.idleAfter;
        return s >= 3600 ? Math.round(s / 3600) + "h" : Math.round(s / 60) + "m";
    }

    // Subtitle under "Keep awake".
    readonly property string sub:
          !idle.enabled      ? "sleeps after " + idle.scheduleLabel
        : idle.minutes === 0 ? "awake · indefinitely"
        : "awake · " + idle.remainingLabel + " left"

    function toggle() {
        if (idle.enabled) idle.enabled = false;
        else idle.hold(idle.minutes);
    }

    // Turn the inhibitor on for `m` minutes (0 = until turned off).
    function hold(m) {
        idle.minutes = m;
        idle.remaining = m * 60;
        idle.enabled = true;
    }

    // A timed hold expires on its own; an indefinite one never does.
    Timer {
        interval: 1000
        repeat: true
        running: idle.enabled && idle.minutes > 0
        onTriggered: {
            idle.remaining--;
            if (idle.remaining <= 0) idle.enabled = false;
        }
    }
}
