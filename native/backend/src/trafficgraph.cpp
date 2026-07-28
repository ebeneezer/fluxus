/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "trafficgraph.h"

#include <QPainter>
#include <algorithm>
#include <cmath>

TrafficGraph::TrafficGraph(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setAntialiasing(false);
    setOpaquePainting(true);
    setMipmap(false);
    resizeHistory(desiredHistoryCapacity());
    connect(this, &TrafficGraph::appearanceChanged, this, [this]() { update(); });
}

NetworkSource *TrafficGraph::source() const
{
    return m_source;
}

void TrafficGraph::setSource(NetworkSource *source)
{
    if (m_source == source) {
        return;
    }
    disconnect(m_sampleConnection);
    disconnect(m_interfaceConnection);
    disconnect(m_rateConnection);
    m_source = source;
    if (m_source) {
        m_sampleConnection = connect(m_source, &NetworkSource::sampled,
                                     this, &TrafficGraph::appendSample);
        m_interfaceConnection = connect(m_source, &NetworkSource::interfaceNameChanged,
                                        this, &TrafficGraph::clear);
        m_rateConnection = connect(m_source, &NetworkSource::framesPerSecondChanged, this, [this]() {
            clear();
            resizeHistory(desiredHistoryCapacity());
        });
    }
    clear();
    resizeHistory(desiredHistoryCapacity());
    Q_EMIT sourceChanged();
}

int TrafficGraph::historySeconds() const
{
    return m_historySeconds;
}

void TrafficGraph::setHistorySeconds(int value)
{
    const int bounded = std::clamp(value, 10, 900);
    if (m_historySeconds == bounded) {
        return;
    }
    m_historySeconds = bounded;
    resizeHistory(desiredHistoryCapacity());
    update();
    Q_EMIT historySecondsChanged();
}

bool TrafficGraph::splitDirections() const
{
    return m_splitDirections;
}

void TrafficGraph::setSplitDirections(bool value)
{
    if (m_splitDirections == value) return;
    m_splitDirections = value;
    Q_EMIT appearanceChanged();
}

bool TrafficGraph::uploadInverted() const
{
    return m_uploadInverted;
}

void TrafficGraph::setUploadInverted(bool value)
{
    if (m_uploadInverted == value) return;
    m_uploadInverted = value;
    Q_EMIT appearanceChanged();
}

bool TrafficGraph::downloadInverted() const
{
    return m_downloadInverted;
}

void TrafficGraph::setDownloadInverted(bool value)
{
    if (m_downloadInverted == value) return;
    m_downloadInverted = value;
    Q_EMIT appearanceChanged();
}

QString TrafficGraph::uploadStyle() const
{
    return styleName(m_uploadStyle);
}

void TrafficGraph::setUploadStyle(const QString &value)
{
    const Style style = parseStyle(value);
    if (m_uploadStyle == style) return;
    m_uploadStyle = style;
    Q_EMIT appearanceChanged();
}

QString TrafficGraph::downloadStyle() const
{
    return styleName(m_downloadStyle);
}

QString TrafficGraph::gridMode() const
{
    return m_gridMode;
}

void TrafficGraph::setGridMode(const QString &value)
{
    const QString normalized = value == QStringLiteral("off") || value == QStringLiteral("fixed")
        ? value
        : QStringLiteral("auto");
    if (m_gridMode == normalized) return;
    m_gridMode = normalized;
    Q_EMIT appearanceChanged();
}

int TrafficGraph::gridLineCount() const
{
    return m_gridLineCount;
}

void TrafficGraph::setGridLineCount(int value)
{
    const int bounded = std::clamp(value, 1, 20);
    if (m_gridLineCount == bounded) return;
    m_gridLineCount = bounded;
    Q_EMIT appearanceChanged();
}

void TrafficGraph::setDownloadStyle(const QString &value)
{
    const Style style = parseStyle(value);
    if (m_downloadStyle == style) return;
    m_downloadStyle = style;
    Q_EMIT appearanceChanged();
}

QColor TrafficGraph::backgroundColor() const
{
    return m_backgroundColor;
}

void TrafficGraph::setBackgroundColor(const QColor &value)
{
    if (!value.isValid() || m_backgroundColor == value) return;
    m_backgroundColor = value;
    Q_EMIT appearanceChanged();
}

QColor TrafficGraph::gridColor() const
{
    return m_gridColor;
}

void TrafficGraph::setGridColor(const QColor &value)
{
    if (!value.isValid() || m_gridColor == value) return;
    m_gridColor = value;
    Q_EMIT appearanceChanged();
}

QColor TrafficGraph::uploadColor() const
{
    return m_uploadColor;
}

void TrafficGraph::setUploadColor(const QColor &value)
{
    if (!value.isValid() || m_uploadColor == value) return;
    m_uploadColor = value;
    Q_EMIT appearanceChanged();
}

QColor TrafficGraph::downloadColor() const
{
    return m_downloadColor;
}

void TrafficGraph::setDownloadColor(const QColor &value)
{
    if (!value.isValid() || m_downloadColor == value) return;
    m_downloadColor = value;
    Q_EMIT appearanceChanged();
}

void TrafficGraph::paint(QPainter *painter)
{
    const QRectF area = boundingRect();
    painter->setRenderHint(QPainter::Antialiasing, false);
    painter->fillRect(area, m_backgroundColor);

    if (area.width() < 2.0 || area.height() < 2.0) {
        return;
    }

    rebuildDisplayHistory(std::max(2, static_cast<int>(std::floor(area.width()))));
    const double uploadMaximum = maximum(true);
    const double downloadMaximum = maximum(false);
    if (m_splitDirections) {
        const qreal half = area.height() / 2.0;
        const QRectF uploadArea(area.left(), area.top(), area.width(), half);
        const QRectF downloadArea(area.left(), area.top() + half, area.width(), area.height() - half);
        const double uploadCeiling = m_gridMode == QStringLiteral("auto")
            ? automaticCeiling(uploadMaximum) : std::max(1.0, uploadMaximum);
        const double downloadCeiling = m_gridMode == QStringLiteral("auto")
            ? automaticCeiling(downloadMaximum) : std::max(1.0, downloadMaximum);
        paintGrid(painter, uploadArea, uploadMaximum, m_uploadInverted);
        paintGrid(painter, downloadArea, downloadMaximum, m_downloadInverted);
        paintDirection(painter, uploadArea, true, m_uploadInverted, m_uploadStyle,
                       m_uploadColor, uploadCeiling);
        paintDirection(painter, downloadArea, false, m_downloadInverted, m_downloadStyle,
                       m_downloadColor, downloadCeiling);
        painter->setPen(QPen(m_gridColor, 1.0));
        painter->drawLine(QPointF(area.left(), std::floor(area.center().y()) + 0.5),
                          QPointF(area.right(), std::floor(area.center().y()) + 0.5));
    } else {
        const bool uploadDefinesScale = uploadMaximum >= downloadMaximum;
        const double observedMaximum = std::max(uploadMaximum, downloadMaximum);
        const double ceiling = m_gridMode == QStringLiteral("auto")
            ? automaticCeiling(observedMaximum) : std::max(1.0, observedMaximum);
        paintGrid(painter, area, observedMaximum,
                  uploadDefinesScale ? m_uploadInverted : m_downloadInverted);
        paintDirection(painter, area, true, m_uploadInverted, m_uploadStyle, m_uploadColor, ceiling);
        paintDirection(painter, area, false, m_downloadInverted, m_downloadStyle, m_downloadColor, ceiling);
    }
}

void TrafficGraph::clear()
{
    m_head = 0;
    m_count = 0;
    std::fill(m_history.begin(), m_history.end(), Sample {});
    std::fill(m_displayHistory.begin(), m_displayHistory.end(), Sample {});
    std::fill(m_displayPresent.begin(), m_displayPresent.end(), 0);
    m_cachedDownloadMaximum = 0.0;
    m_cachedUploadMaximum = 0.0;
    update();
}

TrafficGraph::Style TrafficGraph::parseStyle(const QString &style)
{
    if (style.compare(QStringLiteral("filled"), Qt::CaseInsensitive) == 0) return Style::Filled;
    if (style.compare(QStringLiteral("bars"), Qt::CaseInsensitive) == 0) return Style::Bars;
    return Style::Line;
}

QString TrafficGraph::styleName(Style style)
{
    switch (style) {
    case Style::Filled: return QStringLiteral("filled");
    case Style::Bars: return QStringLiteral("bars");
    case Style::Line: return QStringLiteral("line");
    }
    return QStringLiteral("line");
}

double TrafficGraph::automaticCeiling(double observedMaximum)
{
    if (!std::isfinite(observedMaximum) || observedMaximum <= 0.0) {
        return 1.0;
    }
    const double bits = observedMaximum * 8.0;
    const double decade = std::pow(10.0, std::floor(std::log10(bits)));
    const double leadingDigit = std::max(1.0, std::floor(bits / decade));
    return leadingDigit * decade / 8.0;
}

void TrafficGraph::appendSample(double download, double upload)
{
    if (m_history.isEmpty()) {
        resizeHistory(desiredHistoryCapacity());
    }
    if (m_history.isEmpty()) {
        return;
    }
    m_history[m_head] = Sample {
        static_cast<float>(std::max(0.0, download)),
        static_cast<float>(std::max(0.0, upload))
    };
    m_head = (m_head + 1) % m_history.size();
    m_count = std::min(m_count + 1, static_cast<int>(m_history.size()));
    update();
}

void TrafficGraph::rebuildDisplayHistory(int columns)
{
    if (m_displayHistory.size() != columns) {
        m_displayHistory.resize(columns);
        m_displayPresent.resize(columns);
    }
    std::fill(m_displayHistory.begin(), m_displayHistory.end(), Sample {});
    std::fill(m_displayPresent.begin(), m_displayPresent.end(), 0);
    m_cachedDownloadMaximum = 0.0;
    m_cachedUploadMaximum = 0.0;

    if (m_count <= 0 || m_history.size() < 2 || columns < 2) {
        return;
    }

    const qint64 columnSpan = columns - 1;
    const qint64 sampleSpan = m_history.size() - 1;
    for (int index = 0; index < m_count; ++index) {
        const Sample sample = sampleAt(index);
        const qint64 age = m_count - 1 - index;
        const int column = columns - 1 - static_cast<int>(age * columnSpan / sampleSpan);
        Sample &display = m_displayHistory[column];
        display.download = std::max(display.download, sample.download);
        display.upload = std::max(display.upload, sample.upload);
        m_displayPresent[column] = 1;
        m_cachedDownloadMaximum = std::max(m_cachedDownloadMaximum, static_cast<double>(sample.download));
        m_cachedUploadMaximum = std::max(m_cachedUploadMaximum, static_cast<double>(sample.upload));
    }
}

int TrafficGraph::desiredHistoryCapacity() const
{
    const double framesPerSecond = m_source ? m_source->framesPerSecond() : 1.0;
    return std::max(2, static_cast<int>(std::ceil(m_historySeconds * framesPerSecond)));
}

void TrafficGraph::resizeHistory(int capacity)
{
    capacity = std::max(2, capacity);
    if (capacity == m_history.size()) {
        return;
    }
    QVector<Sample> resized(capacity);
    const int retained = std::min(capacity, m_count);
    const int first = m_count - retained;
    for (int index = 0; index < retained; ++index) {
        resized[index] = sampleAt(first + index);
    }
    m_history = std::move(resized);
    m_count = retained;
    m_head = retained % capacity;
}

TrafficGraph::Sample TrafficGraph::sampleAt(int chronologicalIndex) const
{
    if (chronologicalIndex < 0 || chronologicalIndex >= m_count || m_history.isEmpty()) {
        return {};
    }
    const int oldest = (m_head - m_count + m_history.size()) % m_history.size();
    return m_history[(oldest + chronologicalIndex) % m_history.size()];
}

double TrafficGraph::maximum(bool upload) const
{
    return upload ? m_cachedUploadMaximum : m_cachedDownloadMaximum;
}

void TrafficGraph::paintGrid(QPainter *painter, const QRectF &area, double observedMaximum, bool inverted)
{
    if (m_gridMode == QStringLiteral("off") || area.height() <= 1.0) {
        return;
    }

    painter->save();
    painter->setClipRect(area);
    painter->setPen(QPen(m_gridColor, 1.0));

    if (m_gridMode == QStringLiteral("fixed")) {
        for (int line = 1; line <= m_gridLineCount; ++line) {
            const qreal fraction = static_cast<qreal>(line) / (m_gridLineCount + 1);
            const qreal y = std::floor(area.top() + fraction * area.height()) + 0.5;
            painter->drawLine(QPointF(area.left(), y), QPointF(area.right(), y));
        }
        painter->restore();
        return;
    }

    if (!std::isfinite(observedMaximum) || observedMaximum <= 0.0) {
        painter->restore();
        return;
    }

    // The readout is expressed in bits/s. At 779 bit/s the leading digit sets
    // a 700 bit/s edge: 100..600 are internal and both borders remain implicit.
    const double displayMaximum = observedMaximum * 8.0;
    const double decade = std::pow(10.0, std::floor(std::log10(displayMaximum)));
    const double displayCeiling = std::floor(displayMaximum / decade) * decade;
    for (double marker = decade; marker < displayCeiling; marker += decade) {
        const qreal fraction = marker / displayCeiling;
        const qreal rawY = inverted
            ? area.top() + fraction * area.height()
            : area.bottom() - fraction * area.height();
        const qreal y = std::floor(rawY) + 0.5;
        if (y > area.top() && y < area.bottom()) {
            painter->drawLine(QPointF(area.left(), y), QPointF(area.right(), y));
        }
    }
    painter->restore();
}

void TrafficGraph::paintDirection(QPainter *painter, const QRectF &area, bool upload, bool inverted,
                                  Style style, const QColor &color, double ceiling)
{
    if (m_count <= 0 || m_displayHistory.isEmpty() || area.width() <= 1.0
            || area.height() <= 1.0 || ceiling <= 0.0) {
        return;
    }

    const qreal baseline = inverted ? area.top() : area.bottom();
    const int columns = m_displayHistory.size();
    int firstColumn = -1;
    int lastColumn = -1;
    for (int column = 0; column < columns; ++column) {
        if (m_displayPresent[column]) {
            if (firstColumn < 0) firstColumn = column;
            lastColumn = column;
        }
    }
    if (firstColumn < 0) {
        return;
    }

    auto pointFor = [&](int column) {
        const Sample sample = m_displayHistory[column];
        const double value = upload ? sample.upload : sample.download;
        const qreal fraction = std::clamp(value / ceiling, 0.0, 1.0);
        const qreal y = inverted
            ? area.top() + fraction * area.height()
            : area.bottom() - fraction * area.height();
        const qreal x = area.left() + static_cast<qreal>(column) * (area.width() - 1.0) / (columns - 1);
        return QPointF(x, y);
    };

    painter->save();
    painter->setClipRect(area);
    if (style == Style::Filled) {
        m_fillPolygon.clear();
        m_fillPolygon.reserve(columns + 2);
        m_fillPolygon.append(QPointF(pointFor(firstColumn).x(), baseline));
        for (int column = firstColumn; column <= lastColumn; ++column) {
            if (m_displayPresent[column]) m_fillPolygon.append(pointFor(column));
        }
        m_fillPolygon.append(QPointF(pointFor(lastColumn).x(), baseline));
        QColor fillColor = color;
        fillColor.setAlpha(205);
        painter->setPen(QPen(color, 1.0));
        painter->setBrush(fillColor);
        painter->drawPolygon(m_fillPolygon);
    } else if (style == Style::Bars) {
        painter->setPen(QPen(color, 1.0));
        // rebuildDisplayHistory() has already reduced the time series to at
        // most one maximum per pixel column.  Skipping every second column a
        // second time made samples blink in and out while moving left,
        // especially when the sample spacing was not an even pixel count.
        for (int column = firstColumn; column <= lastColumn; ++column) {
            if (!m_displayPresent[column]) continue;
            const QPointF point = pointFor(column);
            painter->drawLine(QPointF(point.x(), baseline), point);
        }
    } else {
        painter->setPen(QPen(color, 2.0));
        QPointF previous;
        bool havePrevious = false;
        for (int column = firstColumn; column <= lastColumn; ++column) {
            if (!m_displayPresent[column]) continue;
            const QPointF point = pointFor(column);
            if (havePrevious) painter->drawLine(previous, point);
            previous = point;
            havePrevious = true;
        }
    }
    painter->restore();
}
