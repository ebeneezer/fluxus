/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import "../imports/de/idoc/fluxus/backend" as FluxusBackend
import "RateFormat.js" as RateFormat

Item {
    id: root

    required property FluxusBackend.NetworkSource source
    required property var configuration

    readonly property bool diskSource: source.diskSource

    readonly property color plotColor: configuration.backgroundColor || "#2D333C"
    readonly property color gridColor: configuration.gridColor || "#171B1E"
    readonly property color uploadColor: configuration.uploadColor || "#BC8844"
    readonly property color downloadColor: configuration.downloadColor || "#00E6E6"
    readonly property color labelColor: configuration.labelColor || "#FFFFFF"
    readonly property int fontWeight: configuration.fontWeight || Font.Normal
    readonly property bool topReadout: (configuration.numericPosition || "topLeft").startsWith("top")
    readonly property bool leftReadout: (configuration.numericPosition || "topLeft").endsWith("Left")
    readonly property bool statisticsBelowLeds: configuration.showNumeric !== false
                                                   && (configuration.numericPlacement || "graph") === "status"
    readonly property bool splitDirections: configuration.splitDirections === true
    readonly property bool uploadInverted: configuration.uploadInverted !== false
    readonly property bool downloadInverted: configuration.downloadInverted === true
    // In split mode the backend always paints upload in the upper half. In
    // overlay mode, put the direction whose baseline is at the top first.
    readonly property bool uploadStatisticFirst: splitDirections
                                                  || uploadInverted
                                                  || !downloadInverted

    implicitWidth: 223
    implicitHeight: 233

    function formatRate(bytesPerSecond) {
        return RateFormat.format(bytesPerSecond, root.diskSource);
    }

    function ledIntensity(bytesPerSecond) {
        const bits = Math.max(0, Number(bytesPerSecond) || 0) * 8;
        return Math.min(1, Math.log2(1 + bits) / 22);
    }

    FluxusBackend.TrafficGraph {
        id: graph
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusLine.top
        source: root.source
        historySeconds: root.configuration.historySeconds || 60
        splitDirections: root.splitDirections
        uploadInverted: root.uploadInverted
        downloadInverted: root.downloadInverted
        uploadStyle: root.configuration.uploadStyle || "filled"
        downloadStyle: root.configuration.downloadStyle || "line"
        gridMode: root.configuration.gridMode || "auto"
        gridLineCount: root.configuration.gridLineCount || 6
        backgroundColor: root.plotColor
        gridColor: root.gridColor
        uploadColor: root.uploadColor
        downloadColor: root.downloadColor

        Column {
            id: rates
            visible: root.configuration.showNumeric !== false && !root.statisticsBelowLeds
            width: Math.max(0, graph.width - 6)
            spacing: -2
            x: 3
            y: root.topReadout ? 2 : graph.height - height - 2

            Repeater {
                model: 2

                Item {
                    required property int index
                    readonly property bool uploadDirection: index === 0
                        ? root.uploadStatisticFirst : !root.uploadStatisticFirst

                    objectName: uploadDirection
                        ? "uploadGraphStatistic" : "downloadGraphStatistic"
                    width: rates.width
                    height: rateLabel.implicitHeight + 2

                    Rectangle {
                        width: Math.min(parent.width, rateLabel.paintedWidth + 4)
                        height: parent.height
                        x: root.leftReadout ? 0 : parent.width - width
                        color: Qt.rgba(0, 0, 0, 0.58)
                        radius: 2
                    }

                    Text {
                        id: rateLabel
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        text: root.formatRate(parent.uploadDirection
                            ? root.source.uploadBytesPerSecond
                            : root.source.downloadBytesPerSecond)
                        color: parent.uploadDirection ? root.uploadColor : root.downloadColor
                        font.family: root.configuration.numericFontFamily || "Monospace"
                        font.pixelSize: root.configuration.autoNumericFontSize === true
                            ? Math.max(6, Math.floor(graph.height * 0.24))
                            : Math.max(6, Math.min(72, root.configuration.numericFontSize || 15))
                        font.weight: root.fontWeight
                        fontSizeMode: root.configuration.autoNumericFontSize === true
                            ? Text.HorizontalFit : Text.FixedSize
                        minimumPixelSize: 6
                        horizontalAlignment: root.leftReadout ? Text.AlignLeft : Text.AlignRight
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        style: Text.Normal
                    }
                }
            }
        }
    }

    Item {
        id: statusLine
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.statisticsBelowLeds
            ? Math.max(30, Math.min(42, root.height * 0.40))
            : Math.max(14, Math.min(32, root.height * 0.19))

        Text {
            id: interfaceLabel
            anchors.left: parent.left
            anchors.right: !root.statisticsBelowLeds && ledBank.visible ? ledBank.left : parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 2
            anchors.rightMargin: 4
            height: root.statisticsBelowLeds
                ? (visible ? Math.max(8, Math.min(13, Math.floor(statusLine.height * 0.30))) : 0)
                : statusLine.height
            visible: root.configuration.showInterfaceName !== false
            text: String(root.configuration.sourceLabel || "").trim() || root.source.deviceName
            color: root.labelColor
            font.family: "sans-serif"
            font.pixelSize: root.statisticsBelowLeds
                ? Math.max(7, Math.floor(height * 0.78))
                : Math.max(8, Math.min(22, Math.floor(statusLine.height * 0.72)))
            font.weight: root.fontWeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideMiddle
            maximumLineCount: 1
            style: Text.Normal
        }

        Row {
            id: ledBank
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 2
            anchors.bottomMargin: 2
            spacing: 2
            visible: !root.statisticsBelowLeds && root.configuration.showLeds !== false

            LedIndicator {
                glowColor: root.uploadColor
                intensity: root.ledIntensity(root.source.uploadBytesPerSecond)
            }
            LedIndicator {
                glowColor: root.downloadColor
                intensity: root.ledIntensity(root.source.downloadBytesPerSecond)
            }
        }

        Row {
            id: statusStatistics
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: interfaceLabel.top
            visible: root.statisticsBelowLeds

            StatusStatistic {
                width: statusStatistics.width / 2
                height: statusStatistics.height
                directionName: root.diskSource ? "write" : "up"
                directionColor: root.uploadColor
                rateText: root.formatRate(root.source.uploadBytesPerSecond).replace(" ", "")
                ledIntensity: root.ledIntensity(root.source.uploadBytesPerSecond)
                labelColor: root.labelColor
                showLed: root.configuration.showLeds !== false
                numericFontFamily: root.configuration.numericFontFamily || "Monospace"
                numericFontSize: root.configuration.numericFontSize || 15
                fontWeight: root.fontWeight
                autoNumericFontSize: root.configuration.autoNumericFontSize === true
            }

            StatusStatistic {
                width: statusStatistics.width / 2
                height: statusStatistics.height
                directionName: root.diskSource ? "read" : "down"
                directionColor: root.downloadColor
                rateText: root.formatRate(root.source.downloadBytesPerSecond).replace(" ", "")
                ledIntensity: root.ledIntensity(root.source.downloadBytesPerSecond)
                labelColor: root.labelColor
                showLed: root.configuration.showLeds !== false
                numericFontFamily: root.configuration.numericFontFamily || "Monospace"
                numericFontSize: root.configuration.numericFontSize || 15
                fontWeight: root.fontWeight
                autoNumericFontSize: root.configuration.autoNumericFontSize === true
            }
        }
    }
}
