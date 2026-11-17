// Desktop widget: the weather now, and with the forecast look the coming days.
// Edit: layout here; data from apsis-weather.sh and services/Forecast.qml; key and city in weather.conf.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    readonly property bool forecast: widget.style !== undefined && widget.style.forecast === true
    fill: Theme.bgCard

    property bool _counted: false
    function sync() {
        if (forecast && !_counted) { Forecast.want++; _counted = true }
        else if (!forecast && _counted) { Forecast.want--; _counted = false }
    }
    Component.onCompleted: { Sys.wantWeather++; sync() }
    Component.onDestruction: { Sys.wantWeather--; if (_counted) Forecast.want-- }
    onForecastChanged: sync()

    function tint(c) {
        c = String(c || "").toLowerCase()
        if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("thunder") >= 0) return Theme.cyan
        if (c.indexOf("cloud") >= 0 || c.indexOf("mist") >= 0 || c.indexOf("fog") >= 0) return Theme.textSecondary
        return Theme.warn
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
        visible: Sys.hasWeather

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Block {
                Layout.preferredWidth: 74
                Layout.preferredHeight: 78
                radius: 18
                fill: root.tint(Sys.cond)
                ring: Theme.ringActive
                VIcon { anchors.centerIn: parent; size: 44; d: Icons.weatherIcon(Sys.cond); color: Theme.bgMain }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label { text: Sys.temp_c + "°"; font.pixelSize: 40; font.weight: Font.Black }
                Label { text: Sys.desc ? Sys.desc.charAt(0).toUpperCase() + Sys.desc.slice(1) : ""; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                Label { sub: true; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight
                    text: (Sys.city ? Sys.city + "  " : "") + (Sys.hi > -999 ? "H " + Sys.hi + "°  L " + Sys.lo + "°" : "") }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.forecast
            spacing: 6
            Repeater {
                model: root.forecast ? Forecast.daily.slice(1, 6) : []
                Block {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    small: true
                    radius: 10
                    fill: Theme.bgItem
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Label { Layout.alignment: Qt.AlignHCenter; text: modelData.d; font.pixelSize: 10; font.weight: Font.DemiBold }
                        VIcon { Layout.alignment: Qt.AlignHCenter; size: 20; d: Icons.weatherIcon(modelData.cond); color: root.tint(modelData.cond) }
                        Label { Layout.alignment: Qt.AlignHCenter; text: modelData.hi + "°"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Label { Layout.alignment: Qt.AlignHCenter; sub: true; text: modelData.lo + "°"; font.pixelSize: 10 }
                    }
                }
            }
            Label {
                visible: root.forecast && !Forecast.has
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                sub: true
                font.pixelSize: 10
                text: "Loading the forecast..."
            }
        }
    }
    Label {
        anchors.centerIn: parent
        visible: !Sys.hasWeather
        sub: true
        horizontalAlignment: Text.AlignHCenter
        text: "Weather\nset APIKEY and CITY in\n~/.config/apsis/weather.conf"
        font.pixelSize: 11
    }

    BlockButton {
        visible: root.editing
        small: true
        width: 84
        height: 28
        anchors { right: parent.right; top: parent.top; margins: 10 }
        text: root.forecast ? "forecast" : "today"
        fontSize: 10
        onClicked: Desktop.setStyle(root.widget.id, "forecast", !root.forecast)
    }
}
