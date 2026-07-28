/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import de.idoc.fluxus.backend 1.0
import "../package/contents/ui" as FluxusUi

Window {
    width: 74
    height: 77
    visible: true
    color: "transparent"

    QtObject {
        id: config
        property string backgroundColor: "#2D333C"
        property string gridColor: "#171B1E"
        property string uploadColor: "#BC8844"
        property string downloadColor: "#00E6E6"
        property string labelColor: "#FFFFFF"
        property string numericPosition: "topLeft"
        property string numericFontFamily: "Monospace"
        property int numericFontSize: 15
        property bool autoNumericFontSize: false
        property bool splitDirections: false
        property int historySeconds: 10
        property bool uploadInverted: true
        property bool downloadInverted: false
        property string uploadStyle: "filled"
        property string downloadStyle: "line"
        property string gridMode: "auto"
        property int gridLineCount: 6
        property bool showNumeric: true
        property bool showLeds: true
        property bool showInterfaceName: true
    }

    NetworkSource { id: source }

    FluxusUi.FluxusView {
        id: view
        anchors.fill: parent
        source: source
        configuration: config
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            for (let index = 0; index < 190; ++index) {
                const up = index < 90 ? 97375 : 18750 + Math.abs(Math.sin(index / 11)) * 65000
                const down = index < 55 ? 250 : 250 + Math.abs(Math.sin(index / 7)) * 27500
                source.sampled(down, up)
            }
            captureTimer.start()
        }
    }

    Timer {
        id: captureTimer
        interval: 200
        onTriggered: view.grabToImage(result => {
            if (!result.saveToFile("/tmp/fluxus-visual-smoke.png")) {
                Qt.exit(1)
                return
            }
            Qt.exit(0)
        })
    }
}
