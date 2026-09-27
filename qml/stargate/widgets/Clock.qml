import QtQuick
import "../Config"

// One ticking clock per screen, non-visual. Formatting goes through
// Theme.locale explicitly: the greeter runs as the `sddm` user and inherits
// neither the host's LANG nor its LC_TIME, so Qt's default locale would render
// the date in English.
QtObject {
    id: root

    property date now: new Date()

    readonly property var loc: Qt.locale(Theme.locale)

    readonly property string time:
        Qt.formatDateTime(now, Config.clock24 ? "HH:mm" : "h:mm AP")

    readonly property string timeSec:
        Qt.formatDateTime(now, Config.clock24 ? "HH:mm:ss" : "h:mm:ss AP")

    // "Mercredi 27 septembre" — the locale hands it over lowercase.
    readonly property string dateLong: {
        const s = now.toLocaleDateString(loc, "dddd d MMMM")
        return s.length > 0 ? s.charAt(0).toUpperCase() + s.substring(1) : s
    }

    property Timer ticker: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
