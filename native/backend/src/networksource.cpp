/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "networksource.h"

#include <algorithm>
#include <array>
#include <charconv>
#include <fcntl.h>
#include <string_view>
#include <unistd.h>

namespace
{
constexpr std::size_t ProcBufferSize = 32768;

std::string_view trim(std::string_view text)
{
    while (!text.empty() && (text.front() == ' ' || text.front() == '\t')) {
        text.remove_prefix(1);
    }
    while (!text.empty() && (text.back() == ' ' || text.back() == '\t')) {
        text.remove_suffix(1);
    }
    return text;
}

bool nextUnsigned(std::string_view &text, std::uint64_t &value)
{
    text = trim(text);
    if (text.empty()) {
        return false;
    }

    const char *begin = text.data();
    const char *end = begin + text.size();
    const auto result = std::from_chars(begin, end, value);
    if (result.ec != std::errc()) {
        return false;
    }

    text.remove_prefix(static_cast<std::size_t>(result.ptr - begin));
    return true;
}
}

NetworkSource::NetworkSource(QObject *parent)
    : QObject(parent)
{
    // Coarse timers can be coalesced with other Plasma wakeups. Their small
    // tolerance is immaterial for a bandwidth graph and saves needless wakes.
    m_timer.setTimerType(Qt::CoarseTimer);
    connect(&m_timer, &QTimer::timeout, this, &NetworkSource::sample);
    applyTimerInterval();
}

NetworkSource::~NetworkSource()
{
    if (m_procFd >= 0) {
        ::close(m_procFd);
    }
}

QString NetworkSource::interfaceName() const
{
    return m_interfaceName;
}

void NetworkSource::setInterfaceName(const QString &interfaceName)
{
    const QString normalized = interfaceName.trimmed().isEmpty() ? QStringLiteral("all") : interfaceName.trimmed();
    if (m_interfaceName == normalized) {
        return;
    }

    m_interfaceName = normalized;
    m_interfaceUtf8 = normalized.toUtf8();
    resetBaseline();
    Q_EMIT interfaceNameChanged();
    if (m_active) {
        sample();
    }
}

double NetworkSource::framesPerSecond() const
{
    return m_framesPerSecond;
}

void NetworkSource::setFramesPerSecond(double framesPerSecond)
{
    const double bounded = std::clamp(framesPerSecond, 0.2, 30.0);
    if (qFuzzyCompare(m_framesPerSecond + 1.0, bounded + 1.0)) {
        return;
    }

    m_framesPerSecond = bounded;
    applyTimerInterval();
    Q_EMIT framesPerSecondChanged();
}

bool NetworkSource::active() const
{
    return m_active;
}

void NetworkSource::setActive(bool active)
{
    if (m_active == active) {
        return;
    }

    m_active = active;
    if (m_active) {
        refreshInterfaces();
        resetBaseline();
        sample();
        m_timer.start();
    } else {
        m_timer.stop();
        resetBaseline();
        setRates(0.0, 0.0);
    }
    Q_EMIT activeChanged();
}

QStringList NetworkSource::interfaces() const
{
    return m_interfaces;
}

double NetworkSource::downloadBytesPerSecond() const
{
    return m_downloadBytesPerSecond;
}

double NetworkSource::uploadBytesPerSecond() const
{
    return m_uploadBytesPerSecond;
}

bool NetworkSource::valid() const
{
    return m_valid;
}

QString NetworkSource::errorString() const
{
    return m_errorString;
}

void NetworkSource::refreshInterfaces()
{
    QStringList names;
    readCounters(&names);
    names.removeDuplicates();
    std::sort(names.begin(), names.end(), [](const QString &left, const QString &right) {
        return QString::localeAwareCompare(left, right) < 0;
    });
    names.prepend(QStringLiteral("all"));

    if (names != m_interfaces) {
        m_interfaces = names;
        Q_EMIT interfacesChanged();
    }
    m_interfaceClock.restart();
}

void NetworkSource::sample()
{
    QStringList interfaceNames;
    QStringList *names = !m_interfaceClock.isValid() || m_interfaceClock.elapsed() >= 5000
        ? &interfaceNames
        : nullptr;
    const Counters counters = readCounters(names);

    if (names) {
        interfaceNames.removeDuplicates();
        std::sort(interfaceNames.begin(), interfaceNames.end(), [](const QString &left, const QString &right) {
            return QString::localeAwareCompare(left, right) < 0;
        });
        interfaceNames.prepend(QStringLiteral("all"));
        if (interfaceNames != m_interfaces) {
            m_interfaces = interfaceNames;
            Q_EMIT interfacesChanged();
        }
        m_interfaceClock.restart();
    }

    if (!counters.found) {
        resetBaseline();
        setRates(0.0, 0.0);
        setValid(false);
        setErrorString(QStringLiteral("Network interface not found: %1").arg(m_interfaceName));
        Q_EMIT sampled(0.0, 0.0);
        return;
    }

    setValid(true);
    setErrorString(QString());

    if (!m_haveBaseline) {
        m_previousReceived = counters.received;
        m_previousTransmitted = counters.transmitted;
        m_haveBaseline = true;
        m_sampleClock.start();
        setRates(0.0, 0.0);
        Q_EMIT sampled(0.0, 0.0);
        return;
    }

    const qint64 elapsedNanoseconds = m_sampleClock.nsecsElapsed();
    m_sampleClock.restart();
    if (elapsedNanoseconds <= 0) {
        return;
    }

    const double seconds = static_cast<double>(elapsedNanoseconds) / 1'000'000'000.0;
    const std::uint64_t receivedDelta = counters.received >= m_previousReceived
        ? counters.received - m_previousReceived
        : 0;
    const std::uint64_t transmittedDelta = counters.transmitted >= m_previousTransmitted
        ? counters.transmitted - m_previousTransmitted
        : 0;
    m_previousReceived = counters.received;
    m_previousTransmitted = counters.transmitted;

    const double download = static_cast<double>(receivedDelta) / seconds;
    const double upload = static_cast<double>(transmittedDelta) / seconds;
    setRates(download, upload);
    Q_EMIT sampled(download, upload);
}

bool NetworkSource::ensureOpen()
{
    if (m_procFd >= 0) {
        return true;
    }

    m_procFd = ::open("/proc/net/dev", O_RDONLY | O_CLOEXEC);
    if (m_procFd < 0) {
        setValid(false);
        setErrorString(QStringLiteral("Cannot open /proc/net/dev"));
        return false;
    }
    return true;
}

NetworkSource::Counters NetworkSource::readCounters(QStringList *interfaceNames)
{
    Counters counters;
    if (!ensureOpen()) {
        return counters;
    }

    std::array<char, ProcBufferSize> buffer {};
    const ssize_t length = ::pread(m_procFd, buffer.data(), buffer.size() - 1, 0);
    if (length <= 0) {
        ::close(m_procFd);
        m_procFd = -1;
        setValid(false);
        setErrorString(QStringLiteral("Cannot read /proc/net/dev"));
        return counters;
    }

    const std::string_view selected(m_interfaceUtf8.constData(), static_cast<std::size_t>(m_interfaceUtf8.size()));
    const bool aggregate = selected == "all";
    std::string_view file(buffer.data(), static_cast<std::size_t>(length));

    while (!file.empty()) {
        const std::size_t newline = file.find('\n');
        std::string_view line = file.substr(0, newline);
        if (newline == std::string_view::npos) {
            file = {};
        } else {
            file.remove_prefix(newline + 1);
        }

        const std::size_t colon = line.find(':');
        if (colon == std::string_view::npos) {
            continue;
        }

        const std::string_view name = trim(line.substr(0, colon));
        if (name.empty()) {
            continue;
        }
        if (interfaceNames) {
            interfaceNames->append(QString::fromUtf8(name.data(), static_cast<qsizetype>(name.size())));
        }

        const bool matches = aggregate ? name != "lo" : name == selected;
        if (!matches) {
            continue;
        }

        std::string_view fields = line.substr(colon + 1);
        std::uint64_t received = 0;
        std::uint64_t transmitted = 0;
        std::uint64_t ignored = 0;
        if (!nextUnsigned(fields, received)) {
            continue;
        }
        bool complete = true;
        for (int field = 1; field < 8; ++field) {
            if (!nextUnsigned(fields, ignored)) {
                complete = false;
                break;
            }
        }
        if (!complete || !nextUnsigned(fields, transmitted)) {
            continue;
        }

        counters.received += received;
        counters.transmitted += transmitted;
        counters.found = true;
        if (!aggregate) {
            break;
        }
    }

    return counters;
}

void NetworkSource::resetBaseline()
{
    m_haveBaseline = false;
    m_previousReceived = 0;
    m_previousTransmitted = 0;
    m_sampleClock.invalidate();
}

void NetworkSource::setRates(double downloadBytesPerSecond, double uploadBytesPerSecond)
{
    if (qFuzzyCompare(m_downloadBytesPerSecond + 1.0, downloadBytesPerSecond + 1.0)
            && qFuzzyCompare(m_uploadBytesPerSecond + 1.0, uploadBytesPerSecond + 1.0)) {
        return;
    }
    m_downloadBytesPerSecond = downloadBytesPerSecond;
    m_uploadBytesPerSecond = uploadBytesPerSecond;
    Q_EMIT ratesChanged();
}

void NetworkSource::setValid(bool valid)
{
    if (m_valid == valid) {
        return;
    }
    m_valid = valid;
    Q_EMIT validChanged();
}

void NetworkSource::setErrorString(const QString &errorString)
{
    if (m_errorString == errorString) {
        return;
    }
    m_errorString = errorString;
    Q_EMIT errorStringChanged();
}

void NetworkSource::applyTimerInterval()
{
    m_timer.setInterval(qRound(1000.0 / m_framesPerSecond));
}
