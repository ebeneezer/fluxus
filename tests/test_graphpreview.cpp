/* SPDX-License-Identifier: GPL-2.0-or-later */
#include "../native/backend/src/trafficgraph.h"

#include <QGuiApplication>
#include <QImage>
#include <QPainter>
#include <cstdlib>
#include <iostream>

static QImage render(TrafficGraph &graph)
{
    QImage image(graph.size().toSize(), QImage::Format_ARGB32_Premultiplied);
    image.fill(Qt::transparent);
    QPainter painter(&image);
    graph.paint(&painter);
    return image;
}

static void check(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    NetworkSource source;
    source.setActive(false);
    TrafficGraph miniature;
    miniature.setSize(QSizeF(96, 72));
    miniature.setSource(&source);
    const QImage empty = render(miniature);
    for (int i = 0; i < 80; ++i) source.sampled(100 + i * 17 % 250, 40 + i * 11 % 130);
    check(render(miniature) != empty, "fixture must contain a visible history");

    TrafficGraph preview;
    preview.setSize(miniature.size());
    preview.setSource(&source);
    preview.setHistoryGraph(&miniature);
    check(render(preview) == render(miniature), "opening must show the entire existing history");

    for (const auto &style : {QStringLiteral("line"), QStringLiteral("bars"), QStringLiteral("filled")}) {
        for (bool split : {false, true}) {
            miniature.setUploadStyle(style);
            miniature.setDownloadStyle(style);
            miniature.setSplitDirections(split);
            preview.setUploadStyle(style);
            preview.setDownloadStyle(style);
            preview.setSplitDirections(split);
            source.sampled(420, 170);
            check(render(preview) == render(miniature), "live history must stay identical in every style");
        }
    }

    preview.setSize(miniature.size() * 3);
    check(render(preview).size() == QSize(288, 216), "preview must paint at its actual dimensions");
    check(render(preview) != render(miniature).scaled(288, 216),
          "preview must redraw the samples, not magnify miniature pixels");
    preview.setSize(miniature.size());

    TrafficGraph grid;
    grid.setGridMode(QStringLiteral("fixed"));
    grid.setGridLineCount(3);
    for (const QSize size : {QSize(96, 72), QSize(288, 216)}) {
        grid.setSize(size);
        const QImage image = render(grid);
        int gridPixels = 0;
        for (int y = 0; y < size.height(); ++y) {
            if (image.pixelColor(size.width() / 2, y) == grid.gridColor()) ++gridPixels;
        }
        check(gridPixels == 3, "grid strokes must remain one pixel at every preview size");
    }

    const QImage beforePreviewClear = render(miniature);
    preview.clear();
    preview.setHistorySeconds(10);
    check(render(miniature) == beforePreviewClear, "preview must not mutate the shared history");
    miniature.setHistorySeconds(10);
    check(render(preview) == render(miniature), "history resizing must be shared");
    miniature.clear();
    check(render(preview) == render(miniature), "history clearing must be shared");
    source.sampled(90, 60);
    source.setFramesPerSecond(5);
    check(render(preview) == render(miniature), "sampling-rate reset must be shared");
    source.sampled(300, 120);
    preview.setHistoryGraph(nullptr);
    check(render(preview) != render(miniature), "detached preview must own an independent history");

    auto *temporary = new TrafficGraph;
    preview.setHistoryGraph(temporary);
    delete temporary;
    check(preview.historyGraph() == nullptr, "destroyed miniature must detach safely");
    render(preview);
    return 0;
}
