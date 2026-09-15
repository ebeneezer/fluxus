/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVariantList>

#include <cstdint>

class NetworkSource : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString interfaceName READ interfaceName WRITE setInterfaceName NOTIFY interfaceNameChanged)
    Q_PROPERTY(double framesPerSecond READ framesPerSecond WRITE setFramesPerSecond NOTIFY framesPerSecondChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    // Keep the original QML API and saved interface IDs compatible. Drive
    // sources use a disk: prefix and map reads/writes to the same two channels.
    Q_PROPERTY(bool diskSource READ diskSource NOTIFY interfaceNameChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY interfaceNameChanged)
    Q_PROPERTY(QVariantList sourceChoices READ sourceChoices NOTIFY sourceChoicesChanged)
    Q_PROPERTY(QStringList interfaces READ interfaces NOTIFY interfacesChanged)
    Q_PROPERTY(double downloadBytesPerSecond READ downloadBytesPerSecond NOTIFY ratesChanged)
    Q_PROPERTY(double uploadBytesPerSecond READ uploadBytesPerSecond NOTIFY ratesChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)

public:
    explicit NetworkSource(QObject *parent = nullptr);
    ~NetworkSource() override;

    QString interfaceName() const;
    void setInterfaceName(const QString &interfaceName);

    double framesPerSecond() const;
    void setFramesPerSecond(double framesPerSecond);

    bool active() const;
    void setActive(bool active);

    QStringList interfaces() const;
    bool diskSource() const;
    QString deviceName() const;
    QVariantList sourceChoices() const;
    double downloadBytesPerSecond() const;
    double uploadBytesPerSecond() const;
    bool valid() const;
    QString errorString() const;

    Q_INVOKABLE void refreshInterfaces();

Q_SIGNALS:
    void interfaceNameChanged();
    void framesPerSecondChanged();
    void activeChanged();
    void interfacesChanged();
    void sourceChoicesChanged();
    void ratesChanged();
    void validChanged();
    void errorStringChanged();
    void sampled(double downloadBytesPerSecond, double uploadBytesPerSecond);

private Q_SLOTS:
    void sample();

private:
    struct Counters {
        std::uint64_t received = 0;
        std::uint64_t transmitted = 0;
        bool found = false;
    };

    bool ensureOpen(int &fd, const char *path);
    Counters readCounters();
    Counters readNetworkCounters(QStringList *interfaceNames = nullptr);
    Counters readDiskCounters();
    void resetBaseline();
    void setRates(double downloadBytesPerSecond, double uploadBytesPerSecond);
    void setValid(bool valid);
    void setErrorString(const QString &errorString);
    void applyTimerInterval();

    QString m_interfaceName = QStringLiteral("all");
    QByteArray m_interfaceUtf8 = QByteArrayLiteral("all");
    double m_framesPerSecond = 1.0;
    bool m_active = false;
    QVariantList m_sourceChoices;
    QStringList m_interfaces = { QStringLiteral("all") };
    double m_downloadBytesPerSecond = 0.0;
    double m_uploadBytesPerSecond = 0.0;
    bool m_valid = false;
    QString m_errorString;
    QTimer m_timer;
    QElapsedTimer m_sampleClock;
    QElapsedTimer m_interfaceClock;
    std::uint64_t m_previousReceived = 0;
    std::uint64_t m_previousTransmitted = 0;
    bool m_haveBaseline = false;
    int m_procFd = -1;
    int m_diskFd = -1;
};
