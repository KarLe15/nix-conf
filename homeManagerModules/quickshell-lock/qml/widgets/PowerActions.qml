import QtQuick
import Quickshell.Io
import "../Config"

// What the lock lets you do without unlocking. The greeter's version asks SDDM
// what it is allowed to do; here the preset decides, and it lists suspend only by
// default — a lock screen that powers the machine off is a footgun for anyone
// walking past it.
//
// Commands match the powermanagement preset (configurations/software/
// powermanagement/presets/systemD.nix); logind does the privilege check.
Row {
    id: root

    spacing: 5

    readonly property var actions: ({
        "suspend":  { "glyph": Config.icons.suspend, "tip": "Veille",      "cmd": "suspend"  },
        "reboot":   { "glyph": Config.icons.reboot,  "tip": "Redémarrer",  "cmd": "reboot"   },
        "poweroff": { "glyph": Config.icons.power,   "tip": "Éteindre",    "cmd": "poweroff" }
    })

    Process { id: runner }

    Repeater {
        model: Config.lock.powerActions

        BarButton {
            readonly property var spec: root.actions[modelData]

            glyph: spec ? spec.glyph : ""
            tip: spec ? spec.tip : ""
            fg: modelData === "poweroff" ? Theme.maroon : Theme.subtext0
            hoverFg: modelData === "poweroff" ? Theme.maroon : Theme.fg
            hoverBg: modelData === "poweroff"
                     ? Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
                     : Theme.surface0

            onActivated: {
                runner.command = [ "systemctl", spec.cmd ]
                runner.running = true
            }
        }
    }
}
