/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import "../package/contents/ui" as FluxusUi

Window {
    id: window
    width: 48
    height: 20
    visible: true
    color: "#000000"

    Row {
        anchors.centerIn: parent
        spacing: 4
        FluxusUi.LedIndicator { glowColor: "#BC8844"; intensity: 1 }
        FluxusUi.LedIndicator { glowColor: "#00E6E6"; intensity: 0.8 }
    }

    Timer {
        interval: 150
        running: true
        onTriggered: window.contentItem.grabToImage(result => {
            if (!result.saveToFile("/tmp/fluxus-led-smoke.png")) {
                Qt.exit(1)
                return
            }
            Qt.exit(0)
        })
    }
}
