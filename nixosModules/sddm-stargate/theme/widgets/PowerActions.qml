import QtQuick
import "../Config"

// Suspend / reboot / power off. Each button follows the matching `can*` property
// on the SDDM proxy rather than assuming the greeter is allowed to do it.
Row {
    spacing: 5

    BarButton {
        glyph: Config.icons.suspend
        tip: "Veille"
        enabled: sddm.canSuspend
        onActivated: sddm.suspend()
    }

    BarButton {
        glyph: Config.icons.reboot
        tip: "Redémarrer"
        enabled: sddm.canReboot
        onActivated: sddm.reboot()
    }

    BarButton {
        glyph: Config.icons.power
        tip: "Éteindre"
        fg: Theme.maroon
        hoverBg: Qt.rgba(Theme.red.r, Theme.red.g, Theme.red.b, 0.15)
        hoverFg: Theme.maroon
        enabled: sddm.canPowerOff
        onActivated: sddm.powerOff()
    }
}
