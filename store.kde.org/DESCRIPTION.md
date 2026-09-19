# Fluxus

Fluxus is a compact, low-overhead network and disk throughput meter for KDE Plasma 6.
Its visual design is inspired by the classic GKrellM monitor and works in
horizontal panels, vertical panels, and on the desktop.

## Features

- Live upload/download or disk read/write rates
- Physical SSD/HDD selection with model names and decimal byte/s readouts
- Persistent drive selection across reboots and consistent sorting by model and hardware ID
- Selectable Linux network interface or aggregate mode
- Overlay or split-direction traffic graphs
- Line, filled-area, and bar graph styles
- Configurable sampling rate and history window
- Automatic or fixed graph grid
- Readable numeric rates with configurable font and placement
- Optional upload/download activity LEDs
- Configurable colors and panel length

## Requirements

- Linux x86_64
- KDE Plasma 6
- Qt 6 Core, Gui, QML, and Quick runtime libraries

The download contains a native x86_64 Qt plugin compiled with `-O3`. It also
contains the complete corresponding source code.

## Installation

Extract the archive and run:

```sh
./install.sh
```

To restart Plasma Shell during installation:

```sh
./install.sh --restart-plasma
```

To remove Fluxus:

```sh
./uninstall.sh
```

Source code and issue tracker:

<https://github.com/ebeneezer/fluxus>

License: GPL-2.0-or-later
