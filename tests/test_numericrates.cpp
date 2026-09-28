/* SPDX-License-Identifier: GPL-2.0-or-later */
#include "../native/backend/src/networksource.h"

#include <QCoreApplication>
#include <QEventLoop>
#include <QTimer>

#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>

#include <cstdlib>
#include <iostream>

static void check(bool condition, const char *message)
{
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    const int socketFd = ::socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    check(socketFd >= 0, "loopback socket must open");
    sockaddr_in destination {};
    destination.sin_family = AF_INET;
    destination.sin_port = htons(9);
    destination.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

    QTimer traffic;
    traffic.setInterval(10);
    QObject::connect(&traffic, &QTimer::timeout, [&]() {
        const char payload[512] {};
        ::sendto(socketFd, payload, sizeof(payload), 0,
                 reinterpret_cast<sockaddr *>(&destination), sizeof(destination));
    });

    NetworkSource source;
    source.setInterfaceName(QStringLiteral("lo"));
    source.setFramesPerSecond(30);
    source.setNumericUpdatesPerSecond(1);
    int graphUpdates = 0;
    int numericUpdates = 0;
    QObject::connect(&source, &NetworkSource::sampled, [&]() { ++graphUpdates; });
    QObject::connect(&source, &NetworkSource::numericRatesChanged, [&]() { ++numericUpdates; });
    traffic.start();
    source.setActive(true);
    QTimer::singleShot(2300, &app, &QCoreApplication::quit);
    app.exec();

    check(graphUpdates >= 45, "graph must receive frequent samples");
    check(numericUpdates >= 1 && numericUpdates <= 3,
          "numeric values must update at their own one-second rate");
    check(source.numericDownloadBytesPerSecond() > 0,
          "numeric readout must receive the interval average");

    source.setNumericUpdatesPerSecond(0.2);
    const int beforeSlowInterval = numericUpdates;
    QEventLoop slowInterval;
    QTimer::singleShot(650, &slowInterval, &QEventLoop::quit);
    slowInterval.exec();
    check(numericUpdates == beforeSlowInterval,
          "a slower numeric rate must take effect while sampling continues");
    check(graphUpdates >= 60, "graph must keep sampling at its original rate");

    source.setActive(false);
    traffic.stop();
    ::close(socketFd);
    return 0;
}
