"""Print the tables of a measure.py run from its results.json: frame-time distributions per
condition for the cost part, and the frame record's slow-frame split for the modes part."""

import json
import statistics
import sys
from pathlib import Path


def accepted(results, part):
    return [entry for entry in results
            if not entry.get("rejected") and entry.get("part") == part and entry["trial"] != "warmup"]


def cost_tables(results):
    runs = accepted(results, "cost")
    if not runs:
        return
    print("### Frame length per run (ms, VSync off, --frame-trace)\n")
    print("| condition | run | frames | mean | p50 | p95 | p99 | worst | >16.7ms | >33.3ms |")
    print("|---|---|---:|---:|---:|---:|---:|---:|---:|---:|")
    for entry in sorted(runs, key=lambda entry: (entry["condition"], entry["trial"])):
        trace = entry["trace"]
        print(f"| {entry['condition']} | {entry['trial']} | {trace['frames']} | "
              f"{trace['mean_ms']:.3f} | {trace['p50_ms']:.3f} | {trace['p95_ms']:.3f} | "
              f"{trace['p99_ms']:.3f} | {trace['max_ms']:.1f} | {trace['over_60hz_budget']} | "
              f"{trace['over_30hz_budget']} |")
    print("\n### Median over runs (ms)\n")
    print("| condition | runs | mean | p50 | p95 | p99 | worst |")
    print("|---|---:|---:|---:|---:|---:|---:|")
    for condition in ("main-off", "branch-off", "branch-on"):
        traces = [entry["trace"] for entry in runs if entry["condition"] == condition]
        if not traces:
            continue
        cells = [statistics.median(trace[key] for trace in traces)
                 for key in ("mean_ms", "p50_ms", "p95_ms", "p99_ms", "max_ms")]
        print(f"| {condition} | {len(traces)} | " + " | ".join(f"{cell:.3f}" for cell in cells)
              + " |")
    records = [entry["record"] for entry in runs if entry.get("record")]
    if records:
        print("\n### The record's own estimate of its cost (branch-on runs)\n")
        print("| run | timer_pair_usec | timer calls a frame | pairs x calls, us a frame |")
        print("|---|---:|---:|---:|")
        for entry in runs:
            record = entry.get("record")
            if record:
                print(f"| {entry['trial']} | {record['timer_pair_usec']:.3f} | "
                      f"{record['mean_timer_calls']} | {record['own_cost_us_per_frame']} |")


def mode_tables(results):
    runs = accepted(results, "modes")
    if not runs:
        return
    print("\n### Slow frames per recording (VSync as a player plays, --frame-record)\n")
    print("| mode | run | frames | p50 ms | p99 ms | worst ms | slow | slow, scenery job | "
          "slow, no job | largest cost in slow frames, job | largest cost, no job |")
    print("|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|")
    for entry in sorted(runs, key=lambda entry: (entry["condition"], entry["trial"])):
        summary = entry["record"]["summary"]
        with_jobs = ", ".join(f"{key} {value}" for key, value in sorted(
            summary["largest_cost_in_slow_frames_with_scenery_jobs"].items(),
            key=lambda item: -item[1]))
        without = ", ".join(f"{key} {value}" for key, value in sorted(
            summary["largest_cost_in_slow_frames_without_scenery_jobs"].items(),
            key=lambda item: -item[1]))
        print(f"| {entry['condition']} | {entry['trial']} | {summary['frames']} | "
              f"{summary['frame_p50_ms']:.2f} | {summary['frame_p99_ms']:.2f} | "
              f"{summary['frame_max_ms']:.1f} | {summary['slow_frames']} | "
              f"{summary['slow_frames_with_scenery_jobs']} | "
              f"{summary['slow_frames_without_scenery_jobs']} | {with_jobs or '-'} | "
              f"{without or '-'} |")
    buckets = ["scenery", "crowd", "influence", "events", "cues", "draw", "physics_rest",
               "process_rest"]
    print("\n### Mean ms per slow frame, by bucket (pooled over a mode's recordings)\n")
    print("| mode | slow frames | split | " + " | ".join(buckets) + " |")
    print("|---|---:|---|" + "---:|" * len(buckets))
    for condition in sorted({entry["condition"] for entry in runs}):
        summaries = [entry["record"]["summary"] for entry in runs
                     if entry["condition"] == condition]
        for split, count_key, mean_key in [
                ("all", "slow_frames", "mean_ms_per_slow_frame"),
                ("scenery job", "slow_frames_with_scenery_jobs",
                 "mean_ms_per_slow_frame_with_scenery_jobs"),
                ("no job", "slow_frames_without_scenery_jobs",
                 "mean_ms_per_slow_frame_without_scenery_jobs")]:
            total = sum(summary[count_key] for summary in summaries)
            cells = []
            for bucket in buckets:
                weighted = sum(summary[mean_key].get(bucket, 0.0) * summary[count_key]
                               for summary in summaries)
                cells.append(f"{weighted / total:.2f}" if total else "-")
            print(f"| {condition} | {total} | {split} | " + " | ".join(cells) + " |")


def main():
    results = json.loads(Path(sys.argv[1]).read_text())
    rejected = [entry for entry in results if entry.get("rejected")]
    cost_tables(results)
    mode_tables(results)
    if rejected:
        print("\n### Rejected captures\n")
        for entry in rejected:
            print(f"- {entry['label']} attempt {entry['attempt']}: {'; '.join(entry['reasons'])}")


if __name__ == "__main__":
    main()
