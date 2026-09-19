/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QString>
#include <QVector>

#include <algorithm>

namespace Fluxus
{
struct DiskPaths {
    QString sysBlock = QStringLiteral("/sys/block");
    QString byId = QStringLiteral("/dev/disk/by-id");
};

struct DiskDevice {
    QString device;
    QString model;
    QString source;
};

inline QString diskDeviceName(const QString &source, const DiskPaths &paths = {})
{
    const QString name = source.mid(5);
    if (!name.startsWith(QStringLiteral("by-id/"))) {
        return name.contains('/') ? QString() : name;
    }
    const QString id = name.mid(6);
    if (id.isEmpty() || id.contains('/') || id == "." || id == "..") {
        return {};
    }
    const QString target = QFileInfo(QDir(paths.byId).filePath(id)).canonicalFilePath();
    if (target.isEmpty()) {
        return {};
    }
    const QString device = QFileInfo(target).fileName();
    // Never substitute another drive or a partition when an ID disappears.
    return QFileInfo::exists(QDir(paths.sysBlock).filePath(device + "/device"))
        ? device : QString();
}

inline QVector<DiskDevice> diskDevices(const DiskPaths &paths = {})
{
    QMap<QString, QString> ids;
    const QDir byId(paths.byId);
    const auto priority = [](const QString &id) {
        return id.startsWith("wwn-") || id.startsWith("nvme-eui.")
            || id.startsWith("nvme-uuid.") ? 0 : 1;
    };
    for (const QString &id : byId.entryList(QDir::Files | QDir::System | QDir::NoDotAndDotDot, QDir::Name)) {
        const QString device = diskDeviceName(QStringLiteral("disk:by-id/") + id, paths);
        if (device.isEmpty()) {
            continue;
        }
        if (!ids.contains(device) || priority(id) < priority(ids.value(device))) {
            ids.insert(device, id);
        }
    }

    QVector<DiskDevice> devices;
    const QDir blockDevices(paths.sysBlock);
    for (const QString &device : blockDevices.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
        // Whole physical devices only; omit partitions and virtual devices.
        if (!QFileInfo::exists(blockDevices.filePath(device + "/device"))) {
            continue;
        }
        QFile modelFile(blockDevices.filePath(device + "/device/model"));
        QString model;
        if (modelFile.open(QIODevice::ReadOnly)) {
            model = QString::fromUtf8(modelFile.readAll()).trimmed();
        }
        devices.append({device, model, ids.contains(device)
            ? QStringLiteral("disk:by-id/") + ids.value(device)
            : QStringLiteral("disk:") + device});
    }
    std::sort(devices.begin(), devices.end(), [](const DiskDevice &left, const DiskDevice &right) {
        const int modelOrder = QString::compare(left.model, right.model, Qt::CaseInsensitive);
        return modelOrder == 0 ? left.source < right.source : modelOrder < 0;
    });
    return devices;
}

inline QString persistentDiskSource(const QString &source, const QVector<DiskDevice> &devices)
{
    // Preserve already selected IDs, even if another alias becomes preferred.
    if (source.startsWith(QStringLiteral("disk:")) && !source.startsWith(QStringLiteral("disk:by-id/"))) {
        for (const auto &disk : devices) {
            if (source.mid(5) == disk.device) {
                return disk.source;
            }
        }
    }
    return source;
}
}
