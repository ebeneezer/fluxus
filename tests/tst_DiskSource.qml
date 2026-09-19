/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtTest
import de.idoc.fluxus.backend 1.0
import "../package/contents/ui" as FluxusUi
import "../package/contents/ui/RateFormat.js" as RateFormat

TestCase {
    name: "DiskSource"
    width: 180
    height: 57
    when: windowShown

    NetworkSource { id: source; framesPerSecond: 30 }
    FluxusUi.FluxusView {
        id: view
        anchors.fill: parent
        source: source
        configuration: ({showLeds: true, sourceLabel: "SSD test"})
    }
    SignalSpy { id: samples; target: source; signalName: "sampled" }

    function cleanup() { source.active = false; samples.clear(); }

    function test_units() {
        compare(RateFormat.format(125000000, true), "125 MB/s");
        compare(RateFormat.format(125000000, false), "1.00 G");
        compare(RateFormat.format(3500000000, true), "3.50 GB/s");
        compare(RateFormat.format(0, true), "0 B/s");
        compare(RateFormat.format(-10, true), "0 B/s");
    }

    function test_missingDeviceAndNetworkRecovery() {
        source.interfaceName = "disk:fluxus-nonexistent-test-device";
        source.active = true;
        verify(source.diskSource);
        verify(!source.valid);
        compare(source.downloadBytesPerSecond, 0);
        compare(source.uploadBytesPerSecond, 0);
        verify(source.errorString.indexOf("Drive not found") >= 0);
        source.interfaceName = "all";
        verify(!source.diskSource);
        verify(source.valid, source.errorString);
        compare(source.errorString, "");
    }

    function test_missingPersistentDevice() {
        source.interfaceName = "disk:by-id/fluxus-nonexistent-test-id";
        source.active = true;
        verify(source.diskSource);
        verify(!source.valid);
        compare(source.deviceName, "");
        compare(source.persistentInterfaceName, source.interfaceName);
        verify(source.errorString.indexOf("fluxus-nonexistent-test-id") >= 0);
    }

    function test_legacyMigration() {
        source.refreshInterfaces();
        const drives = source.sourceChoices.filter(choice => choice.kind === "disk"
            && choice.value.startsWith("disk:by-id/"));
        if (!drives.length) { skip("No persistent drive IDs on this host"); return; }
        for (const drive of drives) {
            source.interfaceName = "disk:" + drive.device;
            compare(source.persistentInterfaceName, drive.value);
            source.active = true;
            verify(source.valid, source.errorString);
            source.interfaceName = source.persistentInterfaceName;
            compare(source.deviceName, drive.device);
            verify(source.valid, source.errorString);
            source.active = false;
        }
    }

    function test_physicalDrives() {
        source.refreshInterfaces();
        const drives = source.sourceChoices.filter(choice => choice.kind === "disk");
        if (!drives.length) { skip("No physical block devices on this host"); return; }
        for (const drive of drives) {
            source.active = false;
            source.interfaceName = drive.value;
            verify(source.diskSource);
            verify(view.diskSource);
            compare(source.deviceName, drive.device);
            compare(view.formatRate(125000000), "125 MB/s");
            source.active = true;
            verify(source.valid, source.errorString);
            // Selecting or restarting a source establishes a fresh baseline.
            compare(source.downloadBytesPerSecond, 0);
            compare(source.uploadBytesPerSecond, 0);
            samples.clear();
            tryVerify(() => samples.count >= 2);
            verify(Number.isFinite(source.downloadBytesPerSecond));
            verify(Number.isFinite(source.uploadBytesPerSecond));
            verify(source.downloadBytesPerSecond >= 0);
            verify(source.uploadBytesPerSecond >= 0);
        }
    }
}
