/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import de.idoc.fluxus.backend 1.0

Window {
    width: 223
    height: 179
    visible: false

    NetworkSource {
        id: source
        active: true
        framesPerSecond: 30
    }

    NetworkSource {
        id: slowSource
        framesPerSecond: 0.2
    }

    TrafficGraph {
        anchors.fill: parent
        source: source
        historySeconds: 900
        gridMode: "auto"
    }

    Timer {
        interval: 350
        running: true
        onTriggered: {
            if (!source.valid || source.interfaces.length < 2
                    || Math.abs(source.framesPerSecond - 30) > 0.001
                    || Math.abs(slowSource.framesPerSecond - 0.2) > 0.001) {
                console.error("Fluxus backend smoke test failed:", source.errorString)
                Qt.exit(1)
                return
            }
            console.info("Fluxus backend smoke test:", source.interfaces.length,
                         "interfaces, down", source.downloadBytesPerSecond,
                         "up", source.uploadBytesPerSecond)
            Qt.exit(0)
        }
    }
}
