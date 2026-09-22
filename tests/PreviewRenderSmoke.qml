/* SPDX-License-Identifier: GPL-2.0-or-later */
import QtQuick
import QtQuick.Window
import de.idoc.fluxus.backend 1.0
import "../package/contents/ui" as FluxusUi

Window {
    id: window
    width: 970
    height: 565
    visible: true
    color: "#24262b"

    QtObject {
        id: config
        property string backgroundColor: "#14161a"
        property string gridColor: "#555555"
        property string numericFontFamily: "3270 Nerd Font Propo Cond"
        property string numericPosition: "bottomLeft"
        property string sourceLabel: "sys"
        property bool downloadInverted: true
        property bool uploadInverted: false
        property string downloadStyle: "filled"
        property string uploadStyle: "filled"
    }
    NetworkSource { id: source; active: false; framesPerSecond: 3 }
    Text { x: 20; y: 10; text: "Miniature"; color: "white" }
    FluxusUi.FluxusView {
        id: miniature
        x: 20; y: 35
        width: 100; height: 70
        source: source
        configuration: config
    }
    Text { x: 20; y: 115; text: "300% — native rendering"; color: "white" }
    FluxusUi.FluxusView {
        x: 20; y: 140
        width: 300; height: 210
        source: source
        configuration: config
        historyGraph: miniature.trafficGraph
    }
    Text { x: 350; y: 115; text: "600% — native rendering"; color: "white" }
    FluxusUi.FluxusView {
        x: 350; y: 140
        width: 600; height: 420
        source: source
        configuration: config
        historyGraph: miniature.trafficGraph
    }
    Timer {
        interval: 100
        running: true
        onTriggered: {
            for (let i = 0; i < 180; ++i) {
                source.sampled(500 + Math.pow(Math.sin(i / 12), 8) * 32000,
                               300 + Math.pow(Math.cos(i / 17), 6) * 14000);
            }
            capture.start();
        }
    }
    Timer {
        id: capture
        interval: 200
        onTriggered: window.contentItem.grabToImage(result => {
            Qt.exit(result.saveToFile("/tmp/fluxus-preview-render.png") ? 0 : 1);
        })
    }
}
