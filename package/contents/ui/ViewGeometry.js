/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

function statusHeight(height, numericScale, statisticsBelowLeds) {
    return statisticsBelowLeds
        ? Math.max(30, Math.min(42 * numericScale, height * 0.40))
        : Math.max(14, Math.min(32 * numericScale, height * 0.19));
}

function compactStatusHeight(height, numericScale, statisticsBelowLeds, showLeds) {
    const fullHeight = statusHeight(height, numericScale, statisticsBelowLeds);
    if (statisticsBelowLeds)
        return fullHeight - Math.max(8, Math.min(13, Math.floor(fullHeight * 0.30)));
    return showLeds ? 11 : 0;
}

function compactViewHeight(height, numericScale, statisticsBelowLeds, showLeds) {
    return height - statusHeight(height, numericScale, statisticsBelowLeds)
        + compactStatusHeight(height, numericScale, statisticsBelowLeds, showLeds);
}
