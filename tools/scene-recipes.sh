#!/usr/bin/env bash
# Check authored actions headlessly; optionally photograph their saved capture moments.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
usage() {
    cat <<'EOF'
usage: tools/scene-recipes.sh [--help|-h] [--recipe FILE] [--output DIR] [--screenshots]

Run every saved scene (or --recipe FILE) through its headless scripted assertions.
Write logs and manifests to --output DIR (default build/scene-recipes).
--screenshots also uses shot.sh at playback.capture_at seconds after the full simulation
and movement begin. Produces stills only. Example: tools/scene-recipes.sh --screenshots
EOF
}
for arg in "$@"; do
    case "$arg" in --help|-h) usage; exit 0 ;; esac
done
recipe=""
output="$root/build/scene-recipes"
screenshots=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --recipe|--output)
            [[ $# -ge 2 && "$2" != --* ]] || { usage >&2; exit 2; }
            if [[ "$1" == --recipe ]]; then recipe="$2"; else output="$2"; fi
            shift 2 ;;
        --screenshots) screenshots=true; shift ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ -n "$recipe" && ! -f "$recipe" ]]; then usage >&2; exit 2; fi
cd "$root"
recipes=(scene-recipes/*.json)
if [[ -n "$recipe" ]]; then recipes=("$recipe"); fi
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
source "$root/tools/lib_dev_flags.sh"
mkdir -p "$output"
output="$(cd "$output" && pwd)"
for file in "${recipes[@]}"; do
    name="$(basename "$file" .json)"
    "$GODOT" --headless --path "$root" --fixed-fps 60 -- \
        --recipe "$file" --recipe-mode scripted --recipe-manifest "$output/$name.json" \
        --no-save --no-telemetry >"$output/$name.log" 2>&1 &
    pid=$!
    if ! wait_or_kill "$pid" 90 || [[ "$WAIT_OR_KILL_STATUS" -ne 0 ]]; then
        cat "$output/$name.log" >&2
        echo "scene failed: $file" >&2
        exit 1
    fi
    jq -e '.playback_complete == true and all(.observations[]; .passed == true)' \
        "$output/$name.json" >/dev/null
    echo "PASS $name"
    if $screenshots; then
        after="$(jq -r '.playback.capture_at // 0.5' "$file")"
        "$root/tools/shot.sh" "$output/$name.png" "$after" \
            --recipe "$file" --recipe-mode scripted --player-view --no-save \
            --recipe-manifest "$output/$name-capture.json" >"$output/$name-capture.log" 2>&1
    fi
done
