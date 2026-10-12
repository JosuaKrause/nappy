"""Summarise run.sh's frame records: one line per run, then each condition's runs side by side.

    python3 docs/evidence/m159-offscreen-2026-10-11/analyse.py <out-dir> [--tsv runs.tsv]

Every retained row of a record is a frame of play. Per run it reports the frame count, the frame's
median, mean and 95th percentile, the mean of each bucket the change touches, the mean `_draw()`
calls by kind and the renderer's mean draw calls and render objects. A condition is one label,
mode and day; its line gives the median and the range of its runs' values.
"""

import argparse
import gzip
import json
import statistics
import sys
from pathlib import Path

COLUMNS = [
    ("frame_med", None), ("frame_mean", "frame_usec"), ("frame_p95", None),
    ("crowd", "crowd_usec"), ("events", "events_usec"), ("cues", "cues_usec"),
    ("process_rest", "process_rest_usec"), ("draw", "draw_usec"), ("render", "render_usec"),
    ("draws_crowd", "draws_crowd"), ("draws_events", "draws_events"),
    ("draws_badges", "draws_badges"), ("draws_other", "draws_other"),
    ("draw_calls", "draw_calls"), ("render_objects", "render_objects"),
]


def summarise(path):
    record = json.load(gzip.open(path, "rt"))
    index = {name: i for i, name in enumerate(record["columns"])}
    rows = record["rows"]
    frames = sorted(row[index["frame_usec"]] for row in rows)
    out = {"frames": len(rows), "frame_med": statistics.median(frames),
           "frame_p95": frames[int(0.95 * (len(frames) - 1))]}
    for name, column in COLUMNS:
        if column is not None:
            out[name] = sum(row[index[column]] for row in rows) / len(rows)
    out["build"] = record["environment"]["build"]
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("out", type=Path)
    parser.add_argument("--tsv", type=Path, help="write the per-run table here as well")
    args = parser.parse_args()
    runs = {}
    for path in sorted(args.out.glob("*.json.gz")):
        label, mode, day, round_ = path.name[:-len(".json.gz")].rsplit("-", 3)
        runs[(label, mode, day, round_)] = summarise(path)
    if not runs:
        sys.exit(f"no frame records in {args.out}")
    names = ["frames"] + [name for name, _ in COLUMNS]
    lines = ["\t".join(["label", "mode", "day", "round"] + names + ["build"])]
    for key, run in sorted(runs.items()):
        values = [f"{run[n]:.1f}" for n in names]
        lines.append("\t".join(list(key) + values + [run["build"]]))
    table = "\n".join(lines) + "\n"
    print(table)
    if args.tsv:
        args.tsv.write_text(table)
    print("condition medians of run values [min..max], microseconds or counts per frame")
    conditions = sorted({key[:3] for key in runs})
    for condition in conditions:
        members = [run for key, run in runs.items() if key[:3] == condition]
        parts = []
        for name in names:
            values = [run[name] for run in members]
            parts.append(f"{name} {statistics.median(values):.1f} "
                         f"[{min(values):.1f}..{max(values):.1f}]")
        print(" ".join(condition), f"({len(members)} runs):", "; ".join(parts))


if __name__ == "__main__":
    main()
