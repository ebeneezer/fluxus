/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import "../package/contents/ui" as FluxusUi

Window {
    id: window
    width: 120
    height: 40
    visible: true
    color: "#000000"

    Column {
        anchors.centerIn: parent
        spacing: 6
        Repeater {
            model: ["#BC8844", "#00E6E6"]
            Row {
                id: ledRow
                required property string modelData
                spacing: 8
                Repeater {
                    model: [0, 0.01, 0.25, 0.65, 1]
                    FluxusUi.LedIndicator {
                        required property real modelData
                        glowColor: ledRow.modelData
                        intensity: modelData
                    }
                }
            }
        }
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
