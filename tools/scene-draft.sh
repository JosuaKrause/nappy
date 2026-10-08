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
The draft is then played as the scene it is; a body it puts to wait on ground the
stretch cut off has that tile added to draft.include and the stretch is drafted again
(three rounds at most; guards still there after them fail the tool, as does a round
that crashes, with the draft kept as FILE.rejected). The draft is then checked with
--recipe-validate.
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
cp "$recipe" "$work/input.json"
# Each round drafts from the input, then plays the draft as the scene it is: a body the scene puts to
# wait on ground the stretch cut off (the manifest's `in_the_void`) has its tile added to the input's
# `draft.include`, and the stretch is drafted again, so nothing waiting for her stands in the void.
# Three rounds at most; guards still in the void after them, or a round whose play crashed, fail
# the tool with the draft kept aside as $output.rejected. The draft's own walk is
# --invincible: it walks the whole city, where a guard the stretch never puts out may catch her, and
# only the tiles she walks are wanted from it.
for round in 1 2 3; do
    rm -f "$work/draft.json"
    "$GODOT" --headless --path "$root" --fixed-fps 60 -- \
        --recipe "$work/input.json" --recipe-mode scripted --recipe-draft "$work/draft.json" \
        --invincible --no-save --no-telemetry >"$work/draft.log" 2>&1 &
    pid=$!
    if ! wait_or_kill "$pid" 120 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]] || [[ ! -s "$work/draft.json" ]] \
            || grep -qE 'SCRIPT ERROR|^ERROR:' "$work/draft.log"; then
        cat "$work/draft.log" >&2
        echo "scene-draft.sh: the walk did not complete, so nothing was drafted: $recipe" >&2
        exit 1
    fi
    rm -f "$work/scene.json"
    # Ground coverage needs the whole walk, including what happens after an unmet observation or
    # a task's pursuing guard catches her. Assertions are checked on the final authored scene.
    jq '.playback.observations = []' "$work/draft.json" >"$work/coverage.json"
    "$GODOT" --headless --path "$root" --fixed-fps 60 -- \
        --recipe "$work/coverage.json" --recipe-mode scripted --recipe-manifest "$work/scene.json" \
        --invincible --no-save --no-telemetry >"$work/scene.log" 2>&1 &
    pid=$!
    # A scene whose own observations go unmet still says where it put its guards, and the author
    # fixes the walk after; one that crashed, hung or wrote no manifest says nothing, and the draft
    # is kept aside rather than written as if it had answered.
    wait_or_kill "$pid" 120 || true
    if [[ "${WAIT_OR_KILL_STATUS:-1}" -ne 0 ]]; then
        crashed=true
    else
        crashed=false
    fi
    if $crashed || grep -qE 'SCRIPT ERROR|^ERROR:' "$work/scene.log" \
            || ! void="$(jq -ec 'select(.playback_complete == true) | [.in_the_void // [] | .[].tile]' "$work/scene.json" 2>/dev/null)"; then
        cat "$work/scene.log" >&2
        cp "$work/draft.json" "$output.rejected"
        echo "scene-draft.sh: round $round's play of the draft crashed or wrote no manifest; the draft is kept at $output.rejected" >&2
        exit 1
    fi
    grep '^\[SceneRecipe\] unmet observation' "$work/scene.log" | sed 's/^/scene-draft.sh: the draft as a scene: /' >&2 || true
    new="$(jq -c --argjson void "$void" '($void - (.draft.include // [])) | unique' "$work/input.json")"
    [[ "$void" == "[]" ]] && break
    if [[ "$round" == 3 || "$new" == "[]" ]]; then
        cp "$work/draft.json" "$output.rejected"
        echo "scene-draft.sh: after three rounds the scene still puts guards on cut-off ground at $new; the draft is kept at $output.rejected" >&2
        exit 1
    fi
    jq --argjson new "$new" '.draft.include = ((.draft.include // []) + $new)' "$work/input.json" \
        >"$work/next.json" && mv "$work/next.json" "$work/input.json"
done
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
