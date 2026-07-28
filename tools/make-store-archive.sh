#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
applet_id="de.idoc.plasma.fluxus"
package_dir="${repo_dir}/package"
metadata_file="${package_dir}/metadata.json"
build_dir="${FLUXUS_BUILD_DIR:-${repo_dir}/build-release-x86_64}"
dist_dir="${FLUXUS_DIST_DIR:-${repo_dir}/dist}"
store_upload_dir="${repo_dir}/store.kde.org/upload"
store_screenshot="${repo_dir}/store.kde.org/screenshots/fluxus-panel.png"
plugin_path="${package_dir}/contents/imports/de/idoc/fluxus/backend/libfluxusbackendplugin.so"
release_cxx_flags="-O3 -DNDEBUG -m64 -march=x86-64 -mtune=generic"

die() {
    printf 'make-store-archive.sh: %s\n' "$*" >&2
    exit 1
}

have() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {
    have "$1" || die "missing required command: $1"
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

metadata_value() {
    python3 - "$metadata_file" "$1" <<'PY'
import json
import sys

path, key = sys.argv[1:]
with open(path, encoding="utf-8") as handle:
    metadata = json.load(handle)
print(metadata["KPlugin"][key])
PY
}

require_command cmake
require_command file
require_command ldd
require_command python3
require_command readelf
require_command sha256sum
require_command strip
require_command tar

[[ -d "$package_dir" ]] || die "missing package directory: $package_dir"
[[ -f "$metadata_file" ]] || die "missing metadata file: $metadata_file"
[[ -f "${repo_dir}/LICENSE" ]] || die "missing LICENSE"
[[ -f "${repo_dir}/README.md" ]] || die "missing README.md"
[[ -f "${repo_dir}/CHANGELOG.md" ]] || die "missing CHANGELOG.md"
[[ -f "$store_screenshot" ]] || die "missing store screenshot: $store_screenshot"
[[ -x "${repo_dir}/install.sh" ]] || die "install.sh is not executable"
[[ -x "${repo_dir}/uninstall.sh" ]] || die "uninstall.sh is not executable"

version="$(metadata_value Version)"
metadata_id="$(metadata_value Id)"
[[ "$metadata_id" == "$applet_id" ]] \
    || die "metadata Id is ${metadata_id}, expected ${applet_id}"
[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._+-]*$ ]] \
    || die "metadata Version contains unsafe characters: ${version}"

arch="$(uname -m)"
[[ "$arch" == "x86_64" ]] || die "this release target requires an x86_64 build host"

cmake -S "$repo_dir" -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    "-DCMAKE_CXX_FLAGS_RELEASE=${release_cxx_flags}" \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
cmake --build "$build_dir" -j"$(jobs)"

[[ -s "$plugin_path" ]] || die "backend plugin was not built: $plugin_path"

python3 - "$build_dir/compile_commands.json" <<'PY'
import json
import shlex
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    commands = json.load(handle)

native = [entry for entry in commands if "/native/backend/" in entry["file"]]
if not native:
    raise SystemExit("no native backend compilation entries found")

for entry in native:
    arguments = entry.get("arguments")
    if arguments is None:
        arguments = shlex.split(entry["command"])
    if "-O3" not in arguments:
        raise SystemExit(f"-O3 missing for {entry['file']}")
PY

file "$plugin_path" | grep -Fq 'ELF 64-bit LSB shared object, x86-64' \
    || die "backend plugin is not an x86_64 ELF shared object"
readelf -h "$plugin_path" | grep -Eq 'Machine:[[:space:]]+Advanced Micro Devices X86-64' \
    || die "ELF header does not declare x86_64"

missing_libs="$(ldd "$plugin_path" 2>/dev/null | awk '/not found/ { print $1 }')"
[[ -z "$missing_libs" ]] \
    || die "backend plugin has unresolved runtime libraries: ${missing_libs//$'\n'/, }"

package_name="fluxus-${version}-plasma6-linux-x86_64"
stage_dir="${dist_dir}/${package_name}"
archive_path="${dist_dir}/${package_name}.tar.bz2"
checksum_path="${archive_path}.sha256"

[[ "$stage_dir" == "${dist_dir}/fluxus-"* ]] || die "unsafe staging path: $stage_dir"
mkdir -p "$dist_dir" "$store_upload_dir"
rm -rf "$stage_dir"
rm -f "$archive_path" "$checksum_path"
mkdir -p "$stage_dir"

cp -a "$package_dir" "$stage_dir/"
cp -a "${repo_dir}/install.sh" "$stage_dir/"
cp -a "${repo_dir}/uninstall.sh" "$stage_dir/"
cp -a "${repo_dir}/README.md" "$stage_dir/"
cp -a "${repo_dir}/CHANGELOG.md" "$stage_dir/"
cp -a "${repo_dir}/LICENSE" "$stage_dir/"
cp -a "${repo_dir}/CMakeLists.txt" "$stage_dir/"
cp -a "${repo_dir}/assets" "$stage_dir/"
cp -a "${repo_dir}/native" "$stage_dir/"
cp -a "${repo_dir}/tests" "$stage_dir/"
cp -a "${repo_dir}/tools" "$stage_dir/"

compiler="$("${CXX:-c++}" --version | sed -n '1p')"
qt_version="$(pkg-config --modversion Qt6Core 2>/dev/null || printf 'unknown')"
cat >"${stage_dir}/BUILD-INFO.txt" <<EOF
Fluxus ${version}
Target: Linux x86_64
Build type: Release
Optimization: -O3 with interprocedural optimization
Architecture flags: -m64 -march=x86-64 -mtune=generic
Compiler: ${compiler}
Qt: ${qt_version}
EOF

staged_plugin="${stage_dir}/package/contents/imports/de/idoc/fluxus/backend/libfluxusbackendplugin.so"
strip --strip-unneeded "$staged_plugin"
file "$staged_plugin" | grep -Fq 'ELF 64-bit LSB shared object, x86-64' \
    || die "staged backend plugin failed x86_64 validation"

tar \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH:-0}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    -C "$dist_dir" \
    -cjf "$archive_path" \
    "$package_name"
(
    cd "$dist_dir"
    sha256sum "$(basename "$archive_path")" >"$(basename "$checksum_path")"
)

cp -a "$archive_path" "$checksum_path" "$store_upload_dir/"
install -m0644 "$store_screenshot" "$store_upload_dir/$(basename "$store_screenshot")"
rm -rf "$stage_dir"

printf '%s\n' "$archive_path"
printf '%s\n' "$checksum_path"
