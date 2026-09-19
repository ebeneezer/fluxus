/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "../imports/de/idoc/fluxus/backend" as FluxusBackend
import "RateFormat.js" as RateFormat

PlasmoidItem {
    id: root

    readonly property string configuredNetworkInterface: {
        const configured = String(Plasmoid.configuration.networkInterface || "").trim();
        return configured.length > 0 ? configured : "all";
    }

    Plasmoid.title: i18n("Fluxus")
    Plasmoid.icon: "fluxus"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Fluxus — %1", networkSource.deviceName)
    toolTipSubText: !networkSource.valid ? networkSource.errorString
        : networkSource.diskSource
            ? i18n("Read %1 · Write %2", formatRate(networkSource.downloadBytesPerSecond),
                    formatRate(networkSource.uploadBytesPerSecond))
            : i18n("Download %1 · Upload %2", formatRate(networkSource.downloadBytesPerSecond),
                    formatRate(networkSource.uploadBytesPerSecond))

    function formatRate(bytesPerSecond) {
        return RateFormat.format(bytesPerSecond, networkSource.diskSource);
    }

    FluxusBackend.NetworkSource {
        id: networkSource
        interfaceName: root.configuredNetworkInterface
        framesPerSecond: Math.max(0.2, Math.min(30, Plasmoid.configuration.framesPerSecond || 1))
        active: root.visible
        // Upgrade legacy kernel names while their current drive is available.
        // Persist the identity so subsequent boots cannot select another SSD.
        onPersistentInterfaceNameChanged: {
            Qt.callLater(function() {
                if (diskSource && interfaceName === root.configuredNetworkInterface
                        && persistentInterfaceName !== root.configuredNetworkInterface)
                    Plasmoid.configuration.networkInterface = persistentInterfaceName;
            });
        }
    }

    compactRepresentation: fluxusRepresentation
    fullRepresentation: fluxusRepresentation

    Component {
        id: fluxusRepresentation

        Item {
            id: representation
            readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            readonly property real aspectRatio: 223 / 233
            readonly property int fallbackWidth: 223
            readonly property int fallbackHeight: 233
            readonly property real panelLengthFactor: Math.max(0.5, Math.min(10,
                Number(Plasmoid.configuration.panelLengthPercent || 100) / 100))
            readonly property int panelLengthPixels: Math.max(0, Math.min(2000,
                Number(Plasmoid.configuration.panelLengthPixels || 0)))
            readonly property real horizontalPanelWidth: Math.max(48,
                panelLengthPixels > 0 ? panelLengthPixels : height * aspectRatio * panelLengthFactor)
            readonly property real verticalPanelHeight: Math.max(48,
                panelLengthPixels > 0 ? panelLengthPixels : width / aspectRatio * panelLengthFactor)

            Layout.fillWidth: verticalPanel
            Layout.fillHeight: horizontalPanel
            Layout.minimumWidth: horizontalPanel ? horizontalPanelWidth : verticalPanel ? 0 : 96
            Layout.preferredWidth: horizontalPanel ? horizontalPanelWidth : fallbackWidth
            Layout.maximumWidth: horizontalPanel ? horizontalPanelWidth : Infinity
            Layout.minimumHeight: verticalPanel ? verticalPanelHeight : horizontalPanel ? 0 : 100
            Layout.preferredHeight: verticalPanel ? verticalPanelHeight : fallbackHeight
            Layout.maximumHeight: verticalPanel ? verticalPanelHeight : Infinity
            implicitWidth: fallbackWidth
            implicitHeight: fallbackHeight
            clip: true

            FluxusView {
                anchors.fill: parent
                source: networkSource
                configuration: Plasmoid.configuration
            }
        }
    }
}
