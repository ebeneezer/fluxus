/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import "../imports/de/idoc/fluxus/backend" as FluxusBackend

KCM.SimpleKCM {
    id: root

    readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inPanel: horizontalPanel || verticalPanel

    readonly property bool diskSource: cfg_networkInterface.startsWith("disk:")
    property string cfg_sourceLabel: ""
    property string cfg_networkInterface: "all"
    property real cfg_framesPerSecond: 1
    property int cfg_historySeconds: 60
    property int cfg_panelLengthPercent: 100
    property int cfg_panelLengthPixels: 0
    property bool cfg_splitDirections: false
    property bool cfg_uploadInverted: true
    property bool cfg_downloadInverted: false
    property string cfg_uploadStyle: "filled"
    property string cfg_downloadStyle: "line"
    property string cfg_gridMode: "auto"
    property int cfg_gridLineCount: 6
    property bool cfg_showNumeric: true
    property string cfg_numericPlacement: "graph"
    property string cfg_numericPosition: "topLeft"
    property string cfg_numericFontFamily: "Monospace"
    property int cfg_numericFontSize: 15
    property int cfg_fontWeight: Font.Normal
    property bool cfg_autoNumericFontSize: false
    property bool cfg_showLeds: true
    property bool cfg_showInterfaceName: true

    property string cfg_sourceLabelDefault: ""
    property string cfg_networkInterfaceDefault: "all"
    property real cfg_framesPerSecondDefault: 1
    property int cfg_historySecondsDefault: 60
    property int cfg_panelLengthPercentDefault: 100
    property int cfg_panelLengthPixelsDefault: 0
    property bool cfg_splitDirectionsDefault: false
    property bool cfg_uploadInvertedDefault: true
    property bool cfg_downloadInvertedDefault: false
    property string cfg_uploadStyleDefault: "filled"
    property string cfg_downloadStyleDefault: "line"
    property string cfg_gridModeDefault: "auto"
    property int cfg_gridLineCountDefault: 6
    property bool cfg_showNumericDefault: true
    property string cfg_numericPlacementDefault: "graph"
    property string cfg_numericPositionDefault: "topLeft"
    property string cfg_numericFontFamilyDefault: "Monospace"
    property int cfg_numericFontSizeDefault: 15
    property int cfg_fontWeightDefault: Font.Normal
    property bool cfg_autoNumericFontSizeDefault: false
    property bool cfg_showLedsDefault: true
    property bool cfg_showInterfaceNameDefault: true

    readonly property var styleChoices: [
        { text: i18n("Line"), value: "line" },
        { text: i18n("Filled"), value: "filled" },
        { text: i18n("Bar graph"), value: "bars" }
    ]
    readonly property var positionChoices: [
        { text: i18n("Top left"), value: "topLeft" },
        { text: i18n("Top right"), value: "topRight" },
        { text: i18n("Bottom left"), value: "bottomLeft" },
        { text: i18n("Bottom right"), value: "bottomRight" }
    ]
    readonly property var placementChoices: [
        { text: i18n("In graph"), value: "graph" },
        { text: i18n("Below activity LEDs"), value: "status" }
    ]
    readonly property var gridChoices: [
        { text: i18n("Off"), value: "off" },
        { text: i18n("Fixed line count"), value: "fixed" },
        { text: i18n("Automatic decades"), value: "auto" }
    ]
    readonly property var rateChoices: [
        { rate: 0.2, text: i18n("1 frame / 5 s") },
        { rate: 0.25, text: i18n("1 frame / 4 s") },
        { rate: 1 / 3, text: i18n("1 frame / 3 s") },
        { rate: 0.5, text: i18n("1 frame / 2 s") },
        { rate: 1, text: i18n("1 fps") },
        { rate: 2, text: i18n("2 fps") },
        { rate: 3, text: i18n("3 fps") },
        { rate: 5, text: i18n("5 fps") },
        { rate: 10, text: i18n("10 fps") },
        { rate: 15, text: i18n("15 fps") },
        { rate: 20, text: i18n("20 fps") },
        { rate: 25, text: i18n("25 fps") },
        { rate: 30, text: i18n("30 fps") }
    ]
    readonly property var fontFamilies: Qt.fontFamilies().slice().sort((left, right) => left.localeCompare(right))
    readonly property var fontWeightChoices: [
        { text: i18n("Light"), value: Font.Light },
        { text: i18n("Normal"), value: Font.Normal },
        { text: i18n("Medium"), value: Font.Medium },
        { text: i18n("Bold"), value: Font.Bold }
    ]

    signal configurationChanged

    function indexOfValue(model, value) {
        for (let index = 0; index < model.length; ++index) {
            if (model[index].value === value) return index;
        }
        return 0;
    }

    function closestRateIndex(rate) {
        let result = 0;
        let distance = Number.POSITIVE_INFINITY;
        for (let index = 0; index < rateChoices.length; ++index) {
            const candidateDistance = Math.abs(rateChoices[index].rate - Number(rate));
            if (candidateDistance < distance) {
                result = index;
                distance = candidateDistance;
            }
        }
        return result;
    }

    function syncInterface() {
        const index = interfaceCombo.indexOfValue(cfg_networkInterface);
        // Plasma injects cfg_* values asynchronously.  Do not replace a saved
        // interface with the first model entry while its value or the device
        // list is still arriving.
        interfaceCombo.currentIndex = index;
    }

    function durationText(seconds) {
        const bounded = Math.max(10, Math.min(900, Math.round(seconds)));
        if (bounded < 60) return i18n("%1 s", bounded);
        const minutes = Math.floor(bounded / 60);
        const remainder = bounded % 60;
        return remainder === 0
            ? i18np("1 min", "%1 min", minutes)
            : i18n("%1 min %2 s", minutes, remainder);
    }

    function durationValue(text) {
        const value = String(text).trim().toLowerCase();
        const minutes = /([0-9]+)\s*(?:min|m)/.exec(value);
        const seconds = /([0-9]+)\s*(?:s|sec)/.exec(value);
        if (minutes || seconds) {
            return Math.max(10, Math.min(900,
                (minutes ? Number(minutes[1]) * 60 : 0) + (seconds ? Number(seconds[1]) : 0)));
        }
        const numeric = Number.parseInt(value, 10);
        return Number.isFinite(numeric) ? Math.max(10, Math.min(900, numeric)) : 60;
    }

    FluxusBackend.NetworkSource {
        id: interfaceSource
        active: false
        Component.onCompleted: refreshInterfaces()
        onSourceChoicesChanged: Qt.callLater(root.syncInterface)
    }

    Timer {
        interval: 5000
        running: root.visible
        repeat: true
        onTriggered: interfaceSource.refreshInterfaces()
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.ComboBox {
            id: interfaceCombo
            objectName: "measurementSourceCombo"
            Kirigami.FormData.label: i18n("Measurement source:")
            model: interfaceSource.sourceChoices.map(choice => ({
                value: choice.value,
                text: choice.kind === "disk" ? i18n("Drive: %1", choice.name)
                    : choice.value === "all" ? i18n("Network: all interfaces")
                    : i18n("Network: %1", choice.name)
            }))
            textRole: "text"
            valueRole: "value"
            displayText: currentIndex >= 0 ? currentText : root.cfg_networkInterface
            onActivated: {
                root.cfg_networkInterface = currentValue;
                root.configurationChanged();
            }
            Component.onCompleted: Qt.callLater(root.syncInterface)
        }

        QQC2.TextField {
            Kirigami.FormData.label: i18n("Source label:")
            placeholderText: i18n("Automatic device name")
            text: root.cfg_sourceLabel
            onTextEdited: { root.cfg_sourceLabel = text; root.configurationChanged(); }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Update rate:")
            QQC2.Slider {
                id: frameSlider
                Layout.fillWidth: true
                from: 0
                to: root.rateChoices.length - 1
                stepSize: 1
                value: root.closestRateIndex(root.cfg_framesPerSecond)
                onMoved: {
                    root.cfg_framesPerSecond = root.rateChoices[Math.round(value)].rate;
                    root.configurationChanged();
                }
            }
            QQC2.Label {
                text: root.rateChoices[Math.round(frameSlider.value)].text
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: 112
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("History:")
            from: 10
            to: 900
            stepSize: 10
            value: root.cfg_historySeconds
            editable: true
            textFromValue: function(value, locale) { return root.durationText(value); }
            valueFromText: function(text, locale) { return root.durationValue(text); }
            onValueModified: { root.cfg_historySeconds = value; root.configurationChanged(); }
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Panel size:")
            text: i18n("Fixed length")
            enabled: root.inPanel
            checked: root.cfg_panelLengthPixels > 0
            onToggled: {
                root.cfg_panelLengthPixels = checked ? 160 : 0;
                root.configurationChanged();
            }
        }
        Repeater {
            model: [i18n("Width:"), i18n("Height:")]

            RowLayout {
                required property int index
                required property string modelData
                readonly property bool adjustable: index === 0 ? root.horizontalPanel : root.verticalPanel
                Kirigami.FormData.label: modelData

                QQC2.Slider {
                    objectName: parent.index === 0 ? "panelWidthSlider" : "panelHeightSlider"
                    Layout.fillWidth: true
                    enabled: parent.adjustable && root.cfg_panelLengthPixels > 0
                    from: 48
                    to: 2000
                    stepSize: 1
                    value: root.cfg_panelLengthPixels || 160
                    onMoved: {
                        root.cfg_panelLengthPixels = Math.round(value);
                        root.configurationChanged();
                    }
                }
                QQC2.SpinBox {
                    visible: parent.adjustable
                    enabled: root.cfg_panelLengthPixels > 0
                    from: 48
                    to: 2000
                    stepSize: 10
                    value: root.cfg_panelLengthPixels || 160
                    editable: true
                    onValueModified: { root.cfg_panelLengthPixels = value; root.configurationChanged(); }
                }
                QQC2.Label {
                    text: parent.adjustable ? i18n("px")
                        : root.inPanel ? i18n("Controlled by panel") : i18n("Resize on desktop")
                }
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: i18n("Proportional length:")
            enabled: root.inPanel && root.cfg_panelLengthPixels === 0
            from: 50
            to: 1000
            stepSize: 10
            value: root.cfg_panelLengthPercent
            editable: true
            textFromValue: function(value, locale) { return i18n("%1%", value); }
            valueFromText: function(text, locale) {
                const parsed = Number.parseInt(String(text).replace(/[^0-9]/g, ""), 10);
                return Number.isFinite(parsed) ? Math.max(50, Math.min(1000, parsed)) : 100;
            }
            onValueModified: { root.cfg_panelLengthPercent = value; root.configurationChanged(); }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Graph:")
            text: root.diskSource ? i18n("Split reads and writes") : i18n("Split upload and download")
            checked: root.cfg_splitDirections
            onToggled: { root.cfg_splitDirections = checked; root.configurationChanged(); }
        }

        QQC2.ComboBox {
            id: uploadStyleCombo
            Kirigami.FormData.label: root.diskSource ? i18n("Write style:") : i18n("Upload style:")
            textRole: "text"
            valueRole: "value"
            model: root.styleChoices
            currentIndex: root.indexOfValue(root.styleChoices, root.cfg_uploadStyle)
            onActivated: { root.cfg_uploadStyle = currentValue; root.configurationChanged(); }
        }
        QQC2.CheckBox {
            text: root.diskSource ? i18n("Invert write direction") : i18n("Invert upload direction")
            checked: root.cfg_uploadInverted
            onToggled: { root.cfg_uploadInverted = checked; root.configurationChanged(); }
        }

        QQC2.ComboBox {
            id: downloadStyleCombo
            Kirigami.FormData.label: root.diskSource ? i18n("Read style:") : i18n("Download style:")
            textRole: "text"
            valueRole: "value"
            model: root.styleChoices
            currentIndex: root.indexOfValue(root.styleChoices, root.cfg_downloadStyle)
            onActivated: { root.cfg_downloadStyle = currentValue; root.configurationChanged(); }
        }
        QQC2.CheckBox {
            text: root.diskSource ? i18n("Invert read direction") : i18n("Invert download direction")
            checked: root.cfg_downloadInverted
            onToggled: { root.cfg_downloadInverted = checked; root.configurationChanged(); }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Horizontal grid:")

            QQC2.ComboBox {
                id: gridModeCombo
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: root.gridChoices
                currentIndex: root.indexOfValue(root.gridChoices, root.cfg_gridMode)
                onActivated: { root.cfg_gridMode = currentValue; root.configurationChanged(); }
            }
            QQC2.SpinBox {
                enabled: root.cfg_gridMode === "fixed"
                from: 1
                to: 20
                value: root.cfg_gridLineCount
                editable: true
                onValueModified: { root.cfg_gridLineCount = value; root.configurationChanged(); }
            }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Readouts:")
            text: root.diskSource ? i18n("Show numeric reads and writes") : i18n("Show numeric upload and download")
            checked: root.cfg_showNumeric
            onToggled: { root.cfg_showNumeric = checked; root.configurationChanged(); }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Readout position:")
            enabled: root.cfg_showNumeric
            textRole: "text"
            valueRole: "value"
            model: root.placementChoices
            currentIndex: root.indexOfValue(root.placementChoices, root.cfg_numericPlacement)
            onActivated: { root.cfg_numericPlacement = currentValue; root.configurationChanged(); }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Graph corner:")
            enabled: root.cfg_showNumeric && root.cfg_numericPlacement === "graph"
            textRole: "text"
            valueRole: "value"
            model: root.positionChoices
            currentIndex: root.indexOfValue(root.positionChoices, root.cfg_numericPosition)
            onActivated: { root.cfg_numericPosition = currentValue; root.configurationChanged(); }
        }
        QQC2.ComboBox {
            id: fontFamilyCombo
            Kirigami.FormData.label: i18n("Numeric font:")
            enabled: root.cfg_showNumeric
            editable: true
            selectTextByMouse: true
            model: root.fontFamilies
            Component.onCompleted: {
                const index = find(root.cfg_numericFontFamily);
                if (index >= 0) currentIndex = index;
                editText = root.cfg_numericFontFamily;
            }
            onActivated: {
                root.cfg_numericFontFamily = currentText;
                root.configurationChanged();
            }
            onAccepted: {
                if (editText.length > 0) {
                    root.cfg_numericFontFamily = editText;
                    root.configurationChanged();
                }
            }
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Font weight:")
            textRole: "text"
            valueRole: "value"
            model: root.fontWeightChoices
            currentIndex: root.indexOfValue(root.fontWeightChoices, root.cfg_fontWeight)
            onActivated: { root.cfg_fontWeight = currentValue; root.configurationChanged(); }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Numeric size:")

            QQC2.CheckBox {
                text: i18n("Auto")
                checked: root.cfg_autoNumericFontSize
                onToggled: { root.cfg_autoNumericFontSize = checked; root.configurationChanged(); }
            }
            QQC2.SpinBox {
                enabled: !root.cfg_autoNumericFontSize && root.cfg_showNumeric
                from: 6
                to: 72
                value: root.cfg_numericFontSize
                editable: true
                onValueModified: { root.cfg_numericFontSize = value; root.configurationChanged(); }
            }
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Status line:")
            text: i18n("Show activity LEDs")
            checked: root.cfg_showLeds
            onToggled: { root.cfg_showLeds = checked; root.configurationChanged(); }
        }
        QQC2.CheckBox {
            text: i18n("Show source label")
            checked: root.cfg_showInterfaceName
            onToggled: { root.cfg_showInterfaceName = checked; root.configurationChanged(); }
        }
    }

    onCfg_networkInterfaceChanged: Qt.callLater(syncInterface)
}
