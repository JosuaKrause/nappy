#!/usr/bin/env python3
"""Collects and reports the crowd-tick measurement across revisions (run.sh).

  analyse.py collect <out-dir> <runs.jsonl.gz>   gather run.sh's probe logs into one file
  analyse.py report <runs.jsonl.gz>              parity verdict and the tables in README.md

`collect` keeps every `CROWD_TICK_JSON` line of every `<label>-<round>.log` in `<out-dir>`, tagged
with its label, its round and the label's place in `runs.tsv` (the first label is the baseline),
and refuses a log whose probe reported a failed check or an engine error. A `whole` run keeps its
per-tick rows; a `split` run keeps, per column, the mean, median and 95th percentile of its own
rows, which is what the by-call table reads, rather than a dozen numbers a tick. `report` refuses
to print timings unless every run of the same seed, day, walk, repetition and mode carries the same
position chain on every revision, which is the claim that no change moved an agent; then it prints
the tables. Percentiles are nearest-rank, in microseconds per simulated tick. Standard library only.
"""

from __future__ import annotations

import gzip
import json
import math
import re
import statistics
import sys
from pathlib import Path


def collect(out_dir: Path, target: Path) -> None:
    rows: list[str] = []
    order = [line.split("\t")[1] for line in (out_dir / "runs.tsv").read_text().splitlines()[1:]]
    for log in sorted(out_dir.glob("*-*.log")):
        match = re.fullmatch(r"([a-z0-9_]+)-(\d+)\.log", log.name)
        if not match or match.group(1) not in order:
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
            run["order"] = order.index(match.group(1))
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


def revisions_of(runs: list[dict]) -> list[str]:
    return [name for _, name in sorted({(run["order"], run["revision"]) for run in runs})]


def cases_of(runs: list[dict]) -> list[tuple]:
    return sorted({(run["seed"], run["day"], run["walk"]) for run in runs})


def chosen(runs: list[dict], mode: str, revision: str, case: tuple) -> list[dict]:
    return [
        run
        for run in runs
        if run["mode"] == mode
        and run["revision"] == revision
        and (run["seed"], run["day"], run["walk"]) == case
    ]


def parity(runs: list[dict]) -> None:
    chains: dict[tuple, set[str]] = {}
    for run in runs:
        key = (run["seed"], run["day"], run["walk"], run["repetition"], run["mode"])
        chains.setdefault(key, set()).add(run["chain"])
    split = [key for key, seen in chains.items() if len(seen) != 1]
    if split:
        raise SystemExit(f"position chains differ for {split}")
    by_case: dict[tuple, set[str]] = {}
    for (seed, day, walk, _repetition, _mode), seen in chains.items():
        by_case.setdefault((seed, day, walk), set()).update(seen)
    counted = ", ".join(
        f"{sum(run['revision'] == name for run in runs)} {name}" for name in revisions_of(runs)
    )
    print("## Parity\n")
    print(
        f"{len(runs)} runs ({counted}). Every run of the same seed, day, walk, repetition and "
        "mode has the same position chain on every revision, and each seed, day and walk has one "
        "chain across all its repetitions and both modes:\n"
    )
    for (seed, day, walk), seen in sorted(by_case.items()):
        if len(seen) != 1:
            raise SystemExit(f"seed {seed} day {day} {walk} has {len(seen)} different chains")
        print(f"- seed {seed}, day {day}, {walk} walk: `{next(iter(seen))[:16]}`")
    print()


def workload(runs: list[dict]) -> None:
    print("## Workload the hash covers (`whole` runs, one repetition's counts)\n")
    print("| seed | day | walk | agents | huts | gates | walker-ticks touching her | walker-ticks at a hut |")
    print("|---:|---:|---|---:|---:|---:|---:|---:|")
    first = revisions_of(runs)[0]
    for case in cases_of(runs):
        run = chosen(runs, "whole", first, case)[0]
        print(
            f"| {case[0]} | {case[1]} | {case[2]} | {run['agents']} | {run['huts']} | "
            f"{run['gates']} | {run['walker_contact_ticks']} | {run['walker_door_ticks']} |"
        )
    print()


def tick_table(runs: list[dict]) -> None:
    names = revisions_of(runs)
    print("## The whole tick (`whole` mode, `Crowd._physics_process()` as one span), µs\n")
    print(
        "| seed | day | walk | agents | revision | samples | mean | p50 | p90 | p95 | p99 | max "
        "| p50 vs baseline |"
    )
    print("|---:|---:|---|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|")
    for case in cases_of(runs):
        baseline = 0.0
        for name in names:
            group = chosen(runs, "whole", name, case)
            ticks = [row[1] for run in group for row in run["rows"]]
            median = statistics.median(ticks)
            baseline = baseline or median
            change = f"{100.0 * (median / baseline - 1.0):+.0f}%" if name != names[0] else ""
            print(
                f"| {case[0]} | {case[1]} | {case[2]} | {group[0]['agents']} | {name} | "
                f"{len(ticks)} | {statistics.fmean(ticks):.1f} | {nearest_rank(ticks, 50)} | "
                f"{nearest_rank(ticks, 90)} | {nearest_rank(ticks, 95)} | "
                f"{nearest_rank(ticks, 99)} | {max(ticks)} | {change} |"
            )
    print()
    print("Each run's own median, in run order (round.repetition: µs):\n")
    print("| seed | day | walk | revision | medians |")
    print("|---:|---:|---|---|---|")
    for case in cases_of(runs):
        for name in names:
            group = sorted(
                chosen(runs, "whole", name, case), key=lambda r: (r["round"], r["repetition"])
            )
            cells = ", ".join(
                f"{run['round']}.{run['repetition']}: {statistics.median(r[1] for r in run['rows']):.0f}"
                for run in group
            )
            print(f"| {case[0]} | {case[1]} | {case[2]} | {name} | {cells} |")
    print()


def paired_table(runs: list[dict]) -> None:
    """The drift-robust reading: each run's median compared with the baseline run of the same
    round and repetition, which ran minutes earlier under nearly the same load."""
    names = revisions_of(runs)
    for title, index in (("whole tick", 1), ("agents' own frame", 0)):
        print(f"## Paired by round and repetition: {title}\n")
        print(
            "Per run median in µs. `best` is the lowest of a revision's run medians; "
            "`paired` is the median of the ratios to the baseline run of the same round and "
            "repetition (below 1.00 is faster than the baseline).\n"
        )
        print("| seed | day | walk | revision | best | paired |")
        print("|---:|---:|---|---|---:|---:|")
        for case in cases_of(runs):
            medians: dict[str, dict[tuple, float]] = {}
            for name in names:
                medians[name] = {
                    (run["round"], run["repetition"]): statistics.median(
                        row[index] for row in run["rows"]
                    )
                    for run in chosen(runs, "whole", name, case)
                }
            for name in names:
                ratios = [
                    medians[name][key] / medians[names[0]][key] for key in medians[name]
                ]
                paired = "" if name == names[0] else f"{statistics.median(ratios):.2f}"
                print(
                    f"| {case[0]} | {case[1]} | {case[2]} | {name} | "
                    f"{min(medians[name].values()):.0f} | {paired} |"
                )
        print()


def agents_table(runs: list[dict]) -> None:
    names = revisions_of(runs)
    print("## The agents' own frame (`CrowdAgent._process()` for every agent), µs per tick\n")
    print("| seed | day | walk | revision | samples | p50 | p90 | p99 | p50 vs baseline |")
    print("|---:|---:|---|---|---:|---:|---:|---:|---:|")
    for case in cases_of(runs):
        baseline = 0.0
        for name in names:
            group = chosen(runs, "whole", name, case)
            ticks = [row[0] for run in group for row in run["rows"]]
            median = statistics.median(ticks)
            baseline = baseline or median
            change = f"{100.0 * (median / baseline - 1.0):+.0f}%" if name != names[0] else ""
            print(
                f"| {case[0]} | {case[1]} | {case[2]} | {name} | {len(ticks)} | "
                f"{nearest_rank(ticks, 50)} | {nearest_rank(ticks, 90)} | "
                f"{nearest_rank(ticks, 99)} | {change} |"
            )
    print()


def split_table(runs: list[dict]) -> None:
    print("## By call (`split` mode), mean µs per tick, the mean of every run's own mean\n")
    columns: list[str] = next(run["columns"] for run in runs if run["mode"] == "split")
    print("| seed | day | walk | revision | " + " | ".join(columns) + " | tick (sum but agents) |")
    print("|---:|---:|---|---|" + "---:|" * (len(columns) + 1))
    for case in cases_of(runs):
        for name in revisions_of(runs):
            group = chosen(runs, "split", name, case)
            means = [
                statistics.fmean(run["summary"][column]["mean"] for run in group)
                for column in columns
            ]
            cells = " | ".join(f"{mean:.1f}" for mean in means)
            print(f"| {case[0]} | {case[1]} | {case[2]} | {name} | {cells} | {sum(means[1:]):.1f} |")
    print()


def report(source: Path) -> None:
    runs = load(source)
    first = runs[0]
    print(
        f"Engine {first['engine']}, {first['os']}, {first['processor']}; "
        f"{first['warmup_ticks']} warmup and {first['window_ticks']} timed ticks of "
        f"{first['step_seconds']:.6f}s per run. Revisions, baseline first: "
        f"{', '.join(revisions_of(runs))}.\n"
    )
    parity(runs)
    workload(runs)
    tick_table(runs)
    paired_table(runs)
    agents_table(runs)
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
