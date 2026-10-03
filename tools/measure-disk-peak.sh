#!/usr/bin/env bash
# Run one command and report the peak additional disk allocation it made, the measurement
# tools/lib_disk_headroom.sh's per-job estimates are taken from.
#
#   tools/measure-disk-peak.sh --path build/web -- tools/export-web.sh debug
#
# **Allocated, not exclusive.** `du -sk` counts the blocks each named path holds, which on APFS
# includes copy-on-write clones that share blocks with other files, so the peak it reports is an
# upper bound on what the job takes from the volume rather than an exact figure. `df` on the first
# path's volume is sampled beside it as the volume's own view, and it moves with every other
# process writing to the same disk, so the two are read together and neither alone. A path that
# does not exist yet counts as zero; one the command deletes before the end counts as what it
# held when last sampled.
#
# Bash 3.2-safe, like the rest of tools/.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/measure-disk-peak.sh [--help|-h] [--interval SECONDS] [--output FILE]
                                  --path DIR [--path DIR]... -- COMMAND [ARG...]

Runs COMMAND while sampling the allocated KiB (du -sk) of every --path and the available KiB
(df -Pk) on the volume holding the first --path. Prints each path's baseline, peak and final
size, the peak of their sum above its baseline (the job's peak additional allocation), and the
largest drop in the volume's available space. Exits with COMMAND's own status.

  --path DIR          a destination the command writes to; repeat for several. Need not exist.
  --interval SECONDS  sampling period, a positive number (default 1)
  --output FILE       also write the summary as JSON to FILE, which must not exist yet

Nothing is written except FILE. Sizes are allocated blocks, which can count shared clone blocks,
so the figure is an upper bound on what the job takes from the volume.

  tools/measure-disk-peak.sh --path build/web -- tools/export-web.sh debug
EOF
}

paths=()
interval=1
output=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --path)
            [[ $# -ge 2 && -n "$2" && "$2" != -* ]] || { usage >&2; exit 2; }
            paths+=("$2"); shift 2 ;;
        --interval)
            [[ $# -ge 2 && "$2" =~ ^[0-9]+([.][0-9]+)?$ && "$2" != 0 && ! "$2" =~ ^0+([.]0+)?$ ]] \
                || { usage >&2; exit 2; }
            interval="$2"; shift 2 ;;
        --output)
            [[ $# -ge 2 && -n "$2" && "$2" != -* && -z "$output" ]] || { usage >&2; exit 2; }
            output="$2"; shift 2 ;;
        --) shift; break ;;
        *) usage >&2; exit 2 ;;
    esac
done
if [[ ${#paths[@]} -eq 0 || $# -eq 0 ]]; then
    usage >&2
    exit 2
fi
if [[ -n "$output" && -e "$output" ]]; then
    echo "measure-disk-peak.sh: --output $output already exists; refusing to overwrite it" >&2
    exit 2
fi

# The nearest existing ancestor, so df can be asked about a destination not created yet.
existing_ancestor() {
    local path="$1"
    while [[ ! -e "$path" ]]; do
        path="$(dirname "$path")"
    done
    printf '%s\n' "$path"
}

allocated_kib() {
    local path="$1" size
    [[ -e "$path" ]] || { echo 0; return; }
    size="$(du -sk "$path" 2>/dev/null | awk 'NR==1 {print $1}')"
    printf '%s\n' "${size:-0}"
}

available_kib() {
    df -Pk "$(existing_ancestor "$1")" 2>/dev/null | awk 'NR==2 {print $4}'
}

count=${#paths[@]}
baseline=() peak=() last=()
baseline_sum=0
for ((i=0; i<count; i++)); do
    size="$(allocated_kib "${paths[$i]}")"
    baseline+=("$size"); peak+=("$size"); last+=("$size")
    baseline_sum=$(( baseline_sum + size ))
done
peak_sum=$baseline_sum
available_start="$(available_kib "${paths[0]}")"
available_min="$available_start"
samples=0

sample() {
    local i size sum=0 available
    for ((i=0; i<count; i++)); do
        size="$(allocated_kib "${paths[$i]}")"
        last[$i]=$size
        (( size > peak[$i] )) && peak[$i]=$size
        sum=$(( sum + size ))
    done
    (( sum > peak_sum )) && peak_sum=$sum
    available="$(available_kib "${paths[0]}")"
    if [[ -n "$available" ]] && (( available < available_min )); then
        available_min=$available
    fi
    samples=$(( samples + 1 ))
}

started="$(date +%s)"
"$@" &
pid=$!
# A Ctrl-C reaches the command too; the summary is still printed for what was sampled.
trap 'kill -INT "$pid" 2>/dev/null' INT
trap 'kill -TERM "$pid" 2>/dev/null' TERM
while kill -0 "$pid" 2>/dev/null; do
    sample
    sleep "$interval"
done
wait "$pid"
status=$?
sample
elapsed=$(( $(date +%s) - started ))
available_end="$(available_kib "${paths[0]}")"

final_sum=0
for ((i=0; i<count; i++)); do final_sum=$(( final_sum + last[$i] )); done
peak_additional=$(( peak_sum - baseline_sum ))
df_drop=$(( available_start - available_min ))

echo "measure-disk-peak: command exited $status after ${elapsed}s, $samples samples every ${interval}s"
for ((i=0; i<count; i++)); do
    printf '  %s: baseline %s KiB, peak %s KiB, final %s KiB\n' \
        "${paths[$i]}" "${baseline[$i]}" "${peak[$i]}" "${last[$i]}"
done
printf '  peak additional allocation: %s KiB (%s MiB)\n' "$peak_additional" $(( (peak_additional + 1023) / 1024 ))
printf '  retained after the command: %s KiB\n' $(( final_sum - baseline_sum ))
printf '  volume available: start %s KiB, minimum %s KiB (largest drop %s KiB), end %s KiB\n' \
    "$available_start" "$available_min" "$df_drop" "$available_end"

if [[ -n "$output" ]]; then
    {
        printf '{\n  "command": ['
        sep=""
        for arg in "$@"; do
            printf '%s"%s"' "$sep" "$(printf '%s' "$arg" | sed 's/\\/\\\\/g; s/"/\\"/g')"
            sep=", "
        done
        printf '],\n  "exit_status": %s,\n  "elapsed_seconds": %s,\n' "$status" "$elapsed"
        printf '  "interval_seconds": %s,\n  "samples": %s,\n  "paths": [\n' "$interval" "$samples"
        for ((i=0; i<count; i++)); do
            printf '    {"path": "%s", "baseline_kib": %s, "peak_kib": %s, "final_kib": %s}%s\n' \
                "$(printf '%s' "${paths[$i]}" | sed 's/\\/\\\\/g; s/"/\\"/g')" \
                "${baseline[$i]}" "${peak[$i]}" "${last[$i]}" "$([[ $i -lt $((count - 1)) ]] && echo ,)"
        done
        printf '  ],\n  "peak_additional_kib": %s,\n  "retained_kib": %s,\n' \
            "$peak_additional" $(( final_sum - baseline_sum ))
        printf '  "available_start_kib": %s,\n  "available_min_kib": %s,\n  "available_end_kib": %s\n}\n' \
            "${available_start:-null}" "${available_min:-null}" "${available_end:-null}"
    } > "$output"
fi
exit "$status"
