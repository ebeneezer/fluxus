# Fluxus 0.2.1

- Keep each SSD widget attached to the same physical drive across reboots, even when Linux changes device numbers.
- Save drive selections using persistent hardware IDs from `/dev/disk/by-id`.
- Automatically migrate existing selections using the current drive mapping, preserving custom labels such as SSD1 and SSD2.
- Sort the drive selector by model and persistent ID for a consistent order.
- Report a missing drive as unavailable without silently switching to another drive.
- Devices without persistent IDs remain selectable by their kernel device names.
