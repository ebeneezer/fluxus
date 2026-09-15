/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <array>
#include <charconv>
#include <cstdint>
#include <limits>
#include <string_view>

namespace Fluxus
{
struct DiskCounters {
    std::uint64_t readBytes = 0;
    std::uint64_t writeBytes = 0;
    bool found = false;
};

inline DiskCounters parseDiskstats(std::string_view data, std::string_view device)
{
    auto token = [](std::string_view &line) {
        const auto start = line.find_first_not_of(" \t\r");
        if (start == std::string_view::npos) {
            line = {};
            return std::string_view {};
        }
        line.remove_prefix(start);
        const auto end = line.find_first_of(" \t\r");
        const auto value = line.substr(0, end);
        line.remove_prefix(end == std::string_view::npos ? line.size() : end);
        return value;
    };
    while (!data.empty()) {
        const auto newline = data.find('\n');
        auto line = data.substr(0, newline);
        data.remove_prefix(newline == std::string_view::npos ? data.size() : newline + 1);
        token(line); // major
        token(line); // minor
        if (token(line) != device || device.empty()) {
            continue;
        }
        std::array<std::uint64_t, 11> fields {};
        for (auto &field : fields) {
            const auto value = token(line);
            if (value.empty()) return {};
            const auto result = std::from_chars(value.data(), value.data() + value.size(), field);
            if (result.ec != std::errc() || result.ptr != value.data() + value.size()) return {};
        }
        // Kernel diskstats always use 512-byte sectors, including 4Kn devices.
        constexpr std::uint64_t SectorSize = 512;
        constexpr auto MaxSectors = std::numeric_limits<std::uint64_t>::max() / SectorSize;
        if (fields[2] > MaxSectors || fields[6] > MaxSectors) return {};
        return {fields[2] * SectorSize, fields[6] * SectorSize, true};
    }
    return {};
}
}
