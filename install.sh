#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly APPLET_ID="de.idoc.plasma.fluxus"
readonly PACKAGE_TYPE="Plasma/Applet"
readonly PLUGIN_RELATIVE_PATH="contents/imports/de/idoc/fluxus/backend/libfluxusbackendplugin.so"
readonly ICON_RELATIVE_PATH="contents/icons/fluxus.png"

restart_plasma=0
build_from_source="${FLUXUS_BUILD_FROM_SOURCE:-0}"

usage() {
    printf 'Usage: %s [--build-from-source] [--restart-plasma]\n' "$(basename "$0")"
    printf '\n'
    printf 'Installs or upgrades the %s Plasma 6 applet for the current user.\n' "$APPLET_ID"
    printf '\n'
    printf 'Options:\n'
    printf '  --build-from-source  Rebuild the bundled x86_64 backend with -O3.\n'
    printf '  --restart-plasma    Restart the user Plasma shell after installation.\n'
    printf '  --no-restart        Do not restart Plasma Shell (default).\n'
    printf '  -h, --help          Show this help text.\n'
}

die() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

have() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    have "$1" || die "required command not found: $1"
}

jobs() {
    if [[ -n "${FLUXUS_BUILD_JOBS:-}" ]]; then
        [[ "${FLUXUS_BUILD_JOBS}" =~ ^[1-9][0-9]*$ ]] \
            || die "FLUXUS_BUILD_JOBS must be a positive integer"
        printf '%s\n' "${FLUXUS_BUILD_JOBS}"
    elif have nproc; then
        nproc
    elif have getconf; then
        getconf _NPROCESSORS_ONLN
    else
        printf '1\n'
    fi
}

while (($#)); do
    case "$1" in
        --build-from-source)
            build_from_source=1
            ;;
        --restart-plasma)
            restart_plasma=1
            ;;
        --no-restart)
            restart_plasma=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
    shift
done

[[ "$build_from_source" == "0" || "$build_from_source" == "1" ]] \
    || die "FLUXUS_BUILD_FROM_SOURCE must be 0 or 1"

require_command kpackagetool6

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
package_dir="${script_dir}/package"
metadata_file="${package_dir}/metadata.json"
qmldir_file="${package_dir}/contents/imports/de/idoc/fluxus/backend/qmldir"
plugin_file="${package_dir}/${PLUGIN_RELATIVE_PATH}"
icon_file="${package_dir}/${ICON_RELATIVE_PATH}"
build_dir="${FLUXUS_BUILD_DIR:-${script_dir}/build-release-x86_64}"

[[ -d "$package_dir" ]] || die "package directory missing: $package_dir"
[[ -r "$metadata_file" ]] || die "metadata missing or unreadable: $metadata_file"

if [[ ! -s "$plugin_file" || "$build_from_source" == "1" ]]; then
    [[ -f "${script_dir}/CMakeLists.txt" ]] \
        || die "bundled backend plugin missing and source tree is not included"
    require_command cmake

    cmake -S "$script_dir" -B "$build_dir" \
        -DCMAKE_BUILD_TYPE=Release \
        "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG -m64 -march=x86-64 -mtune=generic" \
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON
    cmake --build "$build_dir" -j"$(jobs)"
fi

[[ -r "$qmldir_file" ]] || die "QML module descriptor missing or unreadable: $qmldir_file"
[[ -s "$plugin_file" && -r "$plugin_file" ]] \
    || die "native backend plugin missing or empty: $plugin_file"
[[ -s "$icon_file" && -r "$icon_file" ]] \
    || die "package icon missing or empty: $icon_file"

grep -Eq '"KPackageStructure"[[:space:]]*:[[:space:]]*"Plasma/Applet"' "$metadata_file" \
    || die "metadata does not declare KPackageStructure Plasma/Applet"
grep -Eq '"Id"[[:space:]]*:[[:space:]]*"de\.idoc\.plasma\.fluxus"' "$metadata_file" \
    || die "metadata does not declare applet id ${APPLET_ID}"
grep -Eq '^module[[:space:]]+de\.idoc\.fluxus\.backend$' "$qmldir_file" \
    || die "qmldir does not declare module de.idoc.fluxus.backend"
grep -Eq '^plugin[[:space:]]+fluxusbackendplugin$' "$qmldir_file" \
    || die "qmldir does not declare plugin fluxusbackendplugin"

if have file; then
    file "$plugin_file" | grep -Eq 'ELF 64-bit.*x86-64' \
        || die "native backend is not an x86_64 ELF shared object"
fi

if have ldd; then
    missing_libs="$(ldd "$plugin_file" 2>/dev/null | awk '/not found/ { print $1 }')"
    [[ -z "$missing_libs" ]] \
        || die "native backend plugin has unresolved runtime libraries: ${missing_libs//$'\n'/, }"
fi

if kpackagetool6 --type "$PACKAGE_TYPE" --show "$APPLET_ID" >/dev/null 2>&1; then
    action="upgrade"
else
    action="install"
fi

printf '%s %s from %s\n' "${action^}" "$APPLET_ID" "$package_dir"
kpackagetool6 --type "$PACKAGE_TYPE" "--${action}" "$package_dir"

icon_theme_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/256x256/apps"
mkdir -p "$icon_theme_dir"
install -m 0644 "$icon_file" "${icon_theme_dir}/fluxus.png"

if have gtk-update-icon-cache; then
    gtk-update-icon-cache -q -t "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor" \
        >/dev/null 2>&1 || true
fi
if have kbuildsycoca6; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

if ((restart_plasma)); then
    require_command systemctl
    systemctl --user restart plasma-plasmashell.service
else
    printf 'Installed. Restart Plasma Shell if a running instance still shows cached metadata.\n'
fi
