/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import "../package/contents/ui" as FluxusUi

Window {
    id: window

    width: 521
    height: 305
    visible: true
    color: "#171822"

    FluxusUi.ConfigColors {
        anchors.fill: parent
        cfg_backgroundColor: "#14161A"
    }

    Timer {
        interval: 150
        running: true
        onTriggered: window.contentItem.grabToImage(result => {
            if (!result.saveToFile("/tmp/fluxus-color-config-smoke.png")) {
                Qt.exit(1)
                return
            }
            Qt.exit(0)
        })
    }
}
