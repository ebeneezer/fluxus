/* SPDX-License-Identifier: GPL-2.0-or-later */
import QtQuick
import QtTest
import de.idoc.fluxus.backend 1.0
import org.kde.plasma.core as PlasmaCore
import "../package/contents/ui" as FluxusUi

TestCase {
    id: testCase
    name: "GraphPreview"
    width: 160
    height: 100
    when: windowShown

    QtObject {
        id: config
        property int previewScalePercent: 300
        property int numericFontSize: 15
        property string numericPlacement: "graph"
        property bool showLeds: true
        property bool showNumeric: true
        property bool showInterfaceName: true
        property string sourceLabel: "Preview test"
    }
    NetworkSource { id: source; active: false }
    FluxusUi.FluxusView {
        id: miniature
        width: 100
        height: 80
        source: source
        configuration: config
    }
    FluxusUi.GraphPreview {
        id: preview
        miniature: miniature
        configuration: config
    }

    function init() {
        preview.hovered = false;
        preview.dismiss();
        miniature.width = 100;
        miniature.height = 80;
        config.previewScalePercent = 300;
        config.numericPlacement = "graph";
        config.showLeds = true;
        config.showNumeric = true;
        config.showInterfaceName = true;
        preview.location = PlasmaCore.Types.Floating;
    }

    function cleanup() {
        preview.hovered = false;
        preview.dismiss();
    }

    function test_hoverPinClose() {
        preview.hovered = true;
        verify(!preview.opened);
        tryCompare(preview, "opened", true);
        const dialog = findChild(preview, "graphPreviewDialog");
        verify((dialog.flags & Qt.WindowTransparentForInput) !== 0);
        const hoverSize = Qt.size(dialog.width, dialog.height);
        const enlarged = findChild(dialog.contentItem, "previewView");
        verify(enlarged !== null);
        compare(enlarged.width, Math.ceil(miniature.width * preview.previewScale));
        compare(enlarged.height, preview.previewViewHeight);
        verify(enlarged.height < preview.nominalViewHeight);
        compare(Math.round(dialog.mainItem.height), Math.ceil(enlarged.height) + 48);
        compare(miniature.hideInterfaceLabel, false);
        compare(enlarged.hideInterfaceLabel, true);
        compare(findChild(enlarged, "interfaceLabel").visible, false);
        compare(findChild(dialog.contentItem, "previewHeaderLabel").text, "Preview test");
        compare(findChild(enlarged, "statusLine").height, 11);
        compare(findChild(enlarged, "ledBank").visible, true);
        compare(enlarged.scale, 1);
        compare(enlarged.historyGraph, miniature.trafficGraph);
        compare(miniature.trafficGraph.showGridLabels, false);
        compare(enlarged.trafficGraph.showGridLabels, true);
        compare(enlarged.trafficGraph.width, enlarged.width);
        verify(enlarged.trafficGraph.width > miniature.trafficGraph.width);
        const miniatureRate = findChild(miniature, "graphRateLabel");
        const previewRate = findChild(enlarged, "graphRateLabel");
        verify(miniatureRate !== null && previewRate !== null);
        verify(previewRate.font.pixelSize > miniatureRate.font.pixelSize);
        verify(previewRate.font.pixelSize < miniatureRate.font.pixelSize * preview.previewScale);
        preview.pin();
        verify((dialog.flags & Qt.WindowTransparentForInput) === 0);
        compare(Qt.size(dialog.width, dialog.height), hoverSize);
        preview.hovered = false;
        wait(250);
        verify(preview.opened);
        verify(preview.pinned);
        const close = findChild(dialog.contentItem, "previewCloseButton");
        verify(close.visible);
        mouseClick(close);
        tryCompare(preview, "opened", false);
        verify(preview.keepPanelOpen, "Close must not release the panel during the click");
    }

    function test_compactStatusPlacement() {
        config.numericPlacement = "status";
        preview.pin();
        const dialog = findChild(preview, "graphPreviewDialog");
        const enlarged = findChild(dialog.contentItem, "previewView");
        const status = findChild(enlarged, "statusLine");
        const statistics = findChild(enlarged, "statusStatistics");
        compare(findChild(enlarged, "interfaceLabel").visible, false);
        verify(enlarged.height < preview.nominalViewHeight);
        verify(status.height > 11);
        compare(statistics.height, status.height);
        compare(Math.round(dialog.mainItem.height), Math.ceil(enlarged.height) + 48);

        config.numericPlacement = "graph";
        config.showLeds = false;
        tryCompare(status, "height", 0);
        compare(enlarged.trafficGraph.height, enlarged.height);
        compare(Math.round(dialog.mainItem.height), Math.ceil(enlarged.height) + 48);
    }

    function test_unavailableGeometryKeepsPreviewSized() {
        compare(preview.calculatePreviewScale(undefined, NaN), 3);
        compare(preview.calculatePreviewScale(0, 0), 3);
        miniature.width = 0;
        miniature.height = 0;
        preview.pin();
        const dialog = findChild(preview, "graphPreviewDialog");
        const enlarged = findChild(dialog.contentItem, "previewView");
        verify(dialog.width > 0 && dialog.height > 0);
        verify(enlarged.width > 0 && enlarged.height > 0);
    }

    function test_closeKeepsPanelAvailable() {
        preview.pin();
        const dialog = findChild(preview, "graphPreviewDialog");
        const close = findChild(dialog.contentItem, "previewCloseButton");
        mousePress(close);
        verify(preview.opened, "The press must be consumed by the button");
        mouseRelease(close);
        tryCompare(preview, "opened", false);
        verify(preview.keepPanelOpen);
        wait(250);
        verify(preview.keepPanelOpen, "The pointer must have time to return to the panel");
        tryCompare(preview, "keepPanelOpen", false, 2000);
        verify(!preview.opened, "The grace period must not reopen the preview");
    }

    function test_returnToPanelEndsCloseGrace() {
        preview.pin();
        preview.dismiss(true);
        verify(preview.keepPanelOpen);
        preview.hovered = true;
        verify(!preview.keepPanelOpen, "Normal panel hover takes over after returning");
        preview.hovered = false;
        wait(400);
        verify(!preview.opened);
        verify(!preview.keepPanelOpen);
    }

    function test_hoverDismissAndSuppression() {
        preview.hovered = true;
        tryCompare(preview, "opened", true);
        preview.hovered = false;
        tryCompare(preview, "opened", false);
        preview.hovered = true;
        preview.pin();
        preview.dismiss();
        wait(450);
        verify(!preview.opened);
        preview.hovered = false;
        preview.hovered = true;
        tryCompare(preview, "opened", true);
    }

    function test_contextMenuDismissKeepsPanelAvailable() {
        preview.hovered = true;
        tryCompare(preview, "opened", true);
        preview.dismissForContextMenu();
        verify(preview.keepPanelOpen);
        tryCompare(preview, "opened", false);
        verify(preview.keepPanelOpen);
        wait(250);
        verify(!preview.opened);
        verify(preview.keepPanelOpen);
    }

    function test_hoverInputPassesThroughOverlappingPreview() {
        preview.hovered = true;
        tryCompare(preview, "opened", true);
        const dialog = findChild(preview, "graphPreviewDialog");
        verify((dialog.flags & Qt.WindowTransparentForInput) !== 0);
        preview.hovered = false;
        verify((dialog.flags & Qt.WindowTransparentForInput) === 0);
    }

    function test_sharedSizeAndDrag_data() {
        return [
            { tag: "desktop", location: PlasmaCore.Types.Floating, dx: 25, dy: 20 },
            { tag: "bottom", location: PlasmaCore.Types.BottomEdge, dx: 25, dy: -20 },
            { tag: "top", location: PlasmaCore.Types.TopEdge, dx: 25, dy: 20 },
            { tag: "left", location: PlasmaCore.Types.LeftEdge, dx: 25, dy: 20 },
            { tag: "right", location: PlasmaCore.Types.RightEdge, dx: -25, dy: 20 }
        ];
    }

    function test_sharedSizeAndDrag(data) {
        preview.location = data.location;
        preview.pin();
        const dialog = findChild(preview, "graphPreviewDialog");
        const grip = findChild(dialog.contentItem, "previewResizeHandle");
        const before = dialog.width;
        mousePress(grip, 10, 10);
        mouseMove(grip, 10 + data.dx, 10 + data.dy);
        mouseRelease(grip, 10, 10);
        verify(config.previewScalePercent > 300);
        verify(dialog.width > before);
        const size = Qt.size(dialog.width, dialog.height);
        preview.dismiss();
        preview.hovered = true;
        tryCompare(preview, "opened", true);
        compare(Qt.size(dialog.width, dialog.height), size);
        preview.resizeToPercent(900);
        compare(config.previewScalePercent, 600);
        preview.resizeToPercent(50);
        compare(config.previewScalePercent, 150);
    }
}
