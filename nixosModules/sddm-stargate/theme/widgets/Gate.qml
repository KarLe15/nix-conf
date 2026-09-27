import QtQuick
import "../Config"

// The Stargate. Purely presentational: it is told how many chevrons have engaged
// and in what mode, and hosts whatever the screen wants in the well through the
// `centre` slot.
Item {
    id: root

    // Chevrons engaged, 0..7. The screen caps this while typing so the ring
    // never reports the full length of what has been entered.
    property int lit: 0
    property bool failed: false
    property bool locked: false

    property color chevronColor: Theme.peach
    property color horizonColor: Theme.blue
    property color errorColor: Theme.red

    // Filled into the well — the address field on the gate screen.
    property Component centre

    readonly property real k: width / 760
    readonly property color liveColor: failed ? errorColor : chevronColor

    // Chevron order as the gate engages them: three up the right, three down the
    // left, then the top one locks. Eight and nine exist on the ring but a
    // seven-symbol address never lights them.
    readonly property var chevronDegrees: [40, 80, 120, 240, 280, 320, 0, 160, 200]

    width: Config.gate.diameter
    height: width

    GateFrame {
        anchors.fill: parent
    }

    SymbolRing {
        anchors.fill: parent
        rotation: root.lit * Config.gate.degPerChar
    }

    GateHub {
        anchors.fill: parent
    }

    EventHorizon {
        anchors.centerIn: parent
        width: root.width - 276 * root.k
        height: width
        active: root.locked
        horizon: root.horizonColor
    }

    Repeater {
        model: root.chevronDegrees

        Chevron {
            // `index` is zero-based; the chevrons are numbered from one.
            readonly property int order: index + 1
            readonly property real deg: modelData
            readonly property real dist: Config.gate.chevronRadius * root.k

            width: 122 * root.k
            height: 118 * root.k
            x: root.width / 2 + dist * Math.sin(deg * Math.PI / 180) - width / 2
            y: root.height / 2 - dist * Math.cos(deg * Math.PI / 180) - height / 2
            rotation: deg

            lit: order <= 7 && order <= root.lit
            litColor: root.liveColor
        }
    }

    // No explicit size: the Loader takes the content's own and centres it in the
    // well. Sizing it to the well instead would stretch the content to fill.
    Loader {
        anchors.centerIn: parent
        sourceComponent: root.centre
    }
}
