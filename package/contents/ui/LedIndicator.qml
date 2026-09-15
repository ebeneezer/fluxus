/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    required property color glowColor
    property real intensity: 0
    readonly property real level: Math.max(0, Math.min(1, intensity))

    width: 10
    height: 7
    // Even a small transfer should visibly light the LED. Keep the idle body
    // dim, while retaining a little brightness modulation during activity.
    opacity: level > 0 ? 0.80 + 0.20 * Math.sqrt(level) : 0.16

    // The original GKrellM indicator has only a one-pixel halo.  Keeping the
    // body square and opaque is what makes it read as an LED at panel sizes.
    Rectangle {
        anchors.fill: parent
        radius: 1
        antialiasing: false
        color: Qt.rgba(root.glowColor.r, root.glowColor.g, root.glowColor.b, 0.40)
    }

    Rectangle {
        anchors.centerIn: parent
        width: 8
        height: 5
        radius: 0
        antialiasing: false
        color: Qt.lighter(root.glowColor, 1.3)
        border.width: 1
        border.color: Qt.darker(root.glowColor, 1.3)
    }

    Rectangle {
        x: 3
        y: 2
        width: 4
        height: 1
        radius: 0
        antialiasing: false
        color: Qt.rgba(1, 1, 1, 0.75)
    }
}
