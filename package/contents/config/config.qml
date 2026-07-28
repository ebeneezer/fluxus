/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Display")
        icon: "network-wired"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Colors")
        icon: "preferences-desktop-color"
        source: "ConfigColors.qml"
    }
}
