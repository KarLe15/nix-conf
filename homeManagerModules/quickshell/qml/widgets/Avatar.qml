import QtQuick
import "root:/"

// The bar's avatar trigger (Screen Bars · code screen, far left). The disc and its
// presence ring are AvatarDisc; this adds the click that drops the control centre
// (Avatar Widget · 9b) and nothing else — the ring stays the only indicator, so the
// widget costs the bar the same width in every state.
Item {
    id: root
    implicitHeight: disc.implicitHeight
    implicitWidth: disc.implicitWidth

    AvatarDisc {
        id: disc
        anchors.fill: parent
        highlighted: avatarMouse.containsMouse
    }

    MouseArea {
        id: avatarMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Popovers.toggle(panel)
    }

    AvatarPanel {
        id: panel
        anchorItem: root
    }
}
