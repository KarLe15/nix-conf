import QtQuick
import "../Config"

// The connector and mode, bottom right — the same label the design puts on every
// screen so a photo of the wall says which monitor is which.
Text {
    text: Screen.name.toUpperCase() + " · " + Screen.width + "×" + Screen.height
    font.family: Theme.fontMono
    font.pixelSize: 14
    font.weight: Font.DemiBold
    font.letterSpacing: 2
    color: Theme.surface1
}
