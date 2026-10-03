#!/usr/bin/env bash
# Builds only the release Web runtime; the development editor stays full-featured.
set -euo pipefail
usage() {
    cat <<'EOF'
usage: tools/build-web-template.sh [--key | --verify] [--jobs N] [--help|-h]

Build the pinned, threadless release template in build/web-template/template.zip.
Requires curl, tar, shasum and uv. Downloads Godot and Emscripten on a cache miss.
  --key       Print the cache key without downloading or writing anything.
  --verify    Check the current template receipt and hash, without building.
  --jobs N    Positive compile worker count (default 4; build mode only).
  --help, -h  Show this help without work.
Example: tools/build-web-template.sh --jobs 8
EOF
}
mode=build
jobs=4
jobs_given=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --key|--verify)
            [[ "$mode" == build ]] || { usage >&2; exit 2; }
            mode="${1#--}"; shift ;;
        --jobs)
            [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ && "$jobs_given" == false ]] || { usage >&2; exit 2; }
            jobs="$2"; jobs_given=true; shift 2 ;;
        *) usage >&2; exit 2 ;;
    esac
done
[[ "$mode" == build || "$jobs_given" == false ]] || { usage >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$root/tools/web-template"
# This is a tracked constants file, never downloaded shell code.
source "$config/pins.env"
hash() { shasum -a 256 "$1" | awk '{print $1}'; }
key="$( { uname -sm; cat "$config/pins.env" "$config/profile.args" "$root/tools/build-web-template.sh"; } | shasum -a 256 | awk '{print $1}')"
out="$root/build/web-template"
valid() {
    [[ -f "$out/template.zip" && -f "$out/receipt" ]] || return 1
    [[ "$(cat "$out/receipt")" == "$key $(hash "$out/template.zip")" ]]
}
if [[ "$mode" == key ]]; then echo "$key"; exit 0; fi
if valid; then echo "Verified custom Web template: $key"; exit 0; fi
if [[ "$mode" == verify ]]; then
    echo 'Custom Web template missing, stale or corrupt; run tools/build-web-template.sh.' >&2
    exit 1
fi
command -v uv >/dev/null || { echo 'uv is required to run pinned SCons.' >&2; exit 1; }
mkdir -p "$out" "$root/build/web-template-work/$key"
touch "$root/build/.gdignore"
work="$root/build/web-template-work/$key"
fetch() {
    local url="$1" destination="$2" expected="$3"
    if [[ ! -f "$destination" ]] || [[ "$(hash "$destination")" != "$expected" ]]; then
        curl --fail --location --retry 3 "$url" -o "$destination.part"
        [[ "$(hash "$destination.part")" == "$expected" ]] || { echo "Checksum mismatch: $url" >&2; exit 1; }
        mv "$destination.part" "$destination"
    fi
}
fetch "https://github.com/godotengine/godot/archive/$GODOT_REVISION.tar.gz" "$work/godot.tar.gz" "$GODOT_SHA256"
fetch "https://github.com/emscripten-core/emsdk/archive/$EMSDK_REVISION.tar.gz" "$work/emsdk.tar.gz" "$EMSDK_SHA256"
if [[ ! -d "$work/godot" ]]; then
    mkdir "$work/godot"
    tar -xzf "$work/godot.tar.gz" --strip-components=1 -C "$work/godot"
fi
if [[ ! -d "$work/emsdk" ]]; then
    mkdir "$work/emsdk"
    tar -xzf "$work/emsdk.tar.gz" --strip-components=1 -C "$work/emsdk"
fi
"$work/emsdk/emsdk" install "$EMSDK_VERSION"
"$work/emsdk/emsdk" activate "$EMSDK_VERSION"
# emsdk_env.sh refers to optional unset variables.
set +u
source "$work/emsdk/emsdk_env.sh"
set -u
emcc --version
args=(platform=web target=template_release arch=wasm32 threads=no production=yes optimize=size lto=thin debug_symbols=no)
while IFS= read -r option; do
    [[ -z "$option" || "$option" == \#* ]] && continue
    [[ "$option" =~ ^[a-z0-9_]+=(yes|no)$ ]] || { echo "Invalid profile option: $option" >&2; exit 1; }
    args+=("$option")
done < "$config/profile.args"
cd "$work/godot"
uv tool run --python 3.14 --from "scons==$SCONS_VERSION" scons -j"$jobs" "${args[@]}"
template="$work/godot/bin/godot.web.template_release.wasm32.nothreads.zip"
[[ -s "$template" ]] || { echo "Missing compiled template: $template" >&2; exit 1; }
cp "$template" "$out/template.zip.part"
mv "$out/template.zip.part" "$out/template.zip"
printf '%s %s\n' "$key" "$(hash "$out/template.zip")" > "$out/receipt"
echo "Built custom Web template: $out/template.zip ($key)"
