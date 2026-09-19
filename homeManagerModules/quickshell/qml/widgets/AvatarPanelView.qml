import QtQuick
import Quickshell
import Quickshell.Networking
import "root:/"

// The avatar control-center body (Avatar Widget · 9b): identity, presence, the idle
// inhibitor, the network block (variant 10b — interfaces as peers, a check on
// whichever carries the default route) and the neofetch facts. Session actions
// (lock / reboot / power) deliberately live elsewhere.
//
// Split from AvatarPanel so this body can be instantiated headlessly — PopupWindow
// needs the live compositor, a Rectangle does not.
Rectangle {
    id: root

    // True while the popover is open. Drives the wifi scanner: NetworkManager only
    // reports the connected AP until someone asks it to scan, so the SSID list is
    // empty unless we turn the scanner on — and leaving it on would keep the radio
    // busy for a panel nobody is looking at.
    property bool open: false

    readonly property int inner: Config.avatar.width - 32

    color: Theme.mantle
    border.color: Theme.surface
    border.width: 1
    radius: 16
    implicitWidth: inner + 32
    implicitHeight: layout.implicitHeight + 32

    // ---- Identity ----
    readonly property string login: Quickshell.env("USER") || "user"
    // The preset can name you; otherwise $USER, capitalised.
    readonly property string displayName: Config.avatar.userName !== ""
        ? Config.avatar.userName
        : login.charAt(0).toUpperCase() + login.slice(1)

    // ---- Network (Quickshell.Networking → NetworkManager) ----
    readonly property var devices: Networking.devices.values
    readonly property var wired: {
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wired) return devices[i];
        return null;
    }
    readonly property var wifiDev: {
        for (let i = 0; i < devices.length; i++)
            if (devices[i].type === DeviceType.Wifi) return devices[i];
        return null;
    }
    readonly property bool wiredUp: wired !== null && wired.hasLink && wired.connected
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var wifiNets: wifiDev ? wifiDev.networks.values : []
    readonly property var activeNet: {
        for (let i = 0; i < wifiNets.length; i++)
            if (wifiNets[i].connected) return wifiNets[i];
        return null;
    }
    // The default route: wired wins when the cable is live, which is how NM's metrics
    // order them. Nothing in the API reports the route itself.
    readonly property string defaultVia:
          wiredUp                                    ? wired.name
        : (wifiDev && wifiDev.connected && wifiOn)   ? wifiDev.name
        : "—"

    property bool listOpen: false

    // Connected first, then saved, then strongest.
    readonly property var sortedNets: {
        const a = wifiNets.slice();
        a.sort(function (x, y) {
            return (y.connected - x.connected)
                || (y.known - x.known)
                || (y.signalStrength - x.signalStrength);
        });
        return a;
    }

    function secured(n) {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
    }
    function pct(n) { return Math.round(n.signalStrength * 100); }
    function ip(dev) { return dev && Sys.ipv4[dev.name] ? Sys.ipv4[dev.name] : ""; }

    // Scan only while the popover is open; the binding restores false on close.
    Binding {
        target: root.wifiDev
        property: "scannerEnabled"
        value: root.open && root.wifiOn
        when: root.wifiDev !== null
    }

    // Collapse the SSID list when the popover closes, so it reopens compact.
    onOpenChanged: if (!open) listOpen = false

    // ---- Shared building blocks ----
    component SectionLabel: Text {
        font.family: Theme.fontMono
        font.pixelSize: 11
        font.bold: true
        color: Theme.overlay1
    }

    component Fact: Row {
        property string key: ""
        property string value: ""
        spacing: 10
        Text {
            width: 58
            text: key
            font.family: Theme.fontMono
            font.pixelSize: 10
            font.bold: true
            color: Theme.overlay0
        }
        Text {
            text: value
            font.family: Theme.fontMono
            font.pixelSize: 12
            font.bold: true
            color: Theme.subtext1
        }
    }

    component ToggleSwitch: Rectangle {
        property bool on: false
        signal toggled()
        width: 38
        height: 22
        radius: 11
        color: on ? Theme.blue : Theme.surface
        Rectangle {
            y: 2
            x: parent.on ? 18 : 2
            width: 18
            height: 18
            radius: 9
            color: "#eff1f5"
            Behavior on x { NumberAnimation { duration: 120 } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.toggled()
        }
    }

    Column {
        id: layout
        x: 16
        y: 16
        width: root.inner
        spacing: 12

        // ===== IDENTITY =====
        Item {
            width: parent.width
            height: 52
            AvatarDisc {
                id: bigAvatar
                size: Config.avatar.discSize
                ringWidth: Config.avatar.panelRingWidth
                anchors.verticalCenter: parent.verticalCenter
            }
            Column {
                anchors.left: bigAvatar.right
                anchors.leftMargin: 13
                anchors.right: chip.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.displayName
                    font.family: Theme.fontUi
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.login + "@" + (Sys.host || "…")
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.overlay1
                }
            }
            Rectangle {
                id: chip
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                radius: 7
                color: Theme.base
                border.color: Theme.surface
                border.width: 1
                implicitWidth: chipRow.implicitWidth + 18
                implicitHeight: 26
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Presence.ringColor
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Presence.label
                        font.family: Theme.fontUi
                        font.pixelSize: 11
                        font.bold: true
                        color: Presence.ringColor
                    }
                }
            }
        }

        // ===== PRESENCE =====
        SectionLabel { text: "NOTIFICATION STATUS" }

        Rectangle {
            width: parent.width
            implicitHeight: 34
            radius: 10
            color: Theme.base
            border.color: Theme.surface
            border.width: 1

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { key: "available", label: "Available", glyph: Config.avatar.icons.available },  // check-circle
                        { key: "focus",     label: "Focus",     glyph: Config.avatar.icons.focus },  // bullseye
                        { key: "dnd",       label: "DND",       glyph: Config.avatar.icons.dnd }   // bell-slash
                    ]
                    Rectangle {
                        id: seg
                        required property var modelData
                        readonly property bool active: Presence.state === modelData.key
                        // Same palette names the ring uses, from the preset.
                        readonly property color tone: Theme[Config.avatar.presence[modelData.key]] || Theme.green
                        width: (parent.width - 6) / 3
                        height: parent.height
                        radius: 7
                        color: active ? tone : (segMouse.containsMouse ? Theme.surface : "transparent")
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: seg.modelData.glyph
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: seg.active ? Theme.onAccent : Theme.overlay1
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: seg.modelData.label
                                font.family: Theme.fontUi
                                font.pixelSize: 12
                                font.bold: true
                                color: seg.active ? Theme.onAccent : Theme.overlay1
                            }
                        }
                        MouseArea {
                            id: segMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Presence.set(seg.modelData.key)
                        }
                    }
                }
            }
        }

        // Note line — says what the state actually does today, not what the mockup
        // promised: swaync has no per-app rules, so Focus silences everything too.
        // Pinned to one line (fixed height, elide, no wrap): a note that wraps would
        // resize the whole popover as the presence changes under the cursor.
        Item {
            width: parent.width
            height: 18
            Text {
                id: noteGlyph
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Presence.state === "available" ? Config.avatar.icons.bell : Config.avatar.icons.dnd
                font.family: Theme.fontMono
                font.pixelSize: 13
                color: Presence.state === "available" ? Theme.overlay0 : Presence.ringColor
            }
            Text {
                anchors.left: noteGlyph.right
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: Presence.state === "available"
                    ? "All notifications pass through."
                    : (Presence.state === "focus"
                        ? "Everything held — per-app rules come later."
                        : "Notifications silenced" + (Presence.count > 0
                            ? " — " + Presence.count + " held in the centre." : "."))
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: Presence.state === "available" ? Theme.overlay0 : Presence.ringColor
            }
        }

        // ===== IDLE INHIBITOR =====
        SectionLabel { text: "IDLE INHIBITOR" }

        Rectangle {
            width: parent.width
            implicitHeight: 52
            radius: 11
            color: Theme.base
            border.color: Idle.enabled ? Theme.green : Theme.surface
            border.width: 1

            Text {
                id: idleGlyph
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: Idle.enabled ? Config.avatar.icons.awake : Config.avatar.icons.asleep
                font.family: Theme.fontMono
                font.pixelSize: 17
                color: Idle.enabled ? Theme.green : Theme.overlay0
            }
            Column {
                anchors.left: idleGlyph.right
                anchors.leftMargin: 10
                anchors.right: idleSwitch.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: "Keep awake"
                    font.family: Theme.fontUi
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Idle.sub
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.overlay1
                }
            }
            ToggleSwitch {
                id: idleSwitch
                anchors.right: parent.right
                anchors.rightMargin: 11
                anchors.verticalCenter: parent.verticalCenter
                on: Idle.enabled
                color: Idle.enabled ? Theme.green : Theme.surface
                onToggled: Idle.toggle()
            }
        }

        // Duration chips — picking one also arms the inhibitor.
        Row {
            width: parent.width
            spacing: 6
            Repeater {
                model: Idle.durations
                Rectangle {
                    id: chipItem
                    required property var modelData
                    readonly property bool active: Idle.enabled && Idle.minutes === modelData
                    width: (parent.width - 18) / 4
                    height: 28
                    radius: 8
                    color: active ? Theme.surface : (chipMouse.containsMouse ? Theme.base : "transparent")
                    border.color: active ? Theme.green : Theme.surface
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Text {
                        anchors.centerIn: parent
                        text: Idle.durationLabel(chipItem.modelData)
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: chipItem.active ? Theme.green : (Idle.enabled ? Theme.overlay1 : Theme.overlay0)
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Idle.hold(chipItem.modelData)
                    }
                }
            }
        }

        // ===== NETWORK =====
        Item {
            width: parent.width
            height: 16
            SectionLabel {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "NETWORK"
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "default via " + root.defaultVia
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.overlay0
            }
        }

        Rectangle {
            width: parent.width
            radius: 11
            color: Theme.base
            border.color: root.listOpen ? Theme.surfaceAlt : Theme.surface
            border.width: 1
            clip: true
            implicitHeight: netCol.implicitHeight

            Column {
                id: netCol
                width: parent.width

                // ---- Wired row: only while a cable is actually live. The artboard
                // draws the plugged case only; with no link the row would be a
                // permanent dead entry on a desktop that lives on wifi.
                Rectangle {
                    width: parent.width
                    implicitHeight: 48
                    visible: root.wiredUp
                    color: root.defaultVia === (root.wired ? root.wired.name : "")
                        ? Theme.surface : "transparent"
                    Text {
                        id: wiredGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.avatar.icons.check   // carries the default route
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        color: Theme.green
                    }
                    Column {
                        anchors.left: wiredGlyph.right
                        anchors.leftMargin: 9
                        anchors.right: wiredPlug.left
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: "Ethernet"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.fg
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: (root.wired && root.wired.linkSpeed > 0
                                    ? root.wired.linkSpeed + " Mb/s · " : "")
                                + (root.ip(root.wired) || (root.wired ? root.wired.name : ""))
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.overlay1
                        }
                    }
                    Text {
                        id: wiredPlug
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.avatar.icons.wired
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: Theme.green
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface
                    visible: root.wiredUp
                }

                // ---- Wi-Fi row ----
                Rectangle {
                    width: parent.width
                    implicitHeight: 48
                    color: (!root.wiredUp && root.wifiOn && root.wifiDev && root.wifiDev.connected)
                        ? Theme.surface : "transparent"
                    Text {
                        id: wifiGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        text: (!root.wiredUp && root.wifiOn && root.activeNet) ? Config.avatar.icons.check : Config.avatar.icons.wifi
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        color: !root.wifiOn ? Theme.overlay0
                            : (!root.wiredUp && root.activeNet ? Theme.green : Theme.blue)
                    }
                    Column {
                        anchors.left: wifiGlyph.right
                        anchors.leftMargin: 9
                        anchors.right: wifiSwitch.left
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: !root.wifiOn ? "Wi-Fi off"
                                : (root.activeNet ? root.activeNet.name : "Not connected")
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: root.wifiOn ? Theme.fg : Theme.overlay1
                        }
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: !root.wifiOn ? "radio disabled"
                                : (root.activeNet
                                    ? root.pct(root.activeNet) + "% · "
                                      + (root.ip(root.wifiDev) || (root.wifiDev ? root.wifiDev.name : ""))
                                    : (root.wifiNets.length + " networks in range"))
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.overlay1
                        }
                    }
                    ToggleSwitch {
                        id: wifiSwitch
                        anchors.right: chevron.left
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        on: root.wifiOn
                        onToggled: {
                            Networking.wifiEnabled = !root.wifiOn;
                            root.listOpen = false;
                        }
                    }
                    Text {
                        id: chevron
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.listOpen ? Config.avatar.icons.chevronUp : Config.avatar.icons.chevronDown
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.overlay0
                    }
                    MouseArea {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: wifiSwitch.left
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.wifiOn) root.listOpen = !root.listOpen
                    }
                    // The chevron is part of the expander, but sits past the switch.
                    MouseArea {
                        anchors.left: chevron.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.wifiOn) root.listOpen = !root.listOpen
                    }
                }

                // ---- SSID list ----
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.surface
                    visible: root.listOpen && root.wifiOn
                }

                Flickable {
                    width: parent.width
                    visible: root.listOpen && root.wifiOn
                    implicitHeight: Math.min(netList.implicitHeight + 10, Config.avatar.netListHeight)
                    contentHeight: netList.implicitHeight + 10
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: netList
                        x: 5
                        y: 5
                        width: parent.width - 10
                        spacing: 2

                        Repeater {
                            model: root.sortedNets
                            Rectangle {
                                id: netRow
                                required property var modelData
                                // Unknown networks need a PSK, and this shell never asks
                                // for one — joining a new SSID is a terminal job. They
                                // are listed (with no `saved` chip) but inert.
                                readonly property bool joinable: modelData.known
                                width: parent.width
                                implicitHeight: 32
                                radius: 8
                                color: modelData.connected ? Theme.surface
                                    : (netMouse.containsMouse && joinable ? Theme.mantle : "transparent")
                                opacity: joinable ? 1.0 : 0.45

                                Text {
                                    id: netGlyph
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: netRow.modelData.connected ? Config.avatar.icons.check : Config.avatar.icons.wifi
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: netRow.modelData.connected ? Theme.green : Theme.overlay1
                                }
                                Text {
                                    id: netName
                                    anchors.left: netGlyph.right
                                    anchors.leftMargin: 9
                                    anchors.right: netTail.left
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    text: netRow.modelData.name
                                    font.family: Theme.fontUi
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: netRow.modelData.connected ? Theme.fg : Theme.subtext0
                                }
                                Row {
                                    id: netTail
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 7
                                    // Saved: NetworkManager already holds this network's
                                    // secret, so a click can join it.
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: netRow.modelData.known
                                        radius: 5
                                        color: Theme.mantle
                                        border.color: Theme.surface
                                        border.width: 1
                                        implicitWidth: savedText.implicitWidth + 12
                                        implicitHeight: 17
                                        Text {
                                            id: savedText
                                            anchors.centerIn: parent
                                            text: "saved"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.overlay1
                                        }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: root.secured(netRow.modelData)
                                        text: Config.avatar.icons.lock
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: Theme.overlay0
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 30
                                        horizontalAlignment: Text.AlignRight
                                        text: root.pct(netRow.modelData) + "%"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        color: Theme.overlay0
                                    }
                                }
                                MouseArea {
                                    id: netMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: netRow.joinable && !netRow.modelData.connected
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: netRow.modelData.connect()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ===== FACTS =====
        Rectangle {
            width: parent.width
            radius: 11
            color: Theme.base
            border.color: Theme.surface
            border.width: 1
            implicitHeight: facts.implicitHeight + 22


            Column {
                id: facts
                x: 12
                y: 11
                width: parent.width - 24
                spacing: 7
                // Rows and their order come from the preset; the values stay bindings
                // (not a function call) so uptime re-renders as it moves.
                Repeater {
                    model: Config.avatar.facts
                    Fact {
                        required property string modelData
                        key: modelData
                        value: modelData === "uptime"  ? Sys.uptimeText
                             : modelData === "kernel"  ? (Sys.kernel || "…")
                             : modelData === "session" ? "Hyprland · Wayland"
                             : modelData === "shell"   ? "quickshell"
                             : ""
                    }
                }
            }
        }
    }
}
