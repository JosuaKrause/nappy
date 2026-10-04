#!/usr/bin/env bash
# Release Web export of the checked-out tree with Godot's *stock* nothreads release template, into
# the directory given (which is replaced). tools/export-web.sh release needs the custom template
# (tools/build-web-template.sh); this run predates nothing that needs it, and every release before
# the custom template was exported this way. export_presets.cfg is put back on every exit.
set -uo pipefail
[[ $# -eq 1 && "$1" != -* ]] || { echo "usage: export-stock-release.sh OUT_DIR" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
godot="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
out="$1"
presets="$root/export_presets.cfg"
backup="$(mktemp)"
cp "$presets" "$backup"
trap 'cp "$backup" "$presets"; rm -f "$backup"' EXIT
anchor='custom_template/release="build/web-template/template.zip"'
[[ "$(grep -c "^$anchor\$" "$presets")" == 1 ]] || { echo "anchor not found once: $anchor" >&2; exit 1; }
sed -e "s|^$anchor\$|custom_template/release=\"\"|" "$backup" > "$presets"
grep -q '^custom_template/release=""$' "$presets" || { echo "preset not rewritten" >&2; exit 1; }
rm -rf "$out" && mkdir -p "$out"
"$godot" --headless --path "$root" --export-release Web "$out/index.html" > "$out.log" 2>&1
status=$?
echo "export exit $status (log: $out.log)"
exit $status
