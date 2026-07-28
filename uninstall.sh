#!/usr/bin/env bash
set -Eeuo pipefail

readonly APPLET_ID="de.idoc.plasma.fluxus"
readonly PACKAGE_TYPE="Plasma/Applet"

if kpackagetool6 --type "$PACKAGE_TYPE" --show "$APPLET_ID" >/dev/null 2>&1; then
    kpackagetool6 --type "$PACKAGE_TYPE" --remove "$APPLET_ID"
else
    printf 'Fluxus is not installed as a user Plasma applet.\n'
fi

icon_target="${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/256x256/apps/fluxus.png"
rm -f "$icon_target"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

printf 'Fluxus is uninstalled. Restart Plasma Shell if the widget remains visible.\n'
