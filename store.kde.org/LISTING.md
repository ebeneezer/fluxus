# Fluxus store.kde.org listing

## Name

Fluxus

## Category

Plasma 6 Widgets / System Information

## Summary

A compact, low-overhead network and disk throughput meter for KDE Plasma 6.

## Description

Fluxus displays incoming and outgoing network traffic or physical drive reads
and writes in a compact GKrellM-inspired graph. The two directions can be overlaid or split, and the
history, sampling rate, graph styles, directions, colors, numeric readouts,
activity LEDs, and interface label are configurable.

Drive selections use persistent hardware IDs to follow the same SSD or HDD across
reboots. The source selector sorts drives by model and persistent ID.

The release contains a native x86_64 Qt 6 backend that reads Linux network and
disk counters directly from `/proc/net/dev` and `/proc/diskstats`. It is intended
for Linux x86_64 systems running KDE Plasma 6.

## Tags

network, bandwidth, traffic, upload, download, SSD, HDD, disk, system monitor, Plasma 6, GKrellM

## Requirements

- Linux x86_64
- KDE Plasma 6
- Qt 6

## License

GPL-2.0-or-later

## Homepage

https://github.com/ebeneezer/fluxus

## Issue tracker

https://github.com/ebeneezer/fluxus/issues

## Version 0.2.1

- Stable SSD and HDD selections across reboots using persistent hardware IDs
- Automatic migration of existing drive selections using the current drive mapping
- Consistent drive ordering by model and persistent ID
- Missing drives reported as unavailable without switching to another device
