/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

function format(bytesPerSecond, diskSource) {
    let value = Math.max(0, Number(bytesPerSecond) || 0) * (diskSource ? 1 : 8);
    const units = diskSource ? ["B/s", "kB/s", "MB/s", "GB/s", "TB/s"] : ["b", "k", "M", "G"];
    let unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
        value /= 1000;
        ++unit;
    }
    const decimals = value >= 100 || unit === 0 ? 0 : value >= 10 ? 1 : 2;
    return value.toFixed(decimals) + " " + units[unit];
}
