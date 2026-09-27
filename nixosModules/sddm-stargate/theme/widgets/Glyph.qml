import QtQuick
import "../Config"

// A Nerd Font glyph. Every icon in this theme is a codepoint in the monospace
// font rather than an image, so the greeter needs no icon theme installed for
// the `sddm` user — only the font the fonts preset already puts system-wide.
Text {
    font.family: Theme.fontMono
    font.pixelSize: 20
    color: Theme.subtext0
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
