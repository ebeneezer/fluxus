/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "../native/backend/src/diskstats.h"

#include <cstdlib>
#include <iostream>
#include <string>

void check(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

int main()
{
    const std::string snapshot =
        " 259 1 nvme0n1p1 1 0 9999 0 1 0 8888 0 0 0 0\n"
        " 259 0 nvme0n1 100 8 12345678901 20 200 4 7654321 30 0 40 50 0 0 0 0 0 0\n"
        " 259 2 nvme1n1 10 0 100 20 30 0 200 40 0 50 60\n";
    const auto first = Fluxus::parseDiskstats(snapshot, "nvme0n1");
    check(first.found, "First whole drive must be found");
    check(first.readBytes == 12345678901ULL * 512, "Reads must use 64-bit 512-byte sectors");
    check(first.writeBytes == 7654321ULL * 512, "Writes must use field 7");
    const auto second = Fluxus::parseDiskstats(snapshot, "nvme1n1");
    check(second.found && second.readBytes == 51200 && second.writeBytes == 102400,
          "Devices must have independent counters; 11-field records are supported");
    check(!Fluxus::parseDiskstats(snapshot, "nvme0").found, "Names must match exactly");
    check(!Fluxus::parseDiskstats(snapshot, "absent").found, "Missing devices must be invalid");
    check(!Fluxus::parseDiskstats(snapshot, "").found, "Empty selection must be invalid");
    for (const std::string invalid : {
            "1 0 2", "1 0 -2 0 1 0 2 0 0 0 0", "1 0 2x 0 1 0 2 0 0 0 0",
            "1 0 18446744073709551615 0 1 0 2 0 0 0 0",
            "1 0 2 0 1 0 18446744073709551616 0 0 0 0"}) {
        check(!Fluxus::parseDiskstats("259 0 nvme0n1 " + invalid, "nvme0n1").found,
              "Truncated, malformed, negative and overflowing counters must be rejected");
    }
    const auto idle = Fluxus::parseDiskstats("259\t0\tnvme0n1\t0 0 0 0 0 0 0 0 0 0 0", "nvme0n1");
    check(idle.found && idle.readBytes == 0 && idle.writeBytes == 0,
          "An idle device is valid, including tab-delimited input without a final newline");
    std::cout << "Disk counter parsing passed\n";
}
