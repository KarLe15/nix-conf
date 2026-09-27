import QtQuick
import Quickshell
import "../Auth"
import "../Config"
import "../widgets"

// The interactive screen of the lock. Same gate as the greeter's — the dialling,
// the chevron order and the maxPreLock cap are unchanged — with SDDM's context
// objects swapped for the Auth singleton and PAM behind it.
//
// Two things the greeter's version has are gone: the session picker, because there
// is no session to choose when unlocking, and user switching, because the session
// belongs to whoever left it.
Item {
    id: root

    function takeFocus() {
        if (fieldRef)
            fieldRef.take()
    }

    property Item fieldRef: null

    readonly property color chevronColor: Theme[Config.colors.chevron]
    readonly property color horizonColor: Theme[Config.colors.horizon]
    readonly property color errorColor: Theme[Config.colors.error]
    readonly property color capsColor: Theme[Config.colors.caps]

    // STARGATE_PREVIEW_STATE holds the gate in one state so the design can be
    // worked on without authenticating. Ignored once the session is really locked.
    readonly property string preview:
        Auth.previewing ? String(Quickshell.env("STARGATE_PREVIEW_STATE") || "live") : "live"

    readonly property bool vortex: preview === "success" || (preview === "live" && Auth.vortex)
    readonly property bool cancelled: !vortex && (preview === "error" || (preview === "live" && Auth.failed))
    readonly property bool capsOn: preview === "capslock" || (preview === "live" && Auth.capsOn)

    readonly property int lit: {
        if (preview === "dialing") return 4
        if (preview === "error") return 5
        if (vortex || Auth.verifying) return 7
        if (cancelled) return Auth.failedAt
        return Math.min(Auth.password.length, Config.gate.maxPreLock)
    }

    readonly property string mode:
        vortex ? "locked" : cancelled ? "failed" : lit > 0 ? "dialing" : "standby"

    readonly property string statusLabel: ({
        "standby": "Porte en veille",
        "dialing": "Composition",
        "locked":  "Vortex établi",
        "failed":  "Composition annulée"
    })[mode]

    readonly property color statusColor: ({
        "standby": Theme.dim,
        "dialing": chevronColor,
        "locked":  horizonColor,
        "failed":  errorColor
    })[mode]

    readonly property color fieldRing:
        vortex ? horizonColor
               : cancelled ? errorColor
               : capsOn ? capsColor
               : lit > 0 ? chevronColor
               : Theme.surface1

    readonly property color fieldGlow:
        vortex ? Qt.rgba(horizonColor.r, horizonColor.g, horizonColor.b, 0.20)
               : cancelled ? Qt.rgba(errorColor.r, errorColor.g, errorColor.b, 0.16)
               : capsOn ? Qt.rgba(capsColor.r, capsColor.g, capsColor.b, 0.14)
               : lit > 0 ? Qt.rgba(chevronColor.r, chevronColor.g, chevronColor.b, 0.14)
               : "transparent"

    readonly property string hint: {
        if (vortex)
            return "Chevron 7 verrouillé · bon retour, " + Auth.user
        if (cancelled)
            return Auth.info.length > 0 ? Auth.info : "Composition annulée · mot de passe incorrect"
        if (capsOn)
            return "Verr. Maj activé"
        if (Auth.verifying)
            return "Verrouillage du chevron 7…"
        if (lit > 0)
            return "Chevron " + lit + " enclenché"
        return ""
    }

    readonly property color hintColor:
        vortex ? horizonColor
               : cancelled ? errorColor
               : capsOn ? capsColor
               : lit > 0 ? chevronColor
               : Theme.label

    // The field is the only thing on the lock that wants the keyboard, so it takes
    // it as soon as this screen exists and whenever the dial resets.
    Component.onCompleted: root.takeFocus()

    Connections {
        target: Auth
        function onFailedChanged() { if (Auth.failed) root.takeFocus() }
        function onLockedChanged() { if (Auth.locked) root.takeFocus() }
    }

    ScreenBackdrop {
        anchors.fill: parent
        focusX: 0.5
    }

    Clock { id: clock }

    TopBar {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.barMargin

        leftContent: Component {
            Row {
                spacing: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    height: 34
                    radius: 11
                    color: Theme.surface0

                    Glyph {
                        anchors.centerIn: parent
                        text: Config.icons.distro
                        font.pixelSize: 21
                        color: Theme.lavender
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Auth.host
                    font.family: Theme.fontMono
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    color: Theme.fg
                }

                BarDivider { anchors.verticalCenter: parent.verticalCenter }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Screen.name.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                    color: Theme.label
                }
            }
        }

        centerContent: Component {
            Row {
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 9
                    height: 9
                    radius: 4.5
                    color: root.statusColor

                    Behavior on color {
                        ColorAnimation { duration: 250 }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.statusLabel.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 2
                    color: root.statusColor
                }
            }
        }

        rightContent: Component {
            Row {
                spacing: 14

                // Faded rather than hidden: a Row re-packs around a child it drops,
                // which would shunt the power buttons sideways on a keypress.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    opacity: root.capsOn ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.icons.caps
                        font.pixelSize: 19
                        color: root.capsColor
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "MAJ"
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: root.capsColor
                    }
                }

                PowerActions { anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    Item {
        id: content
        anchors.top: parent.top
        anchors.topMargin: Theme.barMargin + Theme.barHeight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 64
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: "SALLE DE LA PORTE"
                font.family: Theme.fontMono
                font.pixelSize: 15
                font.bold: true
                font.letterSpacing: 4
                color: root.chevronColor
                bottomPadding: 22
            }

            Text {
                text: clock.time
                font.family: Theme.fontMono
                font.pixelSize: 132
                font.weight: Font.DemiBold
                font.letterSpacing: -6
                color: Theme.fg
            }

            Text {
                text: clock.dateLong
                font.family: Theme.fontUi
                font.pixelSize: 23
                font.weight: Font.Medium
                color: Theme.subtext0
                topPadding: 20
                bottomPadding: 34
            }

            Rectangle {
                width: 360
                height: 1
                color: Theme.border
            }

            Item { width: 1; height: 22 }

            UserBadge {
                userName: Auth.user
                host: Auth.host
                cyclable: false
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Gate {
                anchors.horizontalCenter: parent.horizontalCenter

                lit: root.lit
                failed: root.cancelled
                locked: root.vortex
                chevronColor: root.chevronColor
                horizonColor: root.horizonColor
                errorColor: root.errorColor

                centre: Component {
                    Column {
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "SAISIR L'ADRESSE"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            font.letterSpacing: 3
                            color: Theme.label
                            bottomPadding: 18
                        }

                        PasswordField {
                            id: pwField
                            anchors.horizontalCenter: parent.horizontalCenter
                            ringColor: root.fieldRing
                            glowColor: root.fieldGlow
                            accent: root.cancelled ? root.errorColor : root.chevronColor

                            Component.onCompleted: {
                                root.fieldRef = pwField
                                pwField.take()
                            }

                            onSubmitted: Auth.submit()
                            onCancelled: Auth.reset()

                            // Auth is the source of truth — the ambience screens can
                            // feed it too — so the field syncs both ways.
                            onTextChanged: {
                                if (text !== Auth.password)
                                    Auth.password = text
                                if (text.length > 0 && Auth.failed)
                                    Auth.failed = false
                            }

                            Connections {
                                target: Auth
                                function onPasswordChanged() {
                                    if (pwField.text !== Auth.password)
                                        pwField.text = Auth.password
                                }
                            }
                        }

                        Item { width: 1; height: 14 }

                        // Fixed box, centred text: a positioner drops any child whose
                        // width is zero, so an empty hint would take its own height
                        // out of the column and shift the field on the first keystroke.
                        Text {
                            width: 420
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.hint
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.5
                            color: root.hintColor
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22

                Text {
                    text: "a–z coder"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.dim
                }

                Text {
                    text: "↵ verrouiller ⅶ"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.dim
                }

                Text {
                    text: "esc annuler"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Theme.dim
                }
            }
        }

        // No "Destination" here: the session is already chosen, it is the one being
        // unlocked. The dial log gets the column to itself.
        Column {
            id: rightColumn
            anchors.right: parent.right
            anchors.rightMargin: 64
            anchors.verticalCenter: parent.verticalCenter
            width: 380
            spacing: 0

            SectionHeader {
                width: rightColumn.width
                label: "Séquence de composition"
                value: root.lit + " / 7"
                valueColor: root.statusColor
            }

            Item { width: 1; height: 6 }

            DialLog {
                width: rightColumn.width
                lit: root.lit
                failed: root.cancelled
                locked: root.vortex
                chevronColor: root.chevronColor
                horizonColor: root.horizonColor
                errorColor: root.errorColor
            }
        }
    }

    ScreenTag {
        anchors.right: parent.right
        anchors.rightMargin: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
    }
}
