import QtQuick
import "root:/"

// Audio + Bluetooth control popover (Volume Bluetooth Widget · 8b). Output device
// card, a live volume slider + mute, and the Bluetooth adapter toggle + device
// list (connect/disconnect, battery). Reads/acts on `hub` (the VolumeBluetooth
// pill), which owns the Pipewire + Bluetooth handles.
Rectangle {
    id: root
    property var hub

    readonly property int inner: 340
    readonly property color accent: Theme.sapphire

    color: Theme.mantle
    border.color: Theme.surface
    border.width: 1
    radius: 16
    implicitWidth: inner + 32
    implicitHeight: layout.implicitHeight + 32

    function devGlyph(icon) {
        const s = (icon || "").toLowerCase();
        if (s.indexOf("audio") >= 0 || s.indexOf("headset") >= 0 || s.indexOf("headphone") >= 0) return "";
        if (s.indexOf("gaming") >= 0 || s.indexOf("joystick") >= 0 || s.indexOf("gamepad") >= 0) return "";
        if (s.indexOf("keyboard") >= 0) return "";
        if (s.indexOf("phone") >= 0) return "";
        return ""; // bluetooth
    }
    function batGlyph(p) {
        return p >= 88 ? "" : p >= 63 ? "" : p >= 38 ? "" : p >= 13 ? "" : "";
    }
    function batPct(d) {
        const b = d.battery;
        return b <= 1 ? Math.round(b * 100) : Math.round(b);
    }

    Column {
        id: layout
        x: 16
        y: 16
        width: root.inner
        spacing: 12

        // ===== OUTPUT =====
        Item {
            width: parent.width
            height: 16
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "OUTPUT"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: Theme.overlay1
            }
        }

        // Output device card.
        Rectangle {
            width: parent.width
            radius: 11
            color: Theme.base
            border.color: Theme.surface
            border.width: 1
            implicitHeight: 58
            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 11
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 36
                    radius: 9
                    color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: "\uf028"  // speaker
                        font.family: Theme.fontMono
                        font.pixelSize: 17
                        color: Theme.onAccent
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 47
                    elide: Text.ElideRight
                    text: root.hub.sinkName
                    font.family: Theme.fontUi
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.fg
                }
            }
        }

        // Volume slider row.
        Row {
            width: parent.width
            spacing: 11
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: 8
                color: muteArea.containsMouse ? Theme.surface : Theme.base
                border.color: Theme.surface
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: root.hub.muted ? "\uf026" : "\uf028"  // volume-off / up
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.fg
                }
                MouseArea {
                    id: muteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.hub.toggleMute()
                }
            }
            // Slider.
            Item {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 32 - 42 - 22
                height: 16
                readonly property real value: root.hub.muted ? 0 : (root.hub.volPct / 100)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surface
                    Rectangle {
                        height: parent.height
                        width: parent.width * slider.value
                        radius: 3
                        color: root.accent
                    }
                }
                Rectangle {
                    x: slider.value * (parent.width - 15)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 15
                    height: 15
                    radius: 8
                    color: "#eff1f5"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function apply(mx) { root.hub.setVolume(Math.max(0, Math.min(1, mx / width))); }
                    onPressed: (m) => apply(m.x)
                    onPositionChanged: (m) => { if (pressed) apply(m.x); }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignRight
                text: root.hub.muted ? "muted" : root.hub.volPct + "%"
                font.family: Theme.fontMono
                font.pixelSize: 13
                font.bold: true
                color: Theme.fg
            }
        }

        // ===== BLUETOOTH =====
        Rectangle { width: parent.width; height: 1; color: Theme.surface }

        Item {
            width: parent.width
            height: 24
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf293"  // bluetooth
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.blue
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "BLUETOOTH"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.overlay1
                }
            }
            Text {
                anchors.right: toggle.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.hub.btEnabled ? "On" : "Off"
                font.family: Theme.fontUi
                font.pixelSize: 12
                color: root.hub.btEnabled ? Theme.blue : Theme.overlay0
            }
            // Adapter power toggle.
            Rectangle {
                id: toggle
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 22
                radius: 11
                color: root.hub.btEnabled ? Theme.blue : Theme.surface
                Rectangle {
                    y: 2
                    x: root.hub.btEnabled ? 18 : 2
                    width: 18
                    height: 18
                    radius: 9
                    color: "#eff1f5"
                    Behavior on x { NumberAnimation { duration: 120 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.hub.btAdapter) root.hub.btAdapter.enabled = !root.hub.btAdapter.enabled
                }
            }
        }

        // Device list (dimmed + inert when the adapter is off).
        Column {
            width: parent.width
            spacing: 6
            opacity: root.hub.btEnabled ? 1.0 : 0.4
            enabled: root.hub.btEnabled

            Repeater {
                model: root.hub.btDevices
                Rectangle {
                    id: dev
                    required property var modelData
                    width: parent.width
                    radius: 10
                    implicitHeight: 46
                    color: rowArea.containsMouse ? Theme.base : "transparent"
                    border.color: dev.modelData.connected ? root.accent : "transparent"
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 11
                        anchors.rightMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 11

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: root.devGlyph(dev.modelData.icon)
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: dev.modelData.connected ? Theme.fg : Theme.overlay1
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20 - 11 - actionT.width - 11
                            spacing: 2
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: dev.modelData.name || dev.modelData.deviceName || "Device"
                                font.family: Theme.fontUi
                                font.pixelSize: 13
                                font.bold: true
                                color: dev.modelData.connected ? Theme.fg : Theme.subtext1
                            }
                            Row {
                                spacing: 5
                                Text {
                                    visible: dev.modelData.connected
                                    text: "● Connected"
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    color: Theme.green
                                }
                                Text {
                                    visible: !dev.modelData.connected
                                    text: dev.modelData.paired ? "Paired" : "Available"
                                    font.family: Theme.fontUi
                                    font.pixelSize: 11
                                    color: Theme.overlay0
                                }
                                Text {
                                    visible: dev.modelData.batteryAvailable
                                    text: root.batGlyph(root.batPct(dev.modelData)) + " " + root.batPct(dev.modelData) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: Theme.green
                                }
                            }
                        }
                        Text {
                            id: actionT
                            anchors.verticalCenter: parent.verticalCenter
                            text: dev.modelData.pairing ? "…"
                                : dev.modelData.connected ? "Disconnect" : "Connect"
                            font.family: Theme.fontUi
                            font.pixelSize: 12
                            font.bold: true
                            color: dev.modelData.connected ? Theme.overlay1 : Theme.blue
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dev.modelData.connected
                                    ? dev.modelData.disconnect()
                                    : dev.modelData.connect()
                            }
                        }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            // Scan.
            Item {
                width: parent.width
                height: 34
                Rectangle { width: parent.width; height: 1; color: Theme.surface; anchors.top: parent.top }
                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 4
                    spacing: 7
                    Text {
                        text: "\uf021"  // refresh
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: root.hub.btAdapter && root.hub.btAdapter.discovering ? Theme.blue : Theme.overlay1
                    }
                    Text {
                        text: root.hub.btAdapter && root.hub.btAdapter.discovering ? "Scanning…" : "Scan for devices"
                        font.family: Theme.fontUi
                        font.pixelSize: 12
                        color: scanArea.containsMouse ? Theme.fg : Theme.overlay1
                    }
                }
                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.hub.btAdapter) root.hub.btAdapter.discovering = !root.hub.btAdapter.discovering
                }
            }
        }
    }
}
