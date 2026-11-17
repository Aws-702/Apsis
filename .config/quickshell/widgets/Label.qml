// Shell text in the house font; `sub` for secondary, `caps` for small section headers.
// Edit: sizes here, the font in config/Theme.qml (fontText).

import QtQuick
import "../config"

Text {
    property bool sub: false
    property bool caps: false
    color: sub || caps ? Theme.textSecondary : Theme.textPrimary
    font.family: Theme.fontText
    font.pixelSize: caps ? 10 : 12
    font.letterSpacing: caps ? 1.4 : 0
    font.weight: caps ? Font.DemiBold : Font.Normal
    font.capitalization: caps ? Font.AllUppercase : Font.MixedCase
    elide: Text.ElideRight
}
