import QtQuick
import "root:/"

// A fixed-width slot for text whose value changes at runtime. Measures every
// string the slot can ever hold and reports the widest, so the pill around it
// keeps one size instead of resizing under its own value — a submap pill that
// shrinks on "mic", an idle pill that narrows as its countdown ticks.
//
// Measured rather than assumed: labels come from presets and Nerd Font glyphs
// are not all one cell wide. Candidates are laid out invisibly at x: 0, so
// childrenRect.width is their maximum.
Item {
    id: slot

    // Every string this slot may display.
    property var candidates: []
    property string family: Theme.fontMono
    property int pixelSize: Theme.fontNormal
    // Measure bold when the live text is ever bold — bold is the wider of the two.
    property bool bold: false

    readonly property real widest: childrenRect.width

    visible: false

    Repeater {
        model: slot.candidates
        Text {
            text: modelData || ""
            font.family: slot.family
            font.pixelSize: slot.pixelSize
            font.bold: slot.bold
        }
    }
}
