import QtQuick
import QtQuick.Effects
import "root:/"

// User-identity avatar (Screen Bars · code screen, far left): the profile photo
// masked into a disc with a lavender ring. Image path comes from Config (installed
// alongside the QML tree). Falls back to a gradient + user glyph if the photo is
// missing.
Item {
    id: root
    implicitHeight: Theme.pillHeight
    implicitWidth: Theme.pillHeight

    readonly property bool hasPhoto: img.status === Image.Ready

    // Fallback disc (shown until/unless the photo loads).
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: width / 2
        visible: !root.hasPhoto
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.lavender }
            GradientStop { position: 1.0; color: Theme.sapphire }
        }
        Text {
            anchors.centerIn: parent
            text: "\uf007"  // nf-fa-user
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontIcon
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }

    // Source photo (hidden; drawn through the mask below).
    Image {
        id: img
        anchors.fill: parent
        anchors.margins: 2
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

    // Lavender ring on top.
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.color: Theme.lavender
        border.width: 2
        antialiasing: true
    }
}
