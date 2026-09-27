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
          kind === "idle"          ? Idle.pillLabel
        : kind === "notifications" ? String(Presence.count)
        : ""

    readonly property color tone:
          kind === "idle"          ? Theme.teal
        : kind === "notifications" ? Theme.rosewater
        : Presence.ringColor

    // The pill reserves the widest glyph and the widest value it can ever show, so
    // it keeps one width and the glyph never shifts: the idle countdown re-renders
    // every minute and the notification count changes under you, and neither should
    // push the rest of the bar around. Idle always has a word to show (see
    // Idle.pillLabel), so its slot is never empty either.
    readonly property var glyphSet:
          kind === "idle"          ? [ Config.avatar.icons.awake, Config.avatar.icons.asleep ]
        : kind === "notifications" ? [ Config.avatar.icons.bell ]
        : [ Config.avatar.icons.available, Config.avatar.icons.focus, Config.avatar.icons.dnd ]

    // Two digits covers any plausible held count; past that the slot just grows.
    readonly property var labelSet:
          kind === "idle"          ? Idle.pillLabels
        : kind === "notifications" ? [ "99" ]
        : []

    TextSlot { id: glyphSlot; candidates: root.glyphSet; pixelSize: Theme.fontIcon }
    TextSlot { id: labelSlot; candidates: root.labelSet; bold: true }

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
            width: Math.max(glyphSlot.widest, implicitWidth)
            horizontalAlignment: Text.AlignHCenter
            text: root.glyph
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: root.lit ? Theme.onAccent : Theme.overlay1
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Per kind, not per value: presence has nothing to put here, and the
            // notification count keeps its slot open between the zeroes it hides at.
            visible: root.labelSet.length > 0
            width: Math.max(labelSlot.widest, implicitWidth)
            horizontalAlignment: Text.AlignHCenter
            text: root.label
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontNormal
            font.bold: true
            color: root.lit ? Theme.onAccent : Theme.overlay1
        }
    }
}
