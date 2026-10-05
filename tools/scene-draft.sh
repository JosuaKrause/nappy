#!/usr/bin/env bash
# Draft a task scene's stretch: walk a recipe's own route on its whole city, write what it walked.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
    cat <<'EOF'
usage: tools/scene-draft.sh [--help|-h] --recipe FILE (--output FILE | --in-place)

Walk the recipe's scripted route (playback.walk) once on its whole construction city
(city.context_seed, seed) and write a first-draft "stretch" recipe: every tile of the
street segments she walked, the buildings fronting them, their street trees, props,
litter and cracks, the day's posters on those walls, a starting crowd of walkers and
cars, and the day's route bag, each listed explicitly for the author to edit. A recipe
that already has a stretch is drafted again from its route; the drafted fields are
replaced, but for a route bag already in the recipe, and everything else is kept.
The draft is then checked with --recipe-validate.
--output FILE writes the draft there; --in-place overwrites the recipe itself.
Example: tools/scene-draft.sh --recipe scene-recipes/task-07-package.json --in-place
EOF
}
for arg in "$@"; do
    case "$arg" in --help|-h) usage; exit 0 ;; esac
done
recipe=""
output=""
in_place=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe|--output)
            [[ $# -ge 2 && "$2" != --* ]] || { usage >&2; exit 2; }
            if [[ "$1" == --recipe ]]; then recipe="$2"; else output="$2"; fi
            shift 2 ;;
        --in-place) in_place=true; shift ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ -z "$recipe" ]] || { $in_place && [[ -n "$output" ]]; } || { ! $in_place && [[ -z "$output" ]]; }; then
    usage >&2
    exit 2
fi
if [[ ! -f "$recipe" ]]; then echo "recipe file not found: $recipe" >&2; usage >&2; exit 2; fi
recipe="$(cd "$(dirname "$recipe")" && pwd)/$(basename "$recipe")"
$in_place && output="$recipe"
mkdir -p "$(dirname "$output")"
output="$(cd "$(dirname "$output")" && pwd)/$(basename "$output")"
cd "$root"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
source "$root/tools/lib_dev_flags.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
"$GODOT" --headless --path "$root" --fixed-fps 60 -- \
    --recipe "$recipe" --recipe-mode scripted --recipe-draft "$work/draft.json" \
    --no-save --no-telemetry >"$work/draft.log" 2>&1 &
pid=$!
if ! wait_or_kill "$pid" 120 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]] || [[ ! -s "$work/draft.json" ]]; then
    cat "$work/draft.log" >&2
    echo "scene-draft.sh: the walk did not complete, so nothing was drafted: $recipe" >&2
    exit 1
fi
grep '^\[SceneRecipe\] draft' "$work/draft.log" || true
"$GODOT" --headless --path "$root" --fixed-fps 60 -- \
    --recipe "$work/draft.json" --recipe-mode scripted --recipe-validate \
    --no-save --no-telemetry >"$work/validate.log" 2>&1 &
pid=$!
if ! wait_or_kill "$pid" 90 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
    grep '^\[SceneRecipe\]' "$work/validate.log" | grep -v '^\[SceneRecipe\] manifest' >&2 || cat "$work/validate.log" >&2
    echo "scene-draft.sh: the draft does not validate as a scene; it is kept at $output.rejected for the author" >&2
    cp "$work/draft.json" "$output.rejected"
    exit 1
fi
cp "$work/draft.json" "$output"
echo "drafted $output"
