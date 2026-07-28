# store.kde.org assets

This directory contains release listing assets for store.kde.org. They are not
part of the installed Plasma applet.

- `DESCRIPTION.md`: store description and installation notes
- `RELEASE_NOTES.md`: notes for the current release
- `screenshots/fluxus-panel.png`: primary listing screenshot

The ready-to-upload x86_64 archive and its SHA-256 checksum are generated in
`upload/` with:

```sh
./tools/make-store-archive.sh
```

The archive contains the optimized native backend and its complete
corresponding source code. The primary screenshot is copied into `upload/` as
well.
