/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property string cfg_backgroundColor: "#2D333C"
    property string cfg_gridColor: "#171B1E"
    property string cfg_uploadColor: "#BC8844"
    property string cfg_downloadColor: "#00E6E6"
    property string cfg_labelColor: "#FFFFFF"

    property string cfg_backgroundColorDefault: "#2D333C"
    property string cfg_gridColorDefault: "#171B1E"
    property string cfg_uploadColorDefault: "#BC8844"
    property string cfg_downloadColorDefault: "#00E6E6"
    property string cfg_labelColorDefault: "#FFFFFF"

    signal configurationChanged

    Kirigami.FormLayout {
        anchors.fill: parent

        ColorButton {
            Kirigami.FormData.label: i18n("Graph background color:")
            Layout.fillWidth: true
            selectedColor: root.cfg_backgroundColor
            onColorEdited: value => { root.cfg_backgroundColor = value; root.configurationChanged(); }
        }
        ColorButton {
            Kirigami.FormData.label: i18n("Grid:")
            Layout.fillWidth: true
            selectedColor: root.cfg_gridColor
            onColorEdited: value => { root.cfg_gridColor = value; root.configurationChanged(); }
        }
        ColorButton {
            Kirigami.FormData.label: i18n("Upload / Write:")
            Layout.fillWidth: true
            selectedColor: root.cfg_uploadColor
            onColorEdited: value => { root.cfg_uploadColor = value; root.configurationChanged(); }
        }
        ColorButton {
            Kirigami.FormData.label: i18n("Download / Read:")
            Layout.fillWidth: true
            selectedColor: root.cfg_downloadColor
            onColorEdited: value => { root.cfg_downloadColor = value; root.configurationChanged(); }
        }
        ColorButton {
            Kirigami.FormData.label: i18n("Source label:")
            Layout.fillWidth: true
            selectedColor: root.cfg_labelColor
            onColorEdited: value => { root.cfg_labelColor = value; root.configurationChanged(); }
        }
    }
}
