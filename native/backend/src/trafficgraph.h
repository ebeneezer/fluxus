/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include "networksource.h"

#include <QColor>
#include <QPointer>
#include <QPolygonF>
#include <QQuickPaintedItem>
#include <QVector>

class TrafficGraph : public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(NetworkSource *source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int historySeconds READ historySeconds WRITE setHistorySeconds NOTIFY historySecondsChanged)
    Q_PROPERTY(bool splitDirections READ splitDirections WRITE setSplitDirections NOTIFY appearanceChanged)
    Q_PROPERTY(bool uploadInverted READ uploadInverted WRITE setUploadInverted NOTIFY appearanceChanged)
    Q_PROPERTY(bool downloadInverted READ downloadInverted WRITE setDownloadInverted NOTIFY appearanceChanged)
    Q_PROPERTY(QString uploadStyle READ uploadStyle WRITE setUploadStyle NOTIFY appearanceChanged)
    Q_PROPERTY(QString downloadStyle READ downloadStyle WRITE setDownloadStyle NOTIFY appearanceChanged)
    Q_PROPERTY(QString gridMode READ gridMode WRITE setGridMode NOTIFY appearanceChanged)
    Q_PROPERTY(int gridLineCount READ gridLineCount WRITE setGridLineCount NOTIFY appearanceChanged)
    Q_PROPERTY(QColor backgroundColor READ backgroundColor WRITE setBackgroundColor NOTIFY appearanceChanged)
    Q_PROPERTY(QColor gridColor READ gridColor WRITE setGridColor NOTIFY appearanceChanged)
    Q_PROPERTY(QColor uploadColor READ uploadColor WRITE setUploadColor NOTIFY appearanceChanged)
    Q_PROPERTY(QColor downloadColor READ downloadColor WRITE setDownloadColor NOTIFY appearanceChanged)

public:
    explicit TrafficGraph(QQuickItem *parent = nullptr);

    NetworkSource *source() const;
    void setSource(NetworkSource *source);
    int historySeconds() const;
    void setHistorySeconds(int historySeconds);

    bool splitDirections() const;
    void setSplitDirections(bool splitDirections);
    bool uploadInverted() const;
    void setUploadInverted(bool uploadInverted);
    bool downloadInverted() const;
    void setDownloadInverted(bool downloadInverted);
    QString uploadStyle() const;
    void setUploadStyle(const QString &uploadStyle);
    QString downloadStyle() const;
    void setDownloadStyle(const QString &downloadStyle);
    QString gridMode() const;
    void setGridMode(const QString &gridMode);
    int gridLineCount() const;
    void setGridLineCount(int gridLineCount);
    QColor backgroundColor() const;
    void setBackgroundColor(const QColor &backgroundColor);
    QColor gridColor() const;
    void setGridColor(const QColor &gridColor);
    QColor uploadColor() const;
    void setUploadColor(const QColor &uploadColor);
    QColor downloadColor() const;
    void setDownloadColor(const QColor &downloadColor);

    void paint(QPainter *painter) override;
    Q_INVOKABLE void clear();

Q_SIGNALS:
    void sourceChanged();
    void historySecondsChanged();
    void appearanceChanged();

private:
    enum class Style { Line, Filled, Bars };
    struct Sample {
        float download = 0.0F;
        float upload = 0.0F;
    };

    static Style parseStyle(const QString &style);
    static QString styleName(Style style);
    static double automaticCeiling(double observedMaximum);
    void appendSample(double download, double upload);
    void rebuildDisplayHistory(int columns);
    int desiredHistoryCapacity() const;
    void resizeHistory(int capacity);
    Sample sampleAt(int chronologicalIndex) const;
    double maximum(bool upload) const;
    void paintGrid(QPainter *painter, const QRectF &area, double observedMaximum, bool inverted);
    void paintDirection(QPainter *painter, const QRectF &area, bool upload, bool inverted,
                        Style style, const QColor &color, double ceiling);

    QPointer<NetworkSource> m_source;
    QMetaObject::Connection m_sampleConnection;
    QMetaObject::Connection m_interfaceConnection;
    QMetaObject::Connection m_rateConnection;
    QVector<Sample> m_history;
    QVector<Sample> m_displayHistory;
    QVector<quint8> m_displayPresent;
    QPolygonF m_fillPolygon;
    int m_head = 0;
    int m_count = 0;
    int m_historySeconds = 60;
    double m_cachedDownloadMaximum = 0.0;
    double m_cachedUploadMaximum = 0.0;
    bool m_splitDirections = false;
    bool m_uploadInverted = true;
    bool m_downloadInverted = false;
    Style m_uploadStyle = Style::Filled;
    Style m_downloadStyle = Style::Line;
    QString m_gridMode = QStringLiteral("auto");
    int m_gridLineCount = 6;
    QColor m_backgroundColor = QColor(45, 51, 60);
    QColor m_gridColor = QColor(23, 27, 30);
    QColor m_uploadColor = QColor(188, 136, 68);
    QColor m_downloadColor = QColor(0, 230, 230);
};
