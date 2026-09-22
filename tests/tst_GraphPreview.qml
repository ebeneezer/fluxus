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
        config.previewScalePercent = 300;
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
        const hoverSize = Qt.size(dialog.width, dialog.height);
        const enlarged = findChild(dialog.contentItem, "previewView");
        verify(enlarged !== null);
        compare(enlarged.width, Math.ceil(miniature.width * preview.previewScale));
        compare(enlarged.height, Math.ceil(miniature.height * preview.previewScale));
        compare(enlarged.scale, 1);
        compare(enlarged.historyGraph, miniature.trafficGraph);
        compare(enlarged.trafficGraph.width, enlarged.width);
        verify(enlarged.trafficGraph.width > miniature.trafficGraph.width);
        preview.pin();
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
