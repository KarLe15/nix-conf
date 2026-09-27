import QtQuick
import "../Config"

// The bar every screen carries: a floating panel inset from the top corners,
// with three zones. Each zone is a Component so the gate and the ambience
// screens can fill them differently without a shared layout model.
Rectangle {
    id: root

    property Component leftContent
    property Component centerContent
    property Component rightContent
    property real hPadding: 12

    height: Theme.barHeight
    radius: Theme.barRadius
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    Loader {
        sourceComponent: root.leftContent
        anchors.left: parent.left
        anchors.leftMargin: root.hPadding
        anchors.verticalCenter: parent.verticalCenter
    }

    Loader {
        sourceComponent: root.centerContent
        anchors.centerIn: parent
    }

    Loader {
        sourceComponent: root.rightContent
        anchors.right: parent.right
        anchors.rightMargin: root.hPadding
        anchors.verticalCenter: parent.verticalCenter
    }
}
