/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import de.idoc.fluxus.backend 1.0
import "../package/contents/ui" as FluxusUi

Window {
    id: window

    width: 74
    height: 77
    visible: true
    color: "transparent"

    QtObject {
        id: config
        property string backgroundColor: "#14161A"
        property string gridColor: "#555555"
        property string uploadColor: "#BC8844"
        property string downloadColor: "#00E6E6"
        property string labelColor: "#FFFFFF"
        property string numericPlacement: "status"
        property string numericPosition: "topLeft"
        property string numericFontFamily: "Monospace"
        property int numericFontSize: 10
        property bool autoNumericFontSize: false
        property bool splitDirections: false
        property int historySeconds: 120
        property bool uploadInverted: false
        property bool downloadInverted: true
        property string uploadStyle: "bars"
        property string downloadStyle: "bars"
        property string gridMode: "off"
        property int gridLineCount: 6
        property bool showNumeric: true
        property bool showLeds: true
        property bool showInterfaceName: true
    }

    NetworkSource {
        id: source
        interfaceName: "wlan1"
    }

    FluxusUi.FluxusView {
        anchors.fill: parent
        source: source
        configuration: config
    }

    Timer {
        interval: 150
        running: true
        onTriggered: window.contentItem.grabToImage(result => {
            if (!result.saveToFile("/tmp/fluxus-statistics-placement-smoke.png")) {
                Qt.exit(1)
                return
            }
            Qt.exit(0)
        })
    }
}
