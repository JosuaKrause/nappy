#!/usr/bin/env python3
"""Collects and reports the cheaper-tick before/after measurement.

  analyse.py collect <out-dir> <runs.jsonl.gz>   gather run.sh's probe logs into one file
  analyse.py report <runs.jsonl.gz>              parity verdict and the tables in README.md

`collect` keeps every `CROWD_TICK_JSON` line of every `<revision>-<round>.log` in `<out-dir>`,
tagged with its revision and round, and refuses a log whose probe reported a failed check or an
engine error. A `whole` run keeps its per-tick rows; a `split` run keeps, per column, the mean,
median and 95th percentile of its own rows, which is what the by-call table reads, rather than
eleven numbers a tick. `report` refuses to print timings unless every run of the same seed, day,
repetition and mode carries the same position chain on both revisions, which is the claim that
the change moved no agent; then it prints the tables. Percentiles are nearest-rank, in
microseconds per simulated tick.
"""

from __future__ import annotations

import gzip
import json
import math
import re
import statistics
import sys
from pathlib import Path

REVISIONS = ("before", "after")


def collect(out_dir: Path, target: Path) -> None:
    rows: list[str] = []
    for log in sorted(out_dir.glob("*-*.log")):
        match = re.fullmatch(r"(before|after)-(\d+)\.log", log.name)
        if not match:
            continue
        text = log.read_text()
        if re.search(r"^\d+ checks, 0 failures$", text, re.M) is None:
            raise SystemExit(f"{log}: the probe did not finish with 0 failures")
        if re.search(r"ERROR:|SCRIPT ERROR|Parse Error", text):
            raise SystemExit(f"{log}: the engine reported an error")
        for line in text.splitlines():
            if not line.startswith("CROWD_TICK_JSON "):
                continue
            run = json.loads(line.split(" ", 1)[1])
            run["revision"] = match.group(1)
            run["round"] = int(match.group(2))
            if run["mode"] == "split":
                ticks = run.pop("rows")
                run["summary"] = {
                    column: {
                        "n": len(ticks),
                        "mean": statistics.fmean(tick[i] for tick in ticks),
                        "p50": nearest_rank([tick[i] for tick in ticks], 50),
                        "p95": nearest_rank([tick[i] for tick in ticks], 95),
                    }
                    for i, column in enumerate(run["columns"])
                }
            rows.append(json.dumps(run, separators=(",", ":")))
    if not rows:
        raise SystemExit(f"no probe output under {out_dir}")
    with gzip.open(target, "wt") as handle:
        handle.write("\n".join(rows) + "\n")
    print(f"wrote {len(rows)} runs to {target}")


def load(source: Path) -> list[dict]:
    with gzip.open(source, "rt") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def nearest_rank(values: list[int], percent: float) -> int:
    ordered = sorted(values)
    return ordered[max(0, math.ceil(percent / 100.0 * len(ordered)) - 1)]


def parity(runs: list[dict]) -> None:
    chains: dict[tuple, set[str]] = {}
    for run in runs:
        key = (run["seed"], run["day"], run["repetition"], run["mode"])
        chains.setdefault(key, set()).add(run["chain"])
    split = [key for key, seen in chains.items() if len(seen) != 1]
    if split:
        raise SystemExit(f"position chains differ for {split}")
    every = {next(iter(seen)) for seen in chains.values()}
    by_case: dict[tuple, set[str]] = {}
    for (seed, day, _repetition, _mode), seen in chains.items():
        by_case.setdefault((seed, day), set()).update(seen)
    counts = {revision: sum(run["revision"] == revision for run in runs) for revision in REVISIONS}
    print("## Parity\n")
    print(
        f"{len(runs)} runs ({counts['before']} before, {counts['after']} after). Every run of the "
        "same seed, day, repetition and mode has the same position chain on both revisions, and "
        f"each seed and day has one chain across all its repetitions and both modes "
        f"({len(every)} distinct chains for {len(by_case)} seed-day cases):\n"
    )
    for (seed, day), seen in sorted(by_case.items()):
        if len(seen) != 1:
            raise SystemExit(f"seed {seed} day {day} has {len(seen)} different chains")
        print(f"- seed {seed}, day {day}: `{next(iter(seen))[:16]}`")
    print()


def tick_table(runs: list[dict]) -> None:
    print("## The whole tick (`whole` mode, `Crowd._physics_process()` as one span)\n")
    print("| seed | day | agents | revision | samples | mean | p50 | p90 | p95 | p99 | max |")
    print("|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|")
    cases = sorted({(run["seed"], run["day"]) for run in runs})
    for seed, day in cases:
        medians: dict[str, float] = {}
        for revision in REVISIONS:
            chosen = [
                run
                for run in runs
                if run["mode"] == "whole"
                and run["revision"] == revision
                and (run["seed"], run["day"]) == (seed, day)
            ]
            ticks = [row[1] for run in chosen for row in run["rows"]]
            medians[revision] = statistics.median(ticks)
            print(
                f"| {seed} | {day} | {chosen[0]['agents']} | {revision} | {len(ticks)} | "
                f"{statistics.fmean(ticks):.1f} | {nearest_rank(ticks, 50)} | "
                f"{nearest_rank(ticks, 90)} | {nearest_rank(ticks, 95)} | "
                f"{nearest_rank(ticks, 99)} | {max(ticks)} |"
            )
        change = 100.0 * (1.0 - medians["after"] / medians["before"])
        print(f"| | | | median {change:.0f}% lower | | | | | | | |")
    print()
    print("Each run's own median, in run order, so the spread between runs is visible:\n")
    print("| seed | day | revision | medians per run (round.repetition: µs) |")
    print("|---:|---:|---|---|")
    for seed, day in cases:
        for revision in REVISIONS:
            chosen = sorted(
                (
                    run
                    for run in runs
                    if run["mode"] == "whole"
                    and run["revision"] == revision
                    and (run["seed"], run["day"]) == (seed, day)
                ),
                key=lambda run: (run["round"], run["repetition"]),
            )
            cells = ", ".join(
                f"{run['round']}.{run['repetition']}: "
                f"{statistics.median(row[1] for row in run['rows']):.0f}"
                for run in chosen
            )
            print(f"| {seed} | {day} | {revision} | {cells} |")
    print()


def split_table(runs: list[dict]) -> None:
    print("## By call (`split` mode), mean µs per tick, the mean of every run's own mean\n")
    columns: list[str] = next(run["columns"] for run in runs if run["mode"] == "split")
    print("| seed | day | revision | " + " | ".join(columns) + " | tick (sum but agents) |")
    print("|---:|---:|---|" + "---:|" * (len(columns) + 1))
    for seed, day in sorted({(run["seed"], run["day"]) for run in runs}):
        for revision in REVISIONS:
            chosen = [
                run
                for run in runs
                if run["mode"] == "split"
                and run["revision"] == revision
                and (run["seed"], run["day"]) == (seed, day)
            ]
            means = [
                statistics.fmean(run["summary"][column]["mean"] for run in chosen)
                for column in columns
            ]
            tick = sum(means[1:])
            cells = " | ".join(f"{mean:.1f}" for mean in means)
            print(f"| {seed} | {day} | {revision} | {cells} | {tick:.1f} |")
    print()


def report(source: Path) -> None:
    runs = load(source)
    first = runs[0]
    print(
        f"Engine {first['engine']}, {first['os']}, {first['processor']}; "
        f"{first['warmup_ticks']} warmup and {first['window_ticks']} timed ticks of "
        f"{first['step_seconds']:.6f}s per run.\n"
    )
    parity(runs)
    tick_table(runs)
    split_table(runs)


def main(argv: list[str]) -> None:
    if len(argv) >= 2 and argv[1] in ("-h", "--help"):
        print(__doc__)
        return
    if len(argv) == 4 and argv[1] == "collect":
        collect(Path(argv[2]), Path(argv[3]))
        return
    if len(argv) == 3 and argv[1] == "report":
        report(Path(argv[2]))
        return
    print(__doc__, file=sys.stderr)
    raise SystemExit(2)


if __name__ == "__main__":
    main(sys.argv)
