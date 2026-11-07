#!/usr/bin/env bash
# Renders SVGs with the game's own SVG parser (Godot's Image.load_svg_from_string) at one or more
# scales and puts rulers in asset units around each render, so a position is read off the picture.
# Per SVG and scale it writes two files into --out:
#
#   <name>@<scale>x.png          the raw render: what tools/art-defect-check.py reads
#   <name>@<scale>x-rulers.png   the same over a neutral background with rulers; the one to open
#
# The render runs in a scratch project with no game autoloads, so no import pass is needed first.
set -uo pipefail

usage() {
    cat <<'EOF2'
usage: tools/svg-preview.sh --out DIR [--scale N]... [--grid] [--background HEX] FILE.svg...

Renders each SVG at each --scale (repeatable; default 1 and 3) with Godot's SVG parser and writes,
into DIR, <name>@<scale>x.png (raw) and <name>@<scale>x-rulers.png (rulers in asset units over a
neutral background). Point it at a different Godot binary with GODOT=/path/to/Godot.

  --out DIR          where the pictures are written (created if missing)
  --scale N          pixels per asset unit; give it more than once for more scales
  --grid             a faint line across the picture at each labelled ruler step
  --background HEX   six-digit hex colour under transparency in the ruled picture (8a8a8a)
  --help, -h         this text

  tools/svg-preview.sh --out /tmp/preview --scale 3 --grid art/events/pipe.svg
EOF2
}

die() {
    echo "svg-preview.sh: $*" >&2
    echo >&2
    usage >&2
    exit 2
}

out=""
scales=()
grid=()
background=()
files=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --out)
            [[ $# -ge 2 ]] || die "--out needs a directory"
            out="$2"; shift 2 ;;
        --scale)
            [[ $# -ge 2 ]] || die "--scale needs a number"
            [[ "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "--scale must be a positive number, got: $2"
            [[ "$2" != *[1-9]* ]] && die "--scale must be positive, got: $2"
            scales+=("$2"); shift 2 ;;
        --grid) grid=(--grid); shift ;;
        --background)
            [[ $# -ge 2 ]] || die "--background needs a hex colour"
            [[ "$2" =~ ^#?[0-9a-fA-F]{6}$ ]] || die "--background must be a six-digit hex colour, got: $2"
            background=(--background "$2"); shift 2 ;;
        -*) die "unknown flag: $1" ;;
        *) files+=("$1"); shift ;;
    esac
done

[[ -n "$out" ]] || die "--out is required"
[[ ${#files[@]} -gt 0 ]] || die "no SVG files given"
for f in "${files[@]}"; do
    [[ "$f" == *.svg ]] || die "not an SVG: $f"
    [[ -f "$f" ]] || die "no such file: $f"
done
[[ ${#scales[@]} -gt 0 ]] || scales=(1 3)

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -x "$GODOT" ]]; then
    echo "godot not found at $GODOT (override with GODOT=...)" >&2
    exit 127
fi

mkdir -p "$out" || exit 1
out="$(cd "$out" && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
printf 'config_version=5\n\n[application]\nconfig/name="svg-preview"\n' > "$scratch/project.godot"

abs_files=()
for f in "${files[@]}"; do
    abs_files+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
done
scale_list="$(IFS=,; echo "${scales[*]}")"

output="$("$GODOT" --headless --path "$scratch" --script "$PROJECT_DIR/tools/svg_preview_render.gd" \
    -- "$out" "$scale_list" "${abs_files[@]}" 2>&1)"
status=$?
echo "$output"
if [[ $status -ne 0 ]] || grep -qE "SCRIPT ERROR|SVG render failed|PNG save failed" <<<"$output"; then
    echo "svg-preview.sh: the render failed" >&2
    exit 1
fi

for f in "${files[@]}"; do
    name="$(basename "$f" .svg)"
    for s in "${scales[@]}"; do
        raw="$out/$name@${s}x.png"
        if [[ ! -f "$raw" ]]; then
            echo "svg-preview.sh: expected render $raw is missing" >&2
            exit 1
        fi
        uv run python "$PROJECT_DIR/tools/art-rulers.py" --scale "$s" ${grid[@]+"${grid[@]}"} ${background[@]+"${background[@]}"} \
            "$raw" "${raw%.png}-rulers.png" || exit 1
    done
done
