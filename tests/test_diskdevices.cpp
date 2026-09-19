/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "../native/backend/src/diskdevices.h"
#include "../native/backend/src/diskstats.h"

#include <QTemporaryDir>

#include <cstdlib>
#include <iostream>

void check(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

int main()
{
    QTemporaryDir fixture;
    check(fixture.isValid(), "Temporary directory required");
    const Fluxus::DiskPaths paths {fixture.path() + "/sys/block", fixture.path() + "/dev/disk/by-id"};
    check(QDir().mkpath(paths.byId), "Create by-id directory");
    const auto makeDisk = [&](const QString &device, const QByteArray &model) {
        check(QDir().mkpath(paths.sysBlock + '/' + device + "/device"), "Create physical device");
        QFile file(paths.sysBlock + '/' + device + "/device/model");
        check(file.open(QIODevice::WriteOnly) && file.write(model) == model.size(), "Write device model");
        QFile node(fixture.path() + "/dev/" + device);
        check(node.open(QIODevice::WriteOnly), "Create fake device node");
    };
    const auto link = [&](const QString &id, const QString &device) {
        QFile::remove(paths.byId + '/' + id);
        check(QFile::link(fixture.path() + "/dev/" + device, paths.byId + '/' + id), "Create device alias");
    };
    makeDisk("nvme0n1", "System SSD\n");
    makeDisk("nvme1n1", "Data SSD\n");
    QDir().mkpath(paths.sysBlock + "/loop0");
    QDir().mkpath(paths.sysBlock + "/dm-0");
    link("nvme-system_serial", "nvme0n1");
    link("nvme-eui.system", "nvme0n1");
    link("nvme-data_serial", "nvme1n1");
    QFile partition(fixture.path() + "/dev/nvme0n1p1");
    check(partition.open(QIODevice::WriteOnly), "Create partition node");
    partition.close();
    link("nvme-eui.system-part1", "nvme0n1p1");

    const auto before = Fluxus::diskDevices(paths);
    check(before.size() == 2, "Exclude virtual devices and do not duplicate aliases");
    check(before[0].model == "Data SSD" && before[1].model == "System SSD", "Sort by model, not kernel index");
    const QString system = Fluxus::persistentDiskSource("disk:nvme0n1", before);
    const QString data = Fluxus::persistentDiskSource("disk:nvme1n1", before);
    check(system == "disk:by-id/nvme-eui.system", "Prefer globally unique hardware ID");
    check(data == "disk:by-id/nvme-data_serial", "Use model/serial alias if no WWN or EUI exists");

    // Simulate the next boot assigning exactly the opposite controller numbers.
    makeDisk("nvme0n1", "Data SSD\n");
    makeDisk("nvme1n1", "System SSD\n");
    link("nvme-system_serial", "nvme1n1");
    link("nvme-eui.system", "nvme1n1");
    link("nvme-data_serial", "nvme0n1");
    const auto after = Fluxus::diskDevices(paths);
    check(after[0].source == before[0].source && after[1].source == before[1].source,
          "Source identities and list order must survive reversed kernel numbering");
    check(Fluxus::diskDeviceName(system, paths) == "nvme1n1", "System selection must follow its physical drive");
    check(Fluxus::diskDeviceName(data, paths) == "nvme0n1", "Data selection must follow its physical drive");
    const std::string counters = "259 0 nvme0n1 1 0 10 0 1 0 20 0 0 0 0\n"
                                 "259 1 nvme1n1 1 0 30 0 1 0 40 0 0 0 0\n";
    const auto selected = Fluxus::parseDiskstats(counters, Fluxus::diskDeviceName(system, paths).toStdString());
    check(selected.found && selected.readBytes == 30 * 512, "Sample the original system disk after reboot");
    const QString alias = "disk:by-id/nvme-system_serial";
    check(Fluxus::persistentDiskSource(alias, after) == alias && Fluxus::diskDeviceName(alias, paths) == "nvme1n1",
          "Keep working saved aliases even when enumeration prefers another ID");

    makeDisk("nvme0n1", "Identical model\n");
    makeDisk("nvme1n1", "Identical model\n");
    const auto sameModel = Fluxus::diskDevices(paths);
    check(sameModel[0].source < sameModel[1].source, "Identical models use identity as the stable tie-breaker");
    QFile::remove(paths.byId + "/nvme-eui.system");
    check(Fluxus::diskDeviceName(system, paths).isEmpty(), "Missing ID must never fall back to another SSD");
    check(Fluxus::persistentDiskSource(system, Fluxus::diskDevices(paths)) == system, "Keep disconnected selection");
    check(Fluxus::diskDeviceName("disk:by-id/nvme-eui.system-part1", paths).isEmpty(), "Reject partition aliases");
    check(Fluxus::diskDeviceName("disk:by-id/../../nvme0n1", paths).isEmpty(), "Reject paths outside by-id");
    check(Fluxus::persistentDiskSource("all", after) == "all", "Network aggregate stays unchanged");
    check(Fluxus::persistentDiskSource("disk:absent", after) == "disk:absent", "Unavailable legacy selection stays unchanged");
    makeDisk("sda", "No persistent ID\n");
    check(Fluxus::persistentDiskSource("disk:sda", Fluxus::diskDevices(paths)) == "disk:sda",
          "Devices without persistent IDs remain selectable by legacy name");
    std::cout << "Persistent drive selection passed\n";
}
