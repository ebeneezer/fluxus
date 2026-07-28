/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtTest
import de.idoc.fluxus.backend 1.0
import "../package/contents/ui" as FluxusUi

TestCase {
    id: testCase

    name: "StatisticsOrder"
    width: 100
    height: 100
    when: windowShown

    QtObject {
        id: config
        property string backgroundColor: "#2D333C"
        property string gridColor: "#171B1E"
        property string uploadColor: "#BC8844"
        property string downloadColor: "#00E6E6"
        property string labelColor: "#FFFFFF"
        property string numericPlacement: "graph"
        property string numericPosition: "topLeft"
        property string numericFontFamily: "Monospace"
        property int numericFontSize: 15
        property bool autoNumericFontSize: false
        property bool splitDirections: false
        property int historySeconds: 60
        property bool uploadInverted: true
        property bool downloadInverted: false
        property string uploadStyle: "filled"
        property string downloadStyle: "line"
        property string gridMode: "off"
        property int gridLineCount: 6
        property bool showNumeric: true
        property bool showLeds: false
        property bool showInterfaceName: false
    }

    NetworkSource {
        id: source
    }

    FluxusUi.FluxusView {
        id: view
        anchors.fill: parent
        source: source
        configuration: config
    }

    function findByObjectName(item, name) {
        if (item.objectName === name)
            return item

        for (let index = 0; index < item.children.length; ++index) {
            const match = findByObjectName(item.children[index], name)
            if (match)
                return match
        }
        return null
    }

    function verifyUploadFirst(expected) {
        wait(0)
        const upload = findByObjectName(view, "uploadGraphStatistic")
        const download = findByObjectName(view, "downloadGraphStatistic")
        verify(upload !== null)
        verify(download !== null)
        compare(upload.y < download.y, expected)
    }

    function test_orderFollowsGraph() {
        // Overlay: download is drawn from the upper baseline.
        config.splitDirections = false
        config.uploadInverted = false
        config.downloadInverted = true
        verifyUploadFirst(false)

        // Split: upload occupies the upper half regardless of its inversion.
        config.splitDirections = true
        verifyUploadFirst(true)

        // Overlay: upload is drawn from the upper baseline.
        config.splitDirections = false
        config.uploadInverted = true
        config.downloadInverted = false
        verifyUploadFirst(true)
    }
}
