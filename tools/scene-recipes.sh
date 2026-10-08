#!/usr/bin/env bash
# Check authored actions headlessly; optionally photograph their saved capture moments.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
    cat <<'EOF'
usage: tools/scene-recipes.sh [--help|-h] [--recipe FILE] [--output DIR] [--screenshots]

Run every saved scene (or each repeated --recipe FILE) through its headless scripted assertions.
Write logs and manifests to --output DIR (default build/scene-recipes).
--screenshots also uses shot.sh twice per scene: NAME-start.png a tenth of a second in, and
NAME.png at playback.capture_at seconds after the full simulation and movement begin.
Retains the relevant stills, action/capture manifests and small logs only.
Example: tools/scene-recipes.sh --screenshots
EOF
}
for arg in "$@"; do
    case "$arg" in --help|-h) usage; exit 0 ;; esac
done
selected_recipes=()
output="$root/build/scene-recipes"
screenshots=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe|--output)
            [[ $# -ge 2 && "$2" != --* ]] || { usage >&2; exit 2; }
            if [[ "$1" == --recipe ]]; then selected_recipes+=("$2"); else output="$2"; fi
            shift 2 ;;
        --screenshots) screenshots=true; shift ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ ${#selected_recipes[@]} -gt 0 ]]; then
    for ((index=0; index<${#selected_recipes[@]}; index++)); do
        recipe="${selected_recipes[$index]}"
        if [[ ! -f "$recipe" ]]; then echo "recipe file not found: $recipe" >&2; usage >&2; exit 2; fi
        selected_recipes[$index]="$(cd "$(dirname "$recipe")" && pwd)/$(basename "$recipe")"
    done
fi
recipes=("$root"/scene-recipes/*.json)
if [[ ${#selected_recipes[@]} -gt 0 ]]; then recipes=("${selected_recipes[@]}"); fi
# The whole batch is checked before its first log is written: a recipe's logs and manifests, or,
# with --screenshots, those and its still.
source "$root/tools/lib_disk_headroom.sh"
headroom_job=scene-recipe
$screenshots && headroom_job=scene-capture
headroom_hint=""
[[ ${#recipes[@]} -gt 1 ]] && headroom_hint="run fewer recipes, each named with --recipe FILE"
# Two stills a scene with --screenshots, its start and its capture moment.
headroom_jobs=${#recipes[@]}
$screenshots && headroom_jobs=$(( ${#recipes[@]} * 2 ))
headroom_preflight tools/scene-recipes.sh "$output" "$headroom_hint" "$headroom_job:$headroom_jobs" || exit 1
mkdir -p "$output"
output="$(cd "$output" && pwd)"
cd "$root"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
source "$root/tools/lib_dev_flags.sh"
for file in "${recipes[@]}"; do
    name="$(basename "$file" .json)"
    "$GODOT" --headless --path "$root" --fixed-fps 60 -- \
        --recipe "$file" --recipe-mode scripted --recipe-manifest "$output/$name.json" \
        --no-save --no-telemetry >"$output/$name.log" 2>&1 &
    pid=$!
    if ! wait_or_kill "$pid" 90 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
        cat "$output/$name.log" >&2
        echo "scene failed: $file (log: $output/$name.log)" >&2
        exit 1
    fi
    if grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$output/$name.log" || ! jq -e \
        '.playback_complete == true and all(.observations[]; .passed == true)
         and ((.in_the_void // []) | length == 0) and ((.seen_to_jump // []) | length == 0)' \
        "$output/$name.json" >/dev/null; then
        echo "scene assertions failed: $file (manifest: $output/$name.json; log: $output/$name.log)" >&2
        exit 1
    fi
    echo "PASS $name"
    if $screenshots; then
        if ! after="$(jq -er '.playback.capture_at // 0.5' "$file")"; then
            echo "invalid capture time: $file (log: $output/$name.log)" >&2
            exit 1
        fi
        for still in "start:0.1" "late:$after"; do
            at="${still#*:}"
            stem="$name"
            [[ "${still%%:*}" == start ]] && stem="$name-start"
            if ! "$root/tools/shot.sh" "$output/$stem.png" "$at" \
                --recipe "$file" --recipe-mode scripted --player-view --no-save \
                --recipe-manifest "$output/$stem-capture.json" >"$output/$stem-capture.log" 2>&1; then
                echo "scene capture failed: $file (log: $output/$stem-capture.log)" >&2
                exit 1
            fi
            if grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$output/$stem-capture.log"; then
                echo "scene capture engine error: $file (log: $output/$stem-capture.log)" >&2
                exit 1
            fi
            run_log="$(sed -n 's/^\[Telemetry\] //p' "$output/$stem-capture.log")"
            if [[ -z "$run_log" || ! -f "$run_log" ]]; then
                echo "scene capture has no complete telemetry provenance: $file (log: $output/$stem-capture.log)" >&2
                exit 1
            fi
        done
    fi
done
