import QtQuick
import QtQuick.Effects
import "root:/"

// The avatar disc itself: the profile photo masked into a circle, ringed in the
// current presence colour (Avatar Widget · 9a). Pure presentation — the bar's
// clickable trigger is Avatar, which wraps this; the popover's identity row uses
// this directly at 52 px. Keeping the two apart is what stops the popover from
// nesting another popover inside itself.
//
// Image path comes from Config (installed alongside the QML tree); a gradient +
// user glyph stands in when the photo is missing.
Item {
    id: root

    // Disc diameter; the bar uses a pill-height disc, the popover a larger one.
    property int size: Theme.pillHeight
    // Ring thickness, then a gap of background between ring and photo — the design's
    // double `box-shadow`, scaled up from its 18 px disc.
    property int ringWidth: Config.avatar.ringWidth
    property int ringGap: Config.avatar.ringGap
    // Dimmed while the bar trigger is hovered.
    property bool highlighted: false

    readonly property int inset: ringWidth + ringGap
    readonly property bool hasPhoto: img.status === Image.Ready

    implicitHeight: size
    implicitWidth: size

    // Fallback disc (shown until/unless the photo loads).
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.inset
        radius: width / 2
        visible: !root.hasPhoto
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.lavender }
            GradientStop { position: 1.0; color: Theme.sapphire }
        }
        Text {
            anchors.centerIn: parent
            text: Config.avatar.icons.user
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    // Source photo (hidden; drawn through the mask below).
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: root.inset
        source: Config.profileImage
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
        cache: true
        visible: false
    }

    // Circular mask texture.
    Item {
        id: mask
        anchors.fill: img
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            antialiasing: true
            color: "black"
        }
    }

    MultiEffect {
        anchors.fill: img
        source: img
        visible: root.hasPhoto
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    // Presence ring on top: green available, yellow focus, red DND.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: Presence.ringColor
        border.width: root.ringWidth
        antialiasing: true
        opacity: root.highlighted ? 0.75 : 1.0

        Behavior on border.color {
            ColorAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }
}
