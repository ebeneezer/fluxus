/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "networksource.h"
#include "trafficgraph.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>

class FluxusBackendPlugin final : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<NetworkSource>(uri, 1, 0, "NetworkSource");
        qmlRegisterType<TrafficGraph>(uri, 1, 0, "TrafficGraph");
    }
};

#include "fluxusbackendplugin.moc"
