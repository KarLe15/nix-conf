import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "root:/"

// One toast card (Notifications · 4b). Two states:
//
//   collapsed  header (app tile · name · time · ✕) → title → body clamped to
//              Config.bodyLines → chevron ▾ → countdown
//   expanded   body unclamps, action buttons appear, chevron flips to ▴, and the
//              countdown freezes to a full-width grey bar
//
// Expansion is hover-driven, so the countdown pausing and the body unclamping are
// the same gesture — you slow a toast down by looking at it.
//
// Sizes are the mockup's own 1x values, not the bar-scaled Theme metrics, the same
// convention the bar's popover bodies follow: this renders in its own window.
Rectangle {
    id: root

    // The Quickshell Notification object this card is showing.
    required property var notif
    signal dismissed()

    // `urgency` is an enum, not a string — String(n.urgency) yields "2", which
    // matched nothing and left every card on the normal palette.
    readonly property string level:
          notif.urgency === NotificationUrgency.Critical ? "critical"
        : notif.urgency === NotificationUrgency.Low      ? "low"
        : "normal"
    // Urgent is one predicate used twice (D8): it bypasses DND *and* never expires.
    readonly property bool urgent: level === "critical"

    // How long this card holds, honouring what the application asked for. The value
    // is the raw freedesktop one in MILLISECONDS — Quickshell's doc comment says
    // seconds, but it assigns the D-Bus int straight through and `-t 15000` arrives
    // as 15000. Semantics: -1 defer to the server, 0 never expire, >0 milliseconds.
    readonly property int holdMs: notif.expireTimeout < 0 ? Config.holdMs
                                                          : notif.expireTimeout
    // Whether a countdown runs at all: urgent cards never expire (D8), and neither
    // does one the application explicitly asked to keep.
    readonly property bool expires: !urgent && holdMs > 0

    readonly property var  colors: Config.urgency[level] || Config.urgency.normal
    readonly property color accent:
        Theme[Config.accent] !== undefined ? Theme[Config.accent] : Theme.blue

    readonly property bool expanded: hover.hovered

    width: Config.width
    radius: Config.radius
    color: colors.bg
    border.color: colors.border
    border.width: 1
    clip: true
    implicitHeight: body.implicitHeight + 3      // + the countdown strip

    // Safe to animate again now the stack window is a fixed-size strip: the height
    // change no longer propagates into a layer-shell resize, so this stays inside
    // the client instead of costing a configure round-trip per frame.
    Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    // ---- countdown -------------------------------------------------------------
    // An explicit ticker rather than a NumberAnimation with `paused`: a property
    // value-source animation does not reliably hold when paused, and the card kept
    // expiring under the pointer. A timer that simply stops while hovered resumes
    // exactly where it left off, which is all "hover pauses countdown" needs.
    property real remaining: 1.0
    Timer {
        interval: 50
        repeat: true
        running: root.expires && !root.expanded && root.remaining > 0
        onTriggered: {
            root.remaining -= interval / Math.max(1, root.holdMs);
            if (root.remaining <= 0) {
                root.remaining = 0;
                root.dismissed();
            }
        }
    }

    // ---- body ------------------------------------------------------------------
    HoverHandler { id: hover }

    Column {
        id: body
        x: 14
        y: 12
        width: parent.width - 28
        spacing: 3
        bottomPadding: 12

        // header
        Item {
            width: parent.width
            height: 24

            Rectangle {
                id: tile
                width: 24; height: 24
                radius: 7
                color: Theme.surface0
                clip: true
                // The notification's own image (a sender's avatar, typically) wins
                // over the application icon; the initials are the last resort.
                Image {
                    anchors.fill: parent
                    source: root.tileSource
                    visible: root.tileSource !== ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 48
                    sourceSize.height: 48
                    asynchronous: true
                }
                Text {
                    anchors.centerIn: parent
                    text: root.initials
                    visible: root.tileSource === ""
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: root.accent
                }
            }
            Text {
                anchors.left: tile.right
                anchors.leftMargin: 9
                anchors.right: stamp.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.notif.appName || "Notification"
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Theme.subtext0
                textFormat: Text.PlainText
            }
            Text {
                id: stamp
                anchors.right: close.left
                anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                text: root.age
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: Theme.overlay0
            }
            Text {
                id: close
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "×"
                font.family: Theme.fontUi
                font.pixelSize: 15
                color: closeArea.containsMouse ? Theme.red : Theme.overlay0
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dismissed()
                }
            }
        }

        // title
        Text {
            id: summaryText
            width: parent.width
            text: root.notif.summary || ""
            font.family: Theme.fontUi
            font.pixelSize: 14
            font.weight: Font.Medium
            color: Theme.fg
            elide: Text.ElideRight
            // Unclamps too. A notification with only a summary and no body — which
            // is what a one-argument notify-send produces — otherwise had nothing
            // to expand and stayed elided however long you hovered it.
            maximumLineCount: root.expanded ? 8 : 2
            wrapMode: Text.WordWrap
            // Applications send Pango markup whether or not the server advertises
            // support for it, and Text parses markup by default — which would both
            // restyle the summary and silently swallow anything shaped like a tag.
            textFormat: Text.PlainText
            visible: text !== ""
            onTruncatedChanged: if (truncated) root.everTruncated = true
        }

        // body — clamped until hovered
        Text {
            id: bodyText
            width: parent.width
            text: root.notif.body || ""
            font.family: Theme.fontUi
            font.pixelSize: 13        // mockup says 12.5; pixelSize is an int
            lineHeight: 1.35
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: root.expanded ? 12 : Config.bodyLines
            textFormat: Text.PlainText
            visible: text !== ""
            onTruncatedChanged: if (truncated) root.everTruncated = true
        }

        // actions — only once expanded, so a collapsed card stays one glanceable shape
        Row {
            spacing: 8
            topPadding: 8
            visible: root.expanded && root.notif.actions.length > 0
            Repeater {
                model: root.expanded ? root.notif.actions : []
                Rectangle {
                    required property var modelData
                    // With action-icons the identifier IS an icon name and the label
                    // is meaningless; without it the identifier is the opaque key and
                    // the label is what to show. Falls back to the label if the named
                    // icon cannot be resolved, so a bad icon name is not a blank button.
                    readonly property string iconSource:
                        root.notif.hasActionIcons
                            ? Quickshell.iconPath(modelData.identifier, true)
                            : ""
                    readonly property bool asIcon: iconSource !== ""

                    radius: 9
                    color: actArea.containsMouse ? Theme.surface1 : Theme.surface0
                    implicitWidth: asIcon ? 34 : actLabel.implicitWidth + 26
                    implicitHeight: 28
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Image {
                        anchors.centerIn: parent
                        width: 16; height: 16
                        source: parent.iconSource
                        visible: parent.asIcon
                        sourceSize.width: 32
                        sourceSize.height: 32
                        asynchronous: true
                    }
                    Text {
                        id: actLabel
                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier
                        visible: !parent.asIcon
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        color: Theme.fg
                        textFormat: Text.PlainText
                    }
                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // Just invoke. Quickshell closes the notification itself unless
                        // it is `resident`, and the closed handler below takes the card
                        // off the stack — so a resident notification keeps its card,
                        // which is the whole point of the flag.
                        onClicked: modelData.invoke()
                    }
                }
            }
        }

        // expand affordance — given real room rather than sitting tight against
        // the body above it and the countdown below.
        Item {
            width: parent.width
            height: 22
            visible: root.hasMore
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: root.expanded ? "▴" : "▾"
                font.family: Theme.fontUi
                font.pixelSize: 11
                font.bold: true
                color: Theme.overlay0
            }
        }
    }

    // ---- countdown strip -------------------------------------------------------
    // Inset by the corner radius rather than spanning edge to edge as the mockup
    // does. The mockup is CSS, where `overflow:hidden` clips children to the border
    // radius; QML's `clip` only clips to the bounding *rectangle*, so a full-width
    // bar on the bottom row pokes out past the curve at both corners.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.radius
        anchors.rightMargin: root.radius
        anchors.bottomMargin: 2
        height: 3
        radius: height / 2
        color: Theme.surface0
        visible: root.expires
        Rectangle {
            height: parent.height
            radius: parent.radius
            // Frozen full-width grey while hovered (4b), so a paused countdown does
            // not read as a nearly-expired one.
            width: parent.width * (root.expanded ? 1.0 : Math.max(0, root.remaining))
            color: root.expanded ? Theme.surface2 : root.accent
            Behavior on color { ColorAnimation { duration: 130 } }
        }
    }

    // ---- derived ---------------------------------------------------------------
    // The notification closing — because the application withdrew it, or because
    // invoking a non-resident action closed it — takes the card with it. Without
    // this the card would sit there until its countdown, long after the thing it
    // refers to is gone.
    Connections {
        target: root.notif
        function onClosed(reason) { root.dismissed(); }
    }

    readonly property string tileSource: {
        const img = notif.image || "";
        if (img !== "") {
            // `image` is often an image://icon/<name> URL that Quickshell builds from
            // the image-path hint WITHOUT checking the name resolves — and the icon
            // provider answers an unresolvable name with a purple/black placeholder
            // rather than failing, so `Image.status` never reports an error. The name
            // has to be validated here or the tile renders that placeholder.
            const m = img.match(/^image:\/\/icon\/(.+)$/);
            if (!m) return img;                      // a real file:// or data URL
            return Quickshell.iconPath(m[1], true) === "" ? "" : img;
        }
        const ic = notif.appIcon || "";
        return ic === "" ? "" : Quickshell.iconPath(ic, true);
    }

    // Sticky: once either block has had to elide, the card is expandable and stays
    // marked so. Reading `truncated` directly would flip back to false the moment
    // expanding revealed the text, taking the chevron away exactly when it should
    // be pointing the other way.
    property bool everTruncated: false
    readonly property bool hasMore: everTruncated || notif.actions.length > 0

    readonly property string initials: {
        const a = (notif.appName || "?").trim();
        if (a.length === 0) return "?";
        return a.charAt(0).toUpperCase() + (a.length > 1 ? a.charAt(1).toLowerCase() : "");
    }

    // Relative age, recomputed by the stack's shared ticker rather than a timer per
    // card — three cards would otherwise carry three timers to render "now".
    property int nowTick: 0
    readonly property double bornAt: Date.now()
    readonly property string age: {
        nowTick;                                   // dependency, forces re-evaluation
        const s = Math.max(0, (Date.now() - bornAt) / 1000);
        if (s < 45)   return "now";
        if (s < 3600) return Math.round(s / 60) + "m";
        return Math.round(s / 3600) + "h";
    }
}
