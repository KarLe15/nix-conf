import QtQuick
import QtQml
import "../Config"
import "../widgets"

// The interactive greeter. Typing the password dials the gate: each character
// codes a chevron and turns the inner ring, Enter locks the seventh and submits.
// A rejected password cancels the dial and turns every engaged chevron red.
//
// This is the only screen that takes input — SDDM gives each monitor its own QML
// engine, so the other two run entirely on their own.
Item {
    id: root

    function takeFocus() {
        if (fieldRef)
            fieldRef.take()
    }

    // ---- State --------------------------------------------------------------
    // The address field lives inside the gate's well, which is filled through a
    // Component, so it is reached through these rather than by id.
    property Item fieldRef: null
    property string password: ""

    property bool locked: false
    property bool failed: false
    // Chevrons engaged when the password was rejected, captured before the field
    // is cleared so the gate can show how far the dial got.
    property int failedAt: 0
    // Enter has been pressed and PAM has not answered yet: the seventh chevron
    // reads as engaged while the machine thinks.
    property bool lockRequested: false
    property string info: ""

    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)

    // theme.conf's previewState, so `--test-mode` can hold the gate in any state.
    readonly property string preview:
        (typeof config !== "undefined" && config.previewState) ? config.previewState : "live"

    readonly property bool vortex: preview === "success" || (preview === "live" && locked)
    readonly property bool cancelled: !vortex && (preview === "error" || (preview === "live" && failed))
    readonly property bool capsOn: preview === "capslock" || (preview === "live" && keyboard.capsLock)

    readonly property color chevronColor: Theme[Config.colors.chevron]
    readonly property color horizonColor: Theme[Config.colors.horizon]
    readonly property color errorColor: Theme[Config.colors.error]
    readonly property color capsColor: Theme[Config.colors.caps]

    // Chevrons engaged. Typing stops at maxPreLock so a long password looks the
    // same on screen as a six-character one; only Enter reaches seven.
    readonly property int lit: {
        if (preview === "dialing") return 4
        if (preview === "error") return 5
        if (vortex || lockRequested) return 7
        if (cancelled) return failedAt
        return Math.min(password.length, Config.gate.maxPreLock)
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

    // ---- Users --------------------------------------------------------------
    // userModel is a QAbstractItemModel with no scalar accessors, so it is
    // reflected into plain objects the rest of the screen can read.
    Instantiator {
        id: users
        model: userModel
        delegate: QtObject {
            readonly property string name: model.name
            readonly property string realName: model.realName
        }
    }

    readonly property var currentUser: users.objectAt(userIndex)
    readonly property string userName: currentUser ? currentUser.name : userModel.lastUser
    readonly property string realName: currentUser ? currentUser.realName : ""

    // ---- Login --------------------------------------------------------------
    function submit() {
        if (password.length === 0)
            return
        failed = false
        locked = false
        info = ""
        lockRequested = true
        sddm.login(root.userName, root.password, root.sessionIndex)
    }

    function clearField() {
        if (fieldRef)
            fieldRef.text = ""
        password = ""
    }

    function reset() {
        clearField()
        failed = false
        locked = false
        lockRequested = false
        info = ""
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.lockRequested = false
            root.failed = false
            root.locked = true
        }

        function onLoginFailed() {
            root.failedAt = Math.min(root.password.length, 7)
            root.lockRequested = false
            root.locked = false
            root.clearField()
            root.failed = true
            root.takeFocus()
        }

        // PAM's own wording (an expired account, a lockout notice) says more than
        // the generic refusal, so it replaces it when there is one.
        function onInformationMessage(message) {
            root.info = message
        }
    }

    // ---- Field presentation -------------------------------------------------
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
            return "Chevron 7 verrouillé · bienvenue, " + (realName.length > 0 ? realName : userName)
        if (cancelled)
            return info.length > 0 ? info : "Composition annulée · mot de passe incorrect"
        if (capsOn)
            return "Verr. Maj activé"
        if (lockRequested)
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

    // ---- Layout -------------------------------------------------------------
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
                    text: sddm.hostName
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

                // Caps lock, next to the layout it applies to. Shown only when it
                // is on — which is exactly when a refused password needs
                // explaining.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: root.capsOn

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

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.icons.keyboard
                        font.pixelSize: 20
                        color: Theme.teal
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: keyboard.layouts.length > 0
                              ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase()
                              : ""
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: Theme.fg
                    }
                }

                BarDivider { anchors.verticalCenter: parent.verticalCenter }

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

        // ---- Left: the clock and who is logging in --------------------------
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
                userName: root.userName
                realName: root.realName
                host: sddm.hostName
                cyclable: userModel.count > 1
                onCycle: root.userIndex = (root.userIndex + 1) % userModel.count
            }
        }

        // ---- Centre: the gate -----------------------------------------------
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

                            Component.onCompleted: root.fieldRef = pwField

                            onSubmitted: root.submit()
                            onCancelled: root.reset()

                            onTextChanged: {
                                root.password = text
                                // Typing again after a refusal starts a fresh dial.
                                if (text.length > 0 && (root.failed || root.locked)) {
                                    root.failed = false
                                    root.locked = false
                                    root.info = ""
                                }
                            }
                        }

                        Item { width: 1; height: 14 }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 22
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

        // ---- Right: the dial sequence and the destination --------------------
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

            Item { width: 1; height: 30 }

            SectionHeader {
                width: rightColumn.width
                label: "Destination"
            }

            Item { width: 1; height: 12 }

            SessionPicker {
                width: rightColumn.width
                accent: root.chevronColor
                currentIndex: root.sessionIndex
                onPicked: function (index) { root.sessionIndex = index }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        text: Screen.name.toUpperCase() + " · " + Screen.width + "×" + Screen.height
        font.family: Theme.fontMono
        font.pixelSize: 14
        font.weight: Font.DemiBold
        font.letterSpacing: 2
        color: Theme.surface1
    }
}
