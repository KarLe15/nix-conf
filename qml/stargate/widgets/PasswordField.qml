import QtQuick
import "../Config"

// The gate address: a password field sunk into the well. Plain TextInput rather
// than a Controls TextField so the theme needs no QtQuick.Controls style — see
// the module README on why the greeter avoids extra QML plugins.
Item {
    id: root

    property alias text: input.text
    property string placeholder: "Mot de passe"
    property color ringColor: Theme.surface1
    property color glowColor: "transparent"
    property color accent: Theme.peach

    signal submitted()
    signal cancelled()

    function take() {
        input.forceActiveFocus()
    }

    width: 340
    height: 56

    // The field's halo, standing in for the design's spread shadow.
    Rectangle {
        anchors.centerIn: parent
        width: parent.width + 8
        height: parent.height + 8
        radius: 18
        color: root.glowColor

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: 14
        color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.88)
        border.width: 1
        border.color: root.ringColor

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        Glyph {
            id: lock
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: Config.icons.lock
            font.pixelSize: 20
            color: Theme.dim
        }

        TextInput {
            id: input
            anchors.left: lock.right
            anchors.leftMargin: 10
            anchors.right: submit.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            echoMode: TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: 0
            selectByMouse: true
            clip: true

            font.family: Theme.fontMono
            font.pixelSize: 18
            font.weight: Font.DemiBold
            font.letterSpacing: 3
            color: Theme.fg
            selectionColor: root.accent
            selectedTextColor: Theme.onAccent

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.submitted()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.cancelled()
                    event.accepted = true
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                visible: input.text.length === 0
                text: root.placeholder
                font.family: Theme.fontMono
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: Theme.dim
            }
        }

        // Locking the seventh chevron, i.e. submitting.
        Rectangle {
            id: submit
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
            radius: 11
            color: root.accent

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Glyph {
                anchors.centerIn: parent
                text: Config.icons.submit
                font.pixelSize: 21
                color: Theme.onAccent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.submitted()
            }
        }
    }
}
