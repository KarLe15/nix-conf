import QtQuick
import "../Config"
import "paint.js" as Paint

// Who is about to log in. With more than one account on the machine the disc
// cycles through them — the greeter has no room for a user list and this host
// has exactly one real user.
Row {
    id: root

    property string userName: ""
    property string realName: ""
    property string host: ""
    property bool cyclable: false

    signal cycle()

    spacing: 14

    Rectangle {
        width: 50
        height: 50
        radius: 25
        color: Theme.surface0
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: Paint.initials(root.realName.length > 0 ? root.realName : root.userName)
            font.family: Theme.fontUi
            font.pixelSize: 17
            font.weight: Font.DemiBold
            color: Theme.lavender
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.cyclable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycle()
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            text: root.realName.length > 0 ? root.realName : root.userName
            font.family: Theme.fontUi
            font.pixelSize: 19
            font.weight: Font.DemiBold
            color: Theme.fg
        }

        Text {
            text: root.userName + "@" + root.host
            font.family: Theme.fontMono
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.dim
        }
    }
}
