import QtQuick
import "../Config"

// "Destination" — the session the login will start, straight off SDDM's
// sessionModel. The index is what gets handed to sddm.login().
//
// A Flow rather than an even split: a host can expose half a dozen sessions with
// names like "Hyprland (uwsm-managed)", and squeezing those into equal columns
// makes every one of them unreadable.
Rectangle {
    id: root

    property int currentIndex: 0
    property color accent: Theme.peach

    signal picked(int index)

    // What a name may occupy before it is elided: the row's width less the pill's
    // own padding, the glyph and the gap. Constant, so pill widths can depend on
    // it without a loop.
    readonly property real nameLimit: width - 8 - 24 - 17 - 8

    height: flow.height + 8
    radius: 13
    color: Theme.panel
    border.width: 1
    border.color: Theme.border

    Flow {
        id: flow
        x: 4
        y: 4
        width: root.width - 8
        spacing: 4

        Repeater {
            model: sessionModel

            Rectangle {
                id: pill

                readonly property bool selected: index === root.currentIndex
                readonly property string sessionName: model.name

                width: mark.implicitWidth + content.spacing + label.width + 24
                height: 40
                radius: 10
                color: selected ? root.accent : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 8

                    Glyph {
                        id: mark
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.sessionIcons[pill.sessionName.toLowerCase()]
                              || Config.sessionIcons["default"]
                        font.pixelSize: 17
                        color: pill.selected ? Theme.onAccent : Theme.label
                    }

                    Text {
                        id: label
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, root.nameLimit)
                        text: pill.sessionName
                        elide: Text.ElideRight
                        font.family: Theme.fontUi
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: pill.selected ? Theme.onAccent : Theme.label
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(index)
                }
            }
        }
    }
}
