/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

Item {
    id: root

    required property FluxusView miniature
    required property var configuration
    property int location: PlasmaCore.Types.Floating
    property bool hovered: false
    property bool pinned: false
    property bool requested: false
    property bool suppressed: false
    readonly property bool opened: dialog.visible
    readonly property bool keepPanelOpen: opened || closeGrace.running
    readonly property real previewScale: Math.max(0.1, Math.min(
        Math.max(150, Math.min(600, configuration.previewScalePercent || 300)) / 100,
        (miniature.Screen.desktopAvailableWidth - 80) / Math.max(1, miniature.width),
        (miniature.Screen.desktopAvailableHeight - 112) / Math.max(1, miniature.height)))

    function pin() {
        showTimer.stop();
        hideTimer.stop();
        suppressed = false;
        pinned = true;
        requested = true;
        closeGrace.stop();
    }

    function dismiss(fromCloseButton = false) {
        showTimer.stop();
        hideTimer.stop();
        // Plasma immediately restores auto-hide when a transient window closes.
        // Keep the panel available briefly while the pointer returns from Close.
        // Start the hold BEFORE hiding the window to avoid an auto-hide pulse.
        if (fromCloseButton) closeGrace.restart();
        else closeGrace.stop();
        requested = false;
        pinned = false;
        suppressed = hovered;
    }

    function resizeToPercent(percent) {
        configuration.previewScalePercent = Math.round(Math.max(150, Math.min(600, percent)));
    }

    onHoveredChanged: {
        if (hovered) {
            closeGrace.stop();
            hideTimer.stop();
            if (!suppressed && !pinned) showTimer.restart();
        } else {
            showTimer.stop();
            suppressed = false;
            if (!pinned) hideTimer.restart();
        }
    }

    Timer {
        id: closeGrace
        interval: 1500
    }

    Timer {
        id: showTimer
        interval: 350
        onTriggered: if (root.hovered && !root.suppressed) root.requested = true
    }

    Timer {
        id: hideTimer
        interval: 180
        onTriggered: if (!root.pinned && !root.hovered && !popupHover.hovered) root.requested = false
    }

    PlasmaCore.Dialog {
        id: dialog
        objectName: "graphPreviewDialog"
        visualParent: root.miniature
        location: root.location
        type: PlasmaCore.Dialog.AppletPopup
        flags: Qt.Tool | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
        hideOnWindowDeactivate: false
        visible: root.requested
        title: root.miniature.source.deviceName

        mainItem: Item {
            id: content
            readonly property int padding: 8
            readonly property int headerHeight: 32
            width: Math.ceil(root.miniature.width * root.previewScale) + padding * 2
            height: Math.ceil(root.miniature.height * root.previewScale) + padding * 2 + headerHeight

            HoverHandler {
                id: popupHover
                onHoveredChanged: {
                    if (hovered) hideTimer.stop();
                    else if (!root.pinned && !root.hovered) hideTimer.restart();
                }
            }

            QQC2.Label {
                anchors.left: parent.left
                anchors.leftMargin: content.padding
                anchors.right: closeButton.left
                height: content.headerHeight
                text: String(root.configuration.sourceLabel || "").trim()
                    || root.miniature.source.deviceName
                elide: Text.ElideMiddle
                verticalAlignment: Text.AlignVCenter
            }

            QQC2.ToolButton {
                id: closeButton
                objectName: "previewCloseButton"
                anchors.right: parent.right
                anchors.rightMargin: root.location === PlasmaCore.Types.BottomEdge ? 22 : 0
                width: content.headerHeight
                height: content.headerHeight
                visible: root.pinned
                icon.name: "window-close"
                text: qsTr("Close")
                display: QQC2.AbstractButton.IconOnly
                // Finish delivering the accepted release before unmapping its window.
                onClicked: Qt.callLater(function() { root.dismiss(true); })
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.text: text
            }

            Loader {
                id: viewLoader
                x: content.padding
                y: content.padding + content.headerHeight
                active: dialog.visible
                sourceComponent: FluxusView {
                    objectName: "previewView"
                    width: Math.ceil(root.miniature.width * root.previewScale)
                    height: Math.ceil(root.miniature.height * root.previewScale)
                    source: root.miniature.source
                    configuration: root.configuration
                    historyGraph: root.miniature.trafficGraph
                    clip: true
                }
            }

            // Grow away from the panel so the handle follows the pointer even
            // when Plasma repositions the popup against a bottom/right edge.
            MouseArea {
                id: resizeHandle
                objectName: "previewResizeHandle"
                readonly property bool leftCorner: root.location === PlasmaCore.Types.RightEdge
                readonly property bool topCorner: root.location === PlasmaCore.Types.BottomEdge
                property point startPointer
                property real startScale: 1
                width: 22
                height: 22
                x: leftCorner ? 0 : parent.width - width
                y: topCorner ? 0 : parent.height - height
                visible: root.pinned
                cursorShape: leftCorner !== topCorner ? Qt.SizeBDiagCursor : Qt.SizeFDiagCursor
                preventStealing: true
                onPressed: mouse => {
                    startPointer = mapToGlobal(mouse.x, mouse.y);
                    startScale = root.previewScale;
                }
                onPositionChanged: mouse => {
                    if (!pressed) return;
                    const point = mapToGlobal(mouse.x, mouse.y);
                    const dx = (point.x - startPointer.x) * (leftCorner ? -1 : 1);
                    const dy = (point.y - startPointer.y) * (topCorner ? -1 : 1);
                    const w = root.miniature.width;
                    const h = root.miniature.height;
                    const delta = (dx * w + dy * h) / Math.max(1, w * w + h * h);
                    root.resizeToPercent((startScale + delta) * 100);
                }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: "transform-scale"
                    opacity: 0.7
                }
            }
        }
    }
}
