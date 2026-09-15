/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    required property string directionName
    required property color directionColor
    required property string rateText
    required property real ledIntensity
    required property color labelColor
    required property bool showLed
    required property string numericFontFamily
    required property int numericFontSize
    required property bool autoNumericFontSize
    property int fontWeight: Font.Normal

    Row {
        id: directionHeader
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 2
        height: Math.max(directionLed.visible ? directionLed.height : 0, directionText.implicitHeight)

        LedIndicator {
            id: directionLed
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showLed
            glowColor: root.directionColor
            intensity: root.ledIntensity
        }

        Text {
            id: directionText
            anchors.verticalCenter: parent.verticalCenter
            text: root.directionName
            color: root.labelColor
            font.family: "sans-serif"
            font.pixelSize: Math.max(7, Math.min(9, Math.floor(root.height * 0.34)))
            font.weight: root.fontWeight
        }
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: directionHeader.bottom
        anchors.bottom: parent.bottom
        text: root.rateText
        color: root.directionColor
        font.family: root.numericFontFamily
        font.pixelSize: root.autoNumericFontSize
            ? Math.max(6, Math.floor(height * 0.92))
            : Math.max(6, Math.min(72, root.numericFontSize))
        font.weight: root.fontWeight
        fontSizeMode: root.autoNumericFontSize ? Text.HorizontalFit : Text.FixedSize
        minimumPixelSize: 6
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
