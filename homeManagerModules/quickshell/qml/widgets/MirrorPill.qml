import QtQuick
import "root:/"

// Read-only echo of avatar-popover state, for the hub bar (Avatar Widget · 9b's
// state, seen from the other screen). Three kinds:
//   presence       the ring colour + its glyph — Available / Focus / DND
//   idle           coffee while a keep-awake hold is on, moon otherwise
//   notifications  swaync's held count; hidden at zero
//
// Deliberately inert: no MouseArea, no cursor change. The popover is the only place
// any of this changes, so these can never disagree with it or with the daemon.
Rectangle {
    id: root

    // "presence" | "idle" | "notifications"
    property string kind: "presence"

    readonly property bool enabledInPreset: Config.avatar.mirrors[kind] === true
    readonly property bool lit:
          kind === "idle"          ? Idle.enabled
        : kind === "notifications" ? Presence.count > 0
        : Presence.state !== "available"

    readonly property string glyph:
          kind === "idle"          ? (Idle.enabled ? Config.avatar.icons.awake
                                                   : Config.avatar.icons.asleep)
        : kind === "notifications" ? Config.avatar.icons.bell
        : Config.avatar.icons[Presence.state]

    readonly property string label:
          kind === "idle"          ? (Idle.enabled && Idle.minutes > 0 ? Idle.remainingLabel : "")
        : kind === "notifications" ? String(Presence.count)
        : ""

    readonly property color tone:
          kind === "idle"          ? Theme.teal
        : kind === "notifications" ? Theme.rosewater
        : Presence.ringColor

    // The notification pill has nothing to say at zero; the other two always do.
    visible: enabledInPreset && (kind !== "notifications" || Presence.count > 0)

    implicitHeight: Theme.pillHeight
    implicitWidth: content.implicitWidth + 20
    radius: Theme.pillRadius
    color: lit ? tone : Theme.surface

    Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 6
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: root.lit ? Theme.onAccent : Theme.overlay1
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            text: root.label
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: root.lit ? Theme.onAccent : Theme.overlay1
        }
    }
}
