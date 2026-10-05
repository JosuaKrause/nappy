"""Reads the scratch directories `measure.py` wrote and prints the run table and the comparisons.

    python3 docs/evidence/m159-draw-split-2026-10-04/analyse.py <scratch-dir> [<scratch-dir> ...]
    python3 docs/evidence/m159-draw-split-2026-10-04/analyse.py --tsv runs.tsv <scratch-dir> ...

Each directory holds `provenance.json`, `results.json`, a `<label>.trace.json.gz` (or `.json`) per
run and, for a record-on run, a `<label>.record.json.gz` (or `.json`). A run is named by the
revision of the checkout it ran in and by whether `--frame-record` was on. The warmup of each
condition is listed but left out of every comparison, and so is any attempt rejected because
another engine ran beside it. `--tsv` writes one row per run (the table README.md quotes).
Standard library only.
"""

from __future__ import annotations

import gzip
import json
import statistics
import sys
from pathlib import Path

DRAW_KINDS = ["crowd", "events", "halos", "scenery", "badges", "player", "other"]


def load_json(path: Path) -> dict | None:
    for candidate in (path.with_name(path.name + ".gz"), path):
        if candidate.exists():
            opener = gzip.open if candidate.suffix == ".gz" else open
            with opener(candidate, "rt") as handle:
                return json.load(handle)
    return None


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[int(max(0, min(len(ordered) - 1, -(-len(ordered) * fraction // 1) - 1)))]


def trace_columns(directory: Path, label: str) -> dict[str, float]:
    trace = load_json(directory / f"{label}.trace.json")
    if trace is None:
        return {}
    names = trace["columns"]
    out: dict[str, float] = {}
    for column in ("draw_calls", "render_objects", "primitives"):
        values = [row[names.index(column)] for row in trace["samples"]]
        out[f"{column}_mean"] = statistics.fmean(values)
        out[f"{column}_median"] = statistics.median(values)
        out[f"{column}_p95"] = percentile(values, 0.95)
    return out


def record_columns(directory: Path, label: str) -> dict[str, float]:
    record = load_json(directory / f"{label}.record.json")
    if record is None:
        return {}
    names = record["columns"]
    rows = record["rows"]

    def mean(column: str) -> float:
        return statistics.fmean(row[names.index(column)] for row in rows)

    out = {"record_rows": float(len(rows)), "timer_calls": mean("timer_calls")}
    out["record_frame_ms"] = mean("frame_usec") / 1000
    for column in ("draw_usec", "render_usec", "render_cpu_usec"):
        if column in names:
            out[column.replace("_usec", "_ms")] = mean(column) / 1000
    kinds = [f"draws_{kind}" for kind in DRAW_KINDS if f"draws_{kind}" in names]
    if kinds:
        for kind in kinds:
            out[kind] = mean(kind)
        out["draws_all"] = statistics.fmean(sum(row[names.index(k)] for k in kinds) for row in rows)
        out["draws_all_max"] = max(sum(row[names.index(k)] for k in kinds) for row in rows)
        out["draws_crowd_max"] = max(row[names.index("draws_crowd")] for row in rows)
    out["schema_version"] = float(record.get("schema_version", 0))
    return out


def runs(directory: Path, tag: str) -> list[dict]:
    provenance = json.loads((directory / "provenance.json").read_text())
    revisions = {name: provenance["identity"][name]["revision"][:8] for name in ("branch", "main")}
    rows = []
    for entry in json.loads((directory / "results.json").read_text()):
        label = entry["label"]
        condition = entry.get("condition") or label.split("-", 2)[2].rsplit("-", 1)[0]
        tree = "branch" if condition.startswith("branch") else "main"
        row = {
            "set": tag,
            "label": label,
            "attempt": entry.get("attempt", 1),
            "revision": revisions[tree],
            "record": "on" if condition.endswith("-on") else "off",
            "trial": label.rsplit("-", 1)[1],
            "started": entry.get("started", ""),
            "load_before": (entry.get("load_average_before") or [""])[0],
            "rejected": bool(entry.get("rejected")) or bool(entry.get("reasons")),
            "reasons": "; ".join(entry.get("reasons", [])),
        }
        if entry.get("rejected") and "competition" in entry:
            row["reasons"] += " (" + " | ".join(c[:90] for c in entry["competition"][:2]) + ")"
        trace = entry.get("trace") or {}
        for key in ("frames", "mean_ms", "p50_ms", "p95_ms", "p99_ms", "max_ms"):
            if key in trace:
                row[key] = trace[key]
        if not row["rejected"]:
            row.update(trace_columns(directory, label))
            row.update(record_columns(directory, label))
        rows.append(row)
    return rows


def median_of(rows: list[dict], key: str) -> str:
    values = [r[key] for r in rows if key in r]
    return f"{statistics.median(values):.3f}" if values else "-"


def main(argv: list[str]) -> int:
    if not argv or any(a in ("-h", "--help") for a in argv):
        print(__doc__)
        return 0 if argv else 2
    tsv = None
    if argv[0] == "--tsv":
        if len(argv) < 3:
            print(__doc__, file=sys.stderr)
            return 2
        tsv, argv = Path(argv[1]), argv[2:]
    if any(a.startswith("-") for a in argv) or not all(Path(a).is_dir() for a in argv):
        print(f"each argument must be a scratch directory\n\n{__doc__}", file=sys.stderr)
        return 2
    every: list[dict] = []
    for index, name in enumerate(argv):
        every += runs(Path(name), chr(ord("A") + index))
    columns = ["set", "label", "attempt", "revision", "record", "trial", "started", "load_before",
               "rejected", "reasons", "frames", "mean_ms", "p50_ms", "p95_ms", "p99_ms", "max_ms",
               "draw_calls_mean", "draw_calls_median", "draw_calls_p95", "render_objects_mean",
               "render_objects_median", "render_objects_p95", "primitives_mean", "record_rows",
               "timer_calls", "record_frame_ms", "draw_ms", "render_ms", "render_cpu_ms",
               "draws_all", "draws_all_max", "draws_crowd_max",
               *[f"draws_{k}" for k in DRAW_KINDS]]
    if tsv:
        with tsv.open("w") as out:
            out.write("\t".join(columns) + "\n")
            for r in every:
                cells = [f"{r[c]:.3f}" if isinstance(r.get(c), float) else str(r.get(c, "")) for c in columns]
                out.write("\t".join(cells) + "\n")
    kept = [r for r in every if not r["rejected"] and r["trial"] != "warmup"]
    print(f"{len(every)} captures, {sum(1 for r in every if r['rejected'])} rejected, "
          f"{sum(1 for r in every if r['trial'] == 'warmup' and not r['rejected'])} warmups, "
          f"{len(kept)} measured\n")
    print("| revision | record | runs | mean frame ms (median of runs) | range | draw calls mean | "
          "draw calls median | draw calls p95 | render objects mean | primitives mean |")
    print("|---|---|---:|---:|---|---:|---:|---:|---:|---:|")
    for revision in sorted({r["revision"] for r in kept}):
        for record in ("off", "on"):
            group = [r for r in kept if r["revision"] == revision and r["record"] == record]
            if not group:
                continue
            means = [r["mean_ms"] for r in group]
            print(f"| {revision} | {record} | {len(group)} | {median_of(group, 'mean_ms')} | "
                  f"{min(means):.2f}-{max(means):.2f} | {median_of(group, 'draw_calls_mean')} | "
                  f"{median_of(group, 'draw_calls_median')} | {median_of(group, 'draw_calls_p95')} | "
                  f"{median_of(group, 'render_objects_mean')} | {median_of(group, 'primitives_mean')} |")
    print()
    new = [r for r in kept if "render_ms" in r]
    if new:
        print("Record-on runs with schema 2 columns (means per frame, then the median of runs):\n")
        keys = ["draw_ms", "render_ms", "render_cpu_ms", "draws_all", "draws_all_max",
                *[f"draws_{k}" for k in DRAW_KINDS], "draws_crowd_max", "timer_calls"]
        print("| run | " + " | ".join(keys) + " |")
        print("|---|" + "---:|" * len(keys))
        for r in new:
            print(f"| {r['set']} {r['label']} | " + " | ".join(f"{r.get(k, 0):.2f}" for k in keys) + " |")
        print("| median | " + " | ".join(median_of(new, k) for k in keys) + " |")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
