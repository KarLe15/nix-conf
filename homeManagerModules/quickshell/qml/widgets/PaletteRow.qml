import QtQuick
import "root:/"

// One palette row (design "App Launcher" · row anatomy: icon tile · title ·
// subtitle · right-side keybind hint). Deliberately mode-agnostic: it takes
// strings, so Apps / Clipboard / Emoji / Pass all reuse it unchanged.
Rectangle {
    id: root

    property string tile: ""          // initials, used when no themed icon resolves
    property string iconSource: ""    // resolved icon path, "" to fall back to `tile`
    property string title: ""
    property string subtitle: ""
    property string hint: ""          // right-hand keybind chip, "" for none
    property bool   selected: false
    property color  accent: Theme.mauve
    property string selectionStyle: "fill"

    signal activated()

    // Design offers four selection treatments; the accent drives all of them.
    readonly property color selBg:
          !selected                     ? (hover.hovered ? Theme.surface0 : "transparent")
        : selectionStyle === "outline"  ? "transparent"
        : selectionStyle === "fill"     ? Qt.rgba(accent.r, accent.g, accent.b, 0.20)
        : /* tint | bar */                Qt.rgba(accent.r, accent.g, accent.b, 0.13)

    implicitHeight: 58
    radius: 12
    color: selBg
    border.width: selected && selectionStyle === "outline" ? 2 : 0
    border.color: accent

    // "bar" draws a left edge rather than a border
    Rectangle {
        visible: root.selected && root.selectionStyle === "bar"
        width: 3
        radius: 2
        color: root.accent
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 4 }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 13

        // The design specifies placeholder initials tiles ("real glyphs TBD").
        // Themed icons resolve for most entries; the tile remains the fallback.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40
            radius: 10
            color: icon.visible ? "transparent" : Theme.surface0

            Image {
                id: icon
                anchors.centerIn: parent
                width: 32; height: 32
                source: root.iconSource
                visible: root.iconSource !== "" && status === Image.Ready
                sourceSize.width: 64
                sourceSize.height: 64
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                asynchronous: true
            }

            Text {
                anchors.centerIn: parent
                visible: !icon.visible
                text: root.tile
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.bold: true
                color: root.selected ? Theme.fg : Theme.subtext1
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 53 - (chip.visible ? chip.width + 13 : 0)
            spacing: 2
            Text {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                font.family: Theme.fontUi
                font.pixelSize: 15
                font.bold: true
                color: Theme.fg
            }
            Text {
                width: parent.width
                text: root.subtitle
                elide: Text.ElideRight
                visible: root.subtitle !== ""
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.overlay1
            }
        }
    }

    Rectangle {
        id: chip
        visible: root.hint !== ""
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 12
        implicitWidth: hintText.implicitWidth + 16
        implicitHeight: hintText.implicitHeight + 10
        radius: 7
        color: root.selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.14)
                             : "transparent"
        border.width: 1
        border.color: root.selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.45)
                                    : Theme.surface0
        Text {
            id: hintText
            anchors.centerIn: parent
            text: root.hint
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.bold: true
            color: root.selected ? root.accent : Theme.overlay0
        }
    }
}
