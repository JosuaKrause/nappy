#!/usr/bin/env bash
# Matched native rendered-city timings; owned detached checkouts are removed on exit.
set -euo pipefail

usage() {
    cat <<'EOF'
usage: tools/measure-ground-frames.sh --godot PATH [--output NEW_DIR] [--help|-h]

Compare pinned atomic, global-section-cap and per-region ground runtimes with one collector.
Runs one warmup per strategy, then three rotated interleaved trials each, serially.
Requires git, jq, shasum and a native display; retain results.json and source manifests.
Full logs and per-frame CSV files remain in the fresh scratch directory.

  --godot PATH       Godot executable (or set GODOT); relative paths use caller's directory.
  --output NEW_DIR   Fresh scratch directory, relative to caller (default: mktemp directory).
  --help, -h         Print help without creating files or launching Godot.

Fetch capture revisions first: git fetch origin refs/pull/452/head
Example: tools/measure-ground-frames.sh --godot /path/to/Godot --output ./ground-measurement
EOF
}
fail() { echo "measure-ground-frames: $*" >&2; exit 1; }
bad() { echo "measure-ground-frames: $*" >&2; usage >&2; exit 2; }
engine="${GODOT:-}"
output=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --godot|--output)
            [[ $# -ge 2 && -n "$2" && "$2" != -* ]] || bad "$1 requires a value"
            if [[ "$1" == --godot ]]; then engine="$2"; else output="$2"; fi
            shift 2 ;;
        *) bad "unknown argument: $1" ;;
    esac
done
[[ -n "$engine" ]] || bad "supply --godot or GODOT"
[[ "$engine" == /* ]] || engine="$PWD/$engine"
[[ -x "$engine" ]] || fail "not executable: $engine"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
names=(atomic global per-region)
revisions=(aae5c189bfe3a7d23530c6f06d17712c7d043807 59b5e6baee8300a6478e4e481c4de4dc7e996496 a64abc1cf6f022cbb57e1a5e04edd7602f6f1adf)
collector_files=(tests/probes/ground_frames_matched.gd tests/probes/ground_frames_matched.gd.uid tests/probes/ground_frames_matched.tscn)
collector_revision="$(git -C "$root" rev-parse HEAD)"
git -C "$root" diff --quiet && git -C "$root" diff --cached --quiet || fail "collector checkout has tracked changes"
for file in "${collector_files[@]}"; do
    git -C "$root" cat-file -e "HEAD:$file" || fail "collector must be committed: $file"
done
for revision in "${revisions[@]}"; do git -C "$root" cat-file -e "$revision^{commit}"; done
for executable in jq shasum; do command -v "$executable" >/dev/null || fail "missing $executable"; done
if [[ -n "$output" ]]; then
    [[ "$output" == /* ]] || output="$PWD/$output"
    [[ ! -e "$output" ]] || fail "output already exists: $output"
    mkdir "$output"
else
    output="$(mktemp -d "${TMPDIR:-/tmp}/ground-matched.XXXXXX")"
fi
output="$(cd "$output" && pwd)"
trees=()
child=""
watchdog=""
cleanup() {
    local tree file
    [[ -z "$child" ]] || kill "$child" 2>/dev/null || true
    [[ -z "$watchdog" ]] || kill "$watchdog" 2>/dev/null || true
    for tree in "${trees[@]+"${trees[@]}"}"; do
        if git -C "$tree" diff --quiet && git -C "$tree" diff --cached --quiet; then
            for file in "${collector_files[@]}"; do rm -f "$tree/$file"; done
            git -C "$root" worktree remove "$tree" || echo "retained unexpected files: $tree" >&2
        else
            echo "retained dirty measurement checkout: $tree" >&2
        fi
    done
    echo "Measurement artifacts: $output"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
snapshot() {
    local tree="$1"
    git -C "$tree" diff --quiet && git -C "$tree" diff --cached --quiet || fail "tracked runtime changed: $tree"
    (cd "$tree"; git ls-files src scenes project.godot assets | LC_ALL=C sort | while IFS= read -r file; do shasum -a 256 "$file"; done)
}
validate() {
    local index="$1" file
    snapshot "${trees[$index]}" > "$output/check.sha256"
    cmp "$output/check.sha256" "$output/${names[$index]}.runtime.sha256"
    for file in "${collector_files[@]}"; do cmp "$root/$file" "${trees[$index]}/$file"; done
}
for index in 0 1 2; do
    tree="$output/tree-${names[$index]}"
    git -C "$root" worktree add --detach "$tree" "${revisions[$index]}"
    trees+=("$tree")
    for file in "${collector_files[@]}"; do
        [[ ! -e "$tree/$file" ]] || fail "collector path already exists: $file"
        cp "$root/$file" "$tree/$file"
    done
    echo "Import ${names[$index]}"
    GODOT="$engine" "$tree/tools/check.sh" > "$output/${names[$index]}.setup.log" 2>&1
    snapshot "$tree" > "$output/${names[$index]}.runtime.sha256"
    validate "$index"
done
printf 'order\tstrategy\ttrial\twarmup\tsource_revision\n' > "$output/order.tsv"
run_order=0
capture() {
    local index="$1" trial="$2" warmup="$3" label digest status
    label="$(printf '%02d' "$run_order")-${names[$index]}-$trial"
    validate "$index"
    digest="$(shasum -a 256 "$output/${names[$index]}.runtime.sha256" | cut -d ' ' -f 1)"
    printf '%s\t%s\t%s\t%s\t%s\n' "$run_order" "${names[$index]}" "$trial" "$warmup" "${revisions[$index]}" >> "$output/order.tsv"
    echo "Capture $label (warmup=$warmup)"
    GROUND_MATCH_OUTPUT="$output/$label.json" GROUND_MATCH_STRATEGY="${names[$index]}" \
        GROUND_MATCH_TRIAL="$trial" GROUND_MATCH_RUN_ORDER="$run_order" \
        GROUND_MATCH_SOURCE_REVISION="${revisions[$index]}" GROUND_MATCH_COLLECTOR_REVISION="$collector_revision" \
        GROUND_MATCH_RUNTIME_DIGEST="$digest" "$engine" --path "${trees[$index]}" \
        --disable-vsync --resolution 1280x720 res://tests/probes/ground_frames_matched.tscn \
        -- --no-save --no-telemetry > "$output/$label.log" 2>&1 &
    child=$!
    (sleep 150; kill "$child" 2>/dev/null) &
    watchdog=$!
    status=0
    wait "$child" || status=$?
    child=""
    kill "$watchdog" 2>/dev/null || true
    wait "$watchdog" 2>/dev/null || true
    watchdog=""
    validate "$index"
    if [[ $status -ne 0 || ! -s "$output/$label.json" ]] \
            || grep -qE 'ERROR:|SCRIPT ERROR|WARNING:' "$output/$label.log" \
            || ! jq -e '.failures == []' "$output/$label.json" >/dev/null; then
        printf '%s\t%s\n' "$label" "exit=$status; see retained log/result" >> "$output/rejected.tsv"
        fail "capture rejected: $label"
    fi
    if [[ "$warmup" == false ]]; then accepted+=("$output/$label.json"); fi
    run_order=$((run_order + 1))
}
accepted=()
for index in 0 1 2; do capture "$index" warmup true; done
for trial in 0 1 2; do
    for slot in 0 1 2; do capture "$(((trial + slot) % 3))" "$trial" false; done
done
jq -s --arg collector_revision "$collector_revision" \
    '{collector_revision:$collector_revision, rejected:[], trials:., order:"order.tsv", runtime_manifests:"*.runtime.sha256"}' \
    "${accepted[@]}" > "$output/results.json"
echo "All nine retained captures passed. Compact results: $output/results.json"
