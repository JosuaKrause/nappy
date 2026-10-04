#!/usr/bin/env bash
# Matched native rendered-city timings; the owned detached checkout is removed on exit.
set -euo pipefail

usage() {
    cat <<'EOF'
usage: tools/measure-ground-frames.sh --godot PATH [--output NEW_DIR] [--help|-h]

Compare the three ground preparation modes (--ground-mode 1, 2 and 3: every needed region
whole in its frame, at most one whole region a frame, one region stepped across frames) of
this checkout's committed HEAD, in one clean detached checkout, with one collector.
Runs one warmup per mode, then three rotated interleaved trials each, serially. A capture
waits for every other engine process (one named Godot or named as --godot's binary) to end
first, and one another engine ran beside is kept under a rejected name and taken again in the
same slot, up to five attempts.
Requires git, jq, shasum and a native display; retain results.json and the source manifest.
Full logs and per-frame CSV files remain in the fresh scratch directory.

  --godot PATH       Godot executable (or set GODOT); relative paths use caller's directory.
  --output NEW_DIR   Fresh scratch directory, relative to caller (default: mktemp directory).
  --help, -h         Print help without creating files or launching Godot.

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
engine_name="$(basename "$engine")"
# Every running engine process but the one given: anything whose program is named `Godot` (the
# macOS app's binary) or the same name as --godot's, read from each process's own argv[0], so an
# engine installed under another name is seen as well. An argv[0] with a space in it is not.
other_engines() {
    ps -axo pid=,args= | awk -v name="$engine_name" -v self="${1:-}" '{
        program = $2; sub(/.*\//, "", program)
        if ((program == "Godot" || program == name) && $1 != self) print $1
    }'
}
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$root"
# shellcheck source=tools/lib_dev_flags.sh
source "$root/tools/lib_dev_flags.sh"
names=(mode1-all mode2-one mode3-stepped)
modes=(1 2 3)
collector_files=(tests/probes/ground_frames_matched.gd tests/probes/ground_frames_matched.gd.uid tests/probes/ground_frames_matched.tscn)
revision="$(git -C "$root" rev-parse HEAD)"
git -C "$root" diff --quiet && git -C "$root" diff --cached --quiet || fail "checkout has tracked changes"
for file in "${collector_files[@]}"; do
    git -C "$root" cat-file -e "HEAD:$file" || fail "collector must be committed: $file"
done
for executable in jq shasum; do command -v "$executable" >/dev/null || fail "missing $executable"; done
if [[ -n "$output" ]]; then
    [[ "$output" == /* ]] || output="$PWD/$output"
    [[ ! -e "$output" ]] || fail "output already exists: $output"
    mkdir "$output"
else
    output="$(mktemp -d "${TMPDIR:-/tmp}/ground-matched.XXXXXX")"
fi
output="$(cd "$output" && pwd)"
tree=""
child=""
sampler=""
cleanup() {
    [[ -z "$child" ]] || kill "$child" 2>/dev/null || true
    [[ -z "$sampler" ]] || kill "$sampler" 2>/dev/null || true
    if [[ -n "$tree" ]]; then
        if git -C "$tree" diff --quiet && git -C "$tree" diff --cached --quiet; then
            git -C "$root" worktree remove "$tree" || echo "retained unexpected files: $tree" >&2
        else
            echo "retained dirty measurement checkout: $tree" >&2
        fi
    fi
    echo "Measurement artifacts: $output"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
# The collector is committed in the measured revision, so one manifest covers runtime and
# collector alike, and every mode runs the identical bytes.
snapshot() {
    local at="$1"
    git -C "$at" diff --quiet && git -C "$at" diff --cached --quiet || fail "tracked runtime changed: $at"
    (cd "$at"; git ls-files src scenes project.godot assets "${collector_files[@]}" | LC_ALL=C sort | while IFS= read -r file; do shasum -a 256 "$file"; done)
}
validate() {
    snapshot "$tree" > "$output/check.sha256"
    cmp "$output/check.sha256" "$output/runtime.sha256"
}
tree="$output/tree"
git -C "$root" worktree add --detach "$tree" "$revision"
echo "Import $revision"
GODOT="$engine" "$tree/tools/check.sh" > "$output/setup.log" 2>&1
snapshot "$tree" > "$output/runtime.sha256"
validate
digest="$(shasum -a 256 "$output/runtime.sha256" | cut -d ' ' -f 1)"
printf 'order\tattempt\tmode\ttrial\twarmup\tsource_revision\tload_average_before\n' > "$output/order.tsv"
run_order=0
# Another engine (a test run from another checkout, say) competes for the same cores and GPU. A
# capture waits up to five minutes for every other Godot process to end before it starts; one
# that another engine ran beside is kept under a rejected name, recorded in rejected.tsv, and the
# same slot is captured again, up to five attempts, so the order and the mode's trial stay put.
capture() {
    local index="$1" trial="$2" warmup="$3" label attempt status fifo others file
    label="$(printf '%02d' "$run_order")-${names[$index]}-$trial"
    for attempt in 1 2 3 4 5; do
        validate
        for _ in $(seq 300); do
            others="$(other_engines | tr '\n' ' ')"
            others="${others% }"
            [[ -n "$others" ]] || break
            sleep 1
        done
        [[ -z "$others" ]] || fail "another Godot process is running ($others); retry once it ends"
        # Other work on the machine shows in the load average even when it is not an engine.
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$run_order" "$attempt" "${names[$index]}" "$trial" \
            "$warmup" "$revision" "$(uptime | sed 's/.*load averages*: //')" >> "$output/order.tsv"
        echo "Capture $label attempt $attempt (warmup=$warmup)"
        rm -f "$output/competition.tmp"
        GROUND_MATCH_OUTPUT="$output/$label.json" GROUND_MATCH_STRATEGY="${names[$index]}" \
            GROUND_MATCH_TRIAL="$trial" GROUND_MATCH_RUN_ORDER="$run_order" \
            GROUND_MATCH_SOURCE_REVISION="$revision" GROUND_MATCH_COLLECTOR_REVISION="$revision" \
            GROUND_MATCH_RUNTIME_DIGEST="$digest" "$engine" --path "$tree" \
            --disable-vsync --resolution 1280x720 res://tests/probes/ground_frames_matched.tscn \
            -- --no-save --no-telemetry --ground-mode "${modes[$index]}" > "$output/$label.log" 2>&1 &
        child=$!
        # The sampler looks once a second for another Godot process while the capture runs. It
        # paces itself on a timed `read` of a FIFO, never a `sleep`, for the reason
        # `wait_or_kill`'s own watchdog does: a forked `sleep` outlives a kill of its subshell and
        # holds this script's output open. One line releases it once the capture has exited.
        fifo="$output/sampler.fifo"
        rm -f "$fifo"
        mkfifo "$fifo"
        exec 8<>"$fifo"
        (
            for _ in $(seq 200); do
                if read -r -t 1 <&8; then exit 0; fi
                other_engines "$child" >> "$output/competition.tmp"
            done
        ) &
        sampler=$!
        # tools/lib_dev_flags.sh's watchdog kills a capture still running after 150 seconds; its
        # exit status is the capture's either way.
        wait_or_kill "$child" 150 || true
        status=$WAIT_OR_KILL_STATUS
        child=""
        echo >&8
        wait "$sampler" 2>/dev/null || true
        sampler=""
        exec 8>&-
        rm -f "$fifo"
        if [[ ! -s "$output/competition.tmp" ]]; then
            break
        fi
        printf '%s\t%s\n' "$label" "attempt $attempt: another Godot process ran during the capture" \
            >> "$output/rejected.tsv"
        for file in "$output/$label".*; do
            [[ "$file" != *-rejected* ]] || continue
            mv "$file" "${file/$label/$label.attempt$attempt-rejected}"
        done
        [[ $attempt -lt 5 ]] || fail "capture rejected: another Godot process ran during every attempt at $label"
    done
    validate
    # The collector reports the mode the city actually ran, so a flag that did not arrive
    # rejects the capture rather than measuring the default three times.
    if [[ $status -ne 0 || ! -s "$output/$label.json" ]] \
            || grep -qE 'ERROR:|SCRIPT ERROR|WARNING:' "$output/$label.log" \
            || ! jq -e --argjson mode "${modes[$index]}" \
                '.failures == [] and .ground_mode == $mode and .forced_draws == 0' \
                "$output/$label.json" >/dev/null; then
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
jq -s --arg revision "$revision" \
    '{source_revision:$revision, collector_revision:$revision, rejected:[], trials:., order:"order.tsv", runtime_manifest:"runtime.sha256"}' \
    "${accepted[@]}" > "$output/results.json"
if ! jq -e '[.trials[].cases[]] | group_by(.name) | all(.[];
        ([.[].steady_workload.cell_sha256] | unique | length) == 1 and
        ([.[].steady_pixel_sha256] | unique | length) == 1)' "$output/results.json" >/dev/null; then
    printf 'comparison\tsteady cell or pixel hashes differ; inspect all retained trials\n' >> "$output/rejected.tsv"
    jq '.rejected = ["cross-mode steady cell or pixel mismatch"]' "$output/results.json" > "$output/rejected-results.json"
    mv "$output/rejected-results.json" "$output/results.json"
    fail "cross-mode workload check failed"
fi
echo "All nine retained captures passed. Compact results: $output/results.json"
