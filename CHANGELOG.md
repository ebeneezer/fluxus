# Changelog

## 0.3.0 — 2026-09-22

- Add a live hover preview and a pinned enlarged view with a Close button.
- Share the complete traffic history between the miniature and preview, including samples collected before opening.
- Render enlarged graphs at their actual resolution, with smooth curves and native text and line sizes.
- Add a shared preview size setting (150–600%) with a slider, numeric field, and draggable resize corner.
- Position previews relative to the panel and limit their size to the available screen area.
- Add a subtle, centered Fluxus watermark behind enlarged graphs.
- Keep the panel available briefly after closing a preview so the pointer can return without immediate auto-hide.
- Cover shared history, rendering, hover, pinning, closing, and resizing at every panel edge with native and QML tests.

## 0.2.2 — 2026-09-22

- Add Kirigami standard inner spacing in horizontal and vertical panels so graphs and status labels clear widget frames.
- Clip panel content to the inset drawing area.

## 0.2.1 — 2026-09-19

- Keep SSD selections stable across reboots using persistent hardware IDs; migrate existing selections.
- Sort drives by model and persistent ID instead of kernel enumeration order.
- Report missing persistent drive IDs as unavailable instead of selecting another drive.
- Test reversed kernel numbering, legacy selection migration, and missing drive IDs.

## 0.2.0 — 2026-09-15

- Add physical drive selection alongside network interfaces, including device model names.
- Measure disk reads and writes from Linux block counters and display decimal byte/s units.
- Adapt direction labels to the selected source and allow custom source labels.
- Make activity LEDs substantially brighter, including at low traffic rates.
- Reset rates and graph history when switching measurement sources.
- Test disk counter parsing, unit conversion, missing devices and live source switching.

## 0.1.2 — 2026-09-15

- Add selectable font weights, defaulting to Normal, and remove text outlines.
- Add fixed panel length in logical pixels with orientation-aware width and height sliders.
- Let the panel control widget thickness in horizontal and vertical layouts.

## 0.1.1 — 2026-07-28

- Add semi-transparent black backgrounds to the graph rate readouts.
- Allow both graph rate readouts to use the full inner graph width.
- Improve compact and panel layouts.
- Add an x86_64 store release workflow with an `-O3` native backend.

## 0.1.0 — 2026-07-19

- Initial Plasma 6 release.
- Add selectable interfaces, upload/download history graphs, numeric rates,
  configurable graph styles, activity LEDs, and appearance settings.
