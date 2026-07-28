/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

QQC2.Button {
    id: root

    property color selectedColor: "#000000"
    signal colorEdited(string value)

    implicitWidth: Math.max(implicitBackgroundWidth,
                            Kirigami.Units.gridUnit * 7)

    contentItem: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 18
            color: root.selectedColor
            border.color: root.palette.mid
            border.width: 1
        }
        QQC2.Label {
            Layout.fillWidth: true
            Layout.minimumWidth: hexMetrics.advanceWidth
            text: root.selectedColor.toString().toUpperCase()
            font.family: "monospace"
            horizontalAlignment: Text.AlignLeft
        }
    }

    TextMetrics {
        id: hexMetrics
        font.family: "monospace"
        text: "#FFFFFFFF"
    }

    onClicked: colorDialog.open()

    ColorDialog {
        id: colorDialog
        selectedColor: root.selectedColor
        onAccepted: root.colorEdited(selectedColor.toString())
    }
}
