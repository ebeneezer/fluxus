/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import de.idoc.fluxus.backend 1.0

Window {
    id: window

    width: 74
    height: 50
    visible: true
    color: "#000000"

    NetworkSource {
        id: source
        framesPerSecond: 0.5
    }

    TrafficGraph {
        id: graph
        anchors.fill: parent
        source: source
        historySeconds: 120
        gridMode: "off"
        uploadStyle: "bars"
        downloadStyle: "bars"
        uploadInverted: false
        downloadInverted: false
        backgroundColor: "#000000"
        uploadColor: "#BC8844"
        downloadColor: "#00E6E6"
    }

    function capture(path, continuation) {
        graph.grabToImage(result => {
            if (!result.saveToFile(path)) {
                Qt.exit(1)
                return
            }
            continuation()
        })
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            for (let index = 0; index < 59; ++index) source.sampled(0, 0)
            source.sampled(0, 1000)
            window.capture("/tmp/fluxus-history-0.png", () => {
                source.sampled(0, 0)
                Qt.callLater(() => window.capture("/tmp/fluxus-history-1.png", () => {
                    source.sampled(0, 0)
                    Qt.callLater(() => window.capture("/tmp/fluxus-history-2.png", () => Qt.exit(0)))
                }))
            })
        }
    }
}
