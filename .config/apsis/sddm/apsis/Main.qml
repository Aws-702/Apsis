// The Apsis SDDM login screen; colours and options come from theme.conf.
// Edit: layout and sizes here; colours in theme.conf (apsis-sddm-apply rewrites them).

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    color: pal.bgMain

    readonly property string paletteName: (config.palette && config.palette.length) ? config.palette : "cherry"
    readonly property var pal: paletteName === "navy" ? navy : cherry

    function ov(v, d) { return (v && v.length) ? v : d }

    QtObject {
        id: cherry
        readonly property color bgMain:        root.ov(config.bgOverride,            "#17090F")
        readonly property color bgCard:        root.ov(config.bgCardOverride,        "#210D15")
        readonly property color bgItem:        root.ov(config.bgItemOverride,        "#351421")
        readonly property color textPrimary:   root.ov(config.textPrimaryOverride,   "#F6E9EF")
        readonly property color textSecondary: root.ov(config.textSecondaryOverride, "#C99BAB")
        readonly property color accent:        root.ov(config.accentOverride,        "#EC4C78")
        readonly property color outline:       root.ov(config.outlineOverride,       "#33FFFFFF")
        readonly property color danger: "#FF6B81"
    }
    QtObject {
        id: navy
        readonly property color bgMain: (config.bgOverride && config.bgOverride.length) ? config.bgOverride : "#0A0A3C"
        readonly property color bgCard: "#101445"
        readonly property color bgItem: "#1C2160"
        readonly property color textPrimary: "#F3ECF5"
        readonly property color textSecondary: "#98A0D0"
        readonly property color accent: (config.accentOverride && config.accentOverride.length) ? config.accentOverride : "#3AD6E0"
        readonly property color outline: "#28FFFFFF"
        readonly property color danger: "#FF6B81"
    }

    readonly property string fontFamily: (config.font && config.font.length) ? config.font : "JetBrainsMono Nerd Font"
    readonly property string clockFmt: (config.clockFormat && config.clockFormat.length) ? config.clockFormat : "HH:mm"
    readonly property string curUser: userBox.currentText
    readonly property int dimPct: (config.dim && config.dim.length) ? parseInt(config.dim) : 40

    Image {
        id: bgImg
        anchors.fill: parent
        source: (config.background && config.background.length) ? config.background : ""
        fillMode: Image.PreserveAspectCrop
        visible: source != ""
    }

    Rectangle {
        anchors.fill: parent
        visible: bgImg.visible
        color: pal.bgMain
        opacity: Math.max(0, Math.min(100, root.dimPct)) / 100
    }

    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        spacing: 10
        PowerButton { label: "sleep";   onActivated: sddm.suspend() }
        PowerButton { label: "restart"; onActivated: sddm.reboot() }
        PowerButton { label: "off";     onActivated: sddm.powerOff() }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 56
        spacing: 4
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: pal.textPrimary
            font.family: root.fontFamily
            font.pixelSize: 72
            font.weight: Font.Light
            text: Qt.formatDateTime(new Date(), root.clockFmt)
        }
        Text {
            id: dateLabel
            anchors.horizontalCenter: parent.horizontalCenter
            color: pal.textSecondary
            font.family: root.fontFamily
            font.pixelSize: 18
            text: Qt.formatDateTime(new Date(), "dddd, d MMMM")
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            clock.text = Qt.formatDateTime(new Date(), root.clockFmt)
            dateLabel.text = Qt.formatDateTime(new Date(), "dddd, d MMMM")
        }
    }

    Rectangle {
        anchors.centerIn: card
        width: card.width + 24
        height: card.height + 24
        radius: 24
        color: "#000000"
        opacity: 0.35
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 400
        height: col.implicitHeight + 52
        radius: 18
        color: pal.bgCard
        border.width: 1
        border.color: pal.outline

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 16

            Item {
                id: avatarBox
                Layout.alignment: Qt.AlignHCenter
                width: 76; height: 76

                readonly property string avatarSrc: (config.avatar && config.avatar.length) ? config.avatar : ""
                property bool hasPhoto: false

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: pal.bgItem
                    border.width: 2
                    border.color: pal.accent
                    visible: !avatarBox.hasPhoto
                    Text {
                        anchors.centerIn: parent
                        text: root.curUser.length ? root.curUser.charAt(0).toUpperCase() : "?"
                        color: pal.accent
                        font.family: root.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.Medium
                    }
                }

                Image {
                    id: probe
                    source: avatarBox.avatarSrc
                    visible: false
                    asynchronous: true
                    onStatusChanged: {
                        if (status === Image.Ready) { avatarBox.hasPhoto = true; faceCanvas.requestPaint() }
                        else if (status === Image.Error) { avatarBox.hasPhoto = false }
                    }
                }

                Canvas {
                    id: faceCanvas
                    anchors.fill: parent
                    visible: avatarBox.hasPhoto
                    onPaint: {
                        if (probe.status !== Image.Ready) return
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var iw = probe.sourceSize.width
                        var ih = probe.sourceSize.height
                        if (!iw || !ih) return
                        var s = Math.min(iw, ih)
                        var sx = (iw - s) / 2
                        var sy = (ih - s) / 2
                        ctx.save()
                        ctx.beginPath()
                        ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2)
                        ctx.closePath()
                        ctx.clip()
                        ctx.drawImage(probe, sx, sy, s, s, 0, 0, width, height)
                        ctx.restore()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: pal.accent
                    visible: avatarBox.hasPhoto
                }
            }

            ComboBox {
                id: userBox
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                font.family: root.fontFamily
                background: Rectangle { radius: 10; color: pal.bgItem; border.width: 1; border.color: pal.outline }
                contentItem: Text {
                    text: userBox.displayText
                    color: pal.textPrimary
                    font: userBox.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                popup: Popup {
                    y: userBox.height + 4
                    width: userBox.width
                    padding: 4
                    background: Rectangle { radius: 10; color: pal.bgCard; border.width: 1; border.color: pal.outline }
                    contentItem: ListView {
                        implicitHeight: Math.min(contentHeight, 200)
                        model: userBox.popup.visible ? userBox.delegateModel : null
                        clip: true
                    }
                }
                delegate: ItemDelegate {
                    width: userBox.width - 8
                    highlighted: userBox.highlightedIndex === index
                    contentItem: Text {
                        text: model.name
                        color: pal.textPrimary
                        font.family: root.fontFamily
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { radius: 8; color: highlighted ? pal.bgItem : "transparent" }
                }
            }

            TextField {
                id: pw
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                echoMode: TextInput.Password
                placeholderText: "Password"
                font.family: root.fontFamily
                color: pal.textPrimary
                placeholderTextColor: pal.textSecondary
                horizontalAlignment: Text.AlignHCenter
                background: Rectangle {
                    radius: 10
                    color: pal.bgItem
                    border.width: pw.activeFocus ? 2 : 1
                    border.color: pw.activeFocus ? pal.accent : pal.outline
                }
                onAccepted: root.doLogin()
            }

            Button {
                id: loginBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                text: "Log in"
                font.family: root.fontFamily
                contentItem: Text {
                    text: loginBtn.text
                    color: pal.bgMain
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { radius: 10; color: loginBtn.down ? Qt.darker(pal.accent, 1.15) : pal.accent }
                onClicked: root.doLogin()
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: root.fontFamily
                font.pixelSize: 11
                background: Rectangle { radius: 8; color: "transparent"; border.width: 1; border.color: pal.outline }
                contentItem: Text {
                    text: sessionBox.displayText
                    color: pal.textSecondary
                    font: sessionBox.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                popup: Popup {
                    y: -(implicitHeight + 4)
                    width: sessionBox.width
                    padding: 4
                    background: Rectangle { radius: 8; color: pal.bgCard; border.width: 1; border.color: pal.outline }
                    contentItem: ListView {
                        implicitHeight: Math.min(contentHeight, 180)
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        clip: true
                    }
                }
                delegate: ItemDelegate {
                    width: sessionBox.width - 8
                    highlighted: sessionBox.highlightedIndex === index
                    contentItem: Text {
                        text: model.name
                        color: pal.textPrimary
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle { radius: 6; color: highlighted ? pal.bgItem : "transparent" }
                }
            }

            Text {
                id: err
                Layout.fillWidth: true
                color: pal.danger
                font.family: root.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                visible: text.length > 0
                text: ""
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: card.bottom
        anchors.topMargin: 16
        color: pal.danger
        font.family: root.fontFamily
        font.pixelSize: 12
        visible: keyboard.capsLock
        text: "Caps Lock is on"
    }

    function doLogin() {
        err.text = ""
        sddm.login(userBox.currentText, pw.text, sessionBox.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            err.text = "Login failed"
            pw.text = ""
            pw.forceActiveFocus()
        }
    }

    Component.onCompleted: pw.forceActiveFocus()

    component PowerButton: Button {
        id: pb
        property string label: ""
        signal activated()
        implicitHeight: 32
        implicitWidth: lbl.implicitWidth + 24
        onClicked: pb.activated()
        contentItem: Text {
            id: lbl
            text: pb.label
            color: pb.down ? pal.accent : pal.textSecondary
            font.family: root.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            radius: 8
            color: pb.down ? pal.bgItem : "transparent"
            border.width: 1
            border.color: pal.outline
        }
    }
}
