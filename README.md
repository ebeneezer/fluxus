# Fluxus

Fluxus is a low-overhead network and disk throughput meter for KDE Plasma 6. Its compact
design is inspired by the classic GKrellM monitor: incoming and outgoing traffic
are drawn in cyan and amber on a dark, bevelled graph.

## Features

- Selectable Linux network interface, including an aggregate `all` mode
- Physical SSD/HDD read and write throughput with device model names in the source selector
- Persistent drive selection across reboots, with drives sorted by model and hardware ID
- Decimal disk throughput in B/s, kB/s, MB/s, GB/s or TB/s; custom source labels
- Overlay or split upload/download graphs
- Independent line, filled-area, or bar rendering
- Configurable sampling rate from one frame every 5 seconds to 30 frames per second
- Configurable history window from 10 seconds to 15 minutes
- Automatically scaled decimal `b`, `k`, `M`, and `G` bit-rate readouts
- Full-width numeric readouts with text-sized translucent backgrounds
- Searchable font selector, selectable weight (Light through Bold), fixed font size, and automatic fit mode
- Fixed panel width/height in logical pixels or proportional panel sizing
- Optional fixed-count or automatically derived horizontal grid lines
- Optional activity LEDs and interface label
- Configurable colors, graph direction, and numeric placement
- Live hover preview and pinned enlarged view, with shared size and full history

The `all` interface adds the counters of every non-loopback interface. On systems
with VPNs, bridges, or containers, selecting the physical interface directly can
avoid counting the same traffic at more than one network layer.

Select **Measurement source → Drive: …** to monitor a whole physical drive.
Cyan shows reads and amber shows writes. Disk throughput uses decimal bytes per
second; network throughput retains its existing bit-rate units. Separate widget
instances can monitor separate drives. **Source label** can identify them as
SSD1 and SSD2. The source selector excludes partitions and virtual/stacked devices;
the network `all` aggregate never includes disks.

Drive sampling reads `/proc/diskstats` without elevated permissions and converts
sector deltas using the kernel's fixed 512-byte accounting unit. It measures
completed block I/O; application reads served from the page cache produce no disk
read traffic. Drive selections are saved as `disk:by-id/ID` in the existing
`networkInterface` setting, using persistent hardware identifiers from
`/dev/disk/by-id`. They follow the physical drive even if Linux assigns different
device numbers on the next boot. The selector sorts drives by model and persistent
ID. Legacy `disk:DEVICE` selections are migrated automatically using the current
drive mapping; devices without a persistent ID retain the legacy format. A missing
saved ID is reported as unavailable, without selecting another drive.

## Binary Release

Download [Fluxus 0.3.0 for Plasma 6 / Linux x86_64](dist/fluxus-0.3.0-plasma6-linux-x86_64.tar.bz2)
and its [SHA-256 checksum](dist/fluxus-0.3.0-plasma6-linux-x86_64.tar.bz2.sha256).

The store archive is built for:

- Linux x86_64
- KDE Plasma 6
- Qt 6

It includes the compiled native QML backend, so end users do not need a compiler,
CMake, or Plasma development packages. The backend remains dynamically linked
against the Qt 6 and system libraries supplied by the target distribution.

## Install a Release Archive

Extract the archive and run:

```sh
./install.sh
```

The installer validates the package metadata, QML module, native backend, and
runtime library resolution before installing or upgrading Fluxus for the current
user. It does not restart Plasma automatically.

To restart Plasma Shell as part of installation:

```sh
./install.sh --restart-plasma
```

To remove Fluxus:

```sh
./uninstall.sh
```

## Build from Source

Requirements:

- KDE Plasma 6
- Qt 6 Core, Gui, Qml, and Quick development files
- CMake 3.24 or newer
- A C++20 compiler

On Arch Linux or CachyOS, the relevant packages are typically:

```sh
sudo pacman -S cmake qt6-base qt6-declarative
```

Configure and build an optimized release:

```sh
cmake -S . -B build-release-x86_64 \
  -DCMAKE_BUILD_TYPE=Release \
  "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG -m64 -march=x86-64 -mtune=generic" \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
cmake --build build-release-x86_64 -j"$(nproc)"
```

The build writes the native plugin directly to:

```text
package/contents/imports/de/idoc/fluxus/backend/
```

Build and install the source checkout with:

```sh
./install.sh --build-from-source
```

## Configuration

Open the widget settings from the Plasma panel. Fluxus supports horizontal and
vertical panels as well as desktop placement. Enable **Panel size → Fixed length**
to set the width in a horizontal panel or the height in a vertical panel
(48–2000 logical pixels). The settings detect the panel orientation and enable
only the applicable Width or Height slider. The panel controls the other dimension. With fixed
length disabled, **Proportional length** scales the widget relative to the panel
thickness (50–1000%). These settings do not affect desktop sizing.

**Font weight** applies to numeric rates and status labels and defaults to Normal.
Choose Light for thinner text; the available appearance depends on the selected
font family. Numeric readouts use a translucent background without a text outline.

Hover over Fluxus to open a live enlarged preview. Click the widget to keep that
same window open until its Close button is pressed. **Preview size** sets the
shared magnification (150–600%) using a slider or numeric field. Drag the marked
corner of the pinned window to change and save the same setting. Both modes use
identical dimensions, bounded by the available screen area. The preview shares
the miniature's complete history, colors, directions and display settings, and
draws the samples afresh at its actual size. Curves use the larger pixel grid;
strokes, text and LEDs are rendered without a magnifying transform. A subtle
Fluxus watermark sits behind the enlarged graph. After pressing Close, the panel
stays available for up to 1.5 seconds while the pointer returns, then resumes its
configured auto-hide behavior.

## Tests

Build the backend before running the QML tests:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  /usr/lib/qt6/bin/qmltestrunner \
  -input tests \
  -import package/contents/imports \
  -o -,txt
```

Run the native disk counter parser and persistent drive selection tests with:

```sh
ctest --test-dir build-release-x86_64 --output-on-failure
```

Additional visual and backend smoke fixtures are available under `tests/`.

## Store Archive

Create the store.kde.org x86_64 release with:

```sh
./tools/make-store-archive.sh
```

The script enforces a Release build with `-O3` and interprocedural optimization,
checks the compiler command lines, validates the x86_64 ELF header and runtime
libraries, strips the staged plugin, and writes the archive plus SHA-256 checksum
to both `dist/` and `store.kde.org/upload/`. The complete corresponding source
code is included in the archive.

## Architecture

QML implements the Plasma integration, configuration, and UI. A small Qt 6 plugin
reads `/proc/net/dev` or `/proc/diskstats` with `pread(2)` and renders the traffic history in one
`QQuickPaintedItem`. The sampler uses a fixed stack buffer; the renderer uses a
bounded ring buffer and repaints only after a new sample.

The history stores the complete selected interval, up to 27,000 samples at
15 minutes and 30 fps. Samples are reduced to at most one peak value per graph
pixel before painting, so rendering cost does not grow with the configured
history length.

## Support and Source

- Source: <https://github.com/ebeneezer/fluxus>
- Issues: <https://github.com/ebeneezer/fluxus/issues>

The applet ID is `de.idoc.plasma.fluxus`.

## License

Fluxus is licensed under `GPL-2.0-or-later`. See `LICENSE`.
