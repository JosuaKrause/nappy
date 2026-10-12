#!/usr/bin/env python3
"""Collects and reports the influence-sweep and events-step measurement across revisions (run.sh).

  analyse.py collect <out-dir> <runs.jsonl.gz>   gather run.sh's probe logs into one file
  analyse.py report <runs.jsonl.gz>              parity verdict and the tables in README.md

`collect` keeps every `TICK_SWEEP_JSON` line of every `<label>-<round>.log` in `<out-dir>`, tagged
with its label, its round and its slot in that round (from `runs.tsv`; the label in round 1's
first slot is the baseline), and refuses a log whose probe reported a failed check or an engine
error. A `whole` run keeps its per-tick rows; a `split` run keeps, per column, the mean, median and
95th percentile of its own rows. `report` refuses to print timings unless every run of the same
seed, day and walk carries the same chain on every revision, repetition and mode, which is the
claim that no change moved an event, an agent, an attribution or a meter; then it prints the
tables. The influence sweep's figures leave out the ticks the baby was crying, when the sweep
returns at once. Percentiles are nearest-rank, in microseconds per simulated tick. Standard
library only.
"""

from __future__ import annotations

import gzip
import json
import math
import re
import statistics
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

Run = dict[str, Any]


def nearest_rank(values: list[int], percent: float) -> int:
    ordered = sorted(values)
    return ordered[max(0, math.ceil(percent / 100.0 * len(ordered)) - 1)]


def slots(out_dir: Path) -> tuple[str, dict[tuple[str, int], int]]:
    lines = (out_dir / "runs.tsv").read_text().splitlines()[1:]
    placed: dict[tuple[str, int], int] = {}
    baseline = ""
    for line in lines:
        fields = line.split("\t")
        round_number, slot, label = int(fields[0]), int(fields[1]), fields[2]
        placed[(label, round_number)] = slot
        if round_number == 1 and slot == 0:
            baseline = label
    return baseline, placed


def collect(out_dir: Path, target: Path) -> None:
    baseline, placed = slots(out_dir)
    rows: list[str] = []
    for log in sorted(out_dir.glob("*-*.log")):
        match = re.fullmatch(r"([a-z0-9_]+)-(\d+)\.log", log.name)
        if not match or (match.group(1), int(match.group(2))) not in placed:
            continue
        text = log.read_text()
        if re.search(r"^\d+ checks, 0 failures$", text, re.MULTILINE) is None:
            raise SystemExit(f"{log}: the probe did not finish with 0 failures")
        if re.search(r"ERROR:|SCRIPT ERROR|Parse Error", text):
            raise SystemExit(f"{log}: the engine reported an error")
        for line in text.splitlines():
            if not line.startswith("TICK_SWEEP_JSON "):
                continue
            run = json.loads(line.split(" ", 1)[1])
            run["revision"] = match.group(1)
            run["baseline"] = match.group(1) == baseline
            run["round"] = int(match.group(2))
            run["slot"] = placed[(match.group(1), run["round"])]
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


def load(source: Path) -> list[Run]:
    with gzip.open(source, "rt") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def case_of(run: Run) -> tuple[int, int, str]:
    return (run["seed"], run["day"], run["walk"])


def parity(runs: list[Run]) -> bool:
    chains: dict[tuple[int, int, str], set[str]] = defaultdict(set)
    for run in runs:
        chains[case_of(run)].add(run["chain"])
    same = all(len(found) == 1 for found in chains.values())
    print(f"## Parity: {len(runs)} runs, {len(chains)} cases")
    for case, found in sorted(chains.items()):
        verdict = f"one chain {next(iter(found))[:16]}" if len(found) == 1 else f"{len(found)} DIFFERENT chains"
        print(f"- seed {case[0]} day {case[1]} {case[2]}: {verdict}")
    return same


def columns(run: Run) -> dict[str, list[int]]:
    """A whole run's events and influence ticks, the influence without the crying ones."""
    names = run["columns"]
    events = names.index("events")
    influence = names.index("influence")
    crying = names.index("crying")
    return {
        "events": [tick[events] for tick in run["rows"]],
        "influence": [tick[influence] for tick in run["rows"] if not tick[crying]],
    }


def report(source: Path) -> None:
    runs = load(source)
    if not parity(runs):
        raise SystemExit("chains differ: timings are not reported")
    labels: list[str] = []
    for run in sorted(runs, key=lambda run: (not run["baseline"], run["round"], run["slot"])):
        if run["revision"] not in labels:
            labels.append(run["revision"])
    whole = [run for run in runs if run["mode"] == "whole"]
    print("\n## Workload (whole runs of the baseline, first repetition)")
    print("| seed | day | walk | agents | planned | most live | reached ticks | alert ticks | crying ticks |")
    print("|---|---:|---|---:|---:|---:|---:|---:|---:|")
    for run in sorted(whole, key=case_of):
        if run["baseline"] and run["round"] == 1 and run["repetition"] == 0:
            print(
                f"| {run['seed']} | {run['day']} | {run['walk']} | {run['agents']} | {run['planned_events']} "
                f"| {run['most_live_events']} | {run['reached_ticks']} | {run['alert_ticks']} | {run['crying_ticks']} |"
            )
    for column in ("events", "influence"):
        print(f"\n## {column}: median of each run's median, and pooled p95 (µs per tick)")
        print(
            "| seed | day | walk | "
            + " | ".join(labels)
            + " | "
            + " | ".join(f"{label}/{labels[0]}" for label in labels[1:])
            + " |"
        )
        print("|---|---:|---|" + "---:|" * (2 * len(labels) - 1))
        by_case: dict[tuple[int, int, str], dict[str, list[Run]]] = defaultdict(lambda: defaultdict(list))
        for run in whole:
            by_case[case_of(run)][run["revision"]].append(run)
        for case in sorted(by_case):
            medians: dict[str, float] = {}
            cells: list[str] = []
            for label in labels:
                found = by_case[case][label]
                per_run = [statistics.median(columns(run)[column]) for run in found if columns(run)[column]]
                pooled = [value for run in found for value in columns(run)[column]]
                if not per_run:
                    cells.append("-")
                    continue
                medians[label] = statistics.median(per_run)
                cells.append(f"{medians[label]:.0f} (p95 {nearest_rank(pooled, 95)})")
            ratios = []
            for label in labels[1:]:
                paired = paired_ratios(by_case[case][labels[0]], by_case[case][label], column)
                spread = f"[{min(paired):.2f} to {max(paired):.2f}]" if paired else ""
                ratios.append(f"{statistics.median(paired):.2f} {spread}" if paired else "-")
            print(f"| {case[0]} | {case[1]} | {case[2]} | " + " | ".join(cells) + " | " + " | ".join(ratios) + " |")
    split = [run for run in runs if run["mode"] == "split"]
    print("\n## By call: median of the split runs' own medians (µs per tick), per day, both walks and seeds")
    parts = split[0]["columns"][:-1]
    print("| day | call | " + " | ".join(labels) + " |")
    print("|---:|---|" + "---:|" * len(labels))
    for day in sorted({run["day"] for run in split}):
        for part in parts:
            cells = []
            for label in labels:
                p50s: list[int] = [
                    run["summary"][part]["p50"] for run in split if run["day"] == day and run["revision"] == label
                ]
                cells.append(f"{statistics.median(p50s):.0f}")
            print(f"| {day} | {part} | " + " | ".join(cells) + " |")


def paired_ratios(base: list[Run], other: list[Run], column: str) -> list[float]:
    """Each run's median over the baseline's run of the same round and repetition."""
    index = {(run["round"], run["repetition"]): run for run in base}
    ratios = []
    for run in other:
        twin = index.get((run["round"], run["repetition"]))
        if twin is None:
            continue
        mine, theirs = columns(run)[column], columns(twin)[column]
        if mine and theirs and statistics.median(theirs) > 0:
            ratios.append(statistics.median(mine) / statistics.median(theirs))
    return ratios


def main() -> None:
    if len(sys.argv) == 4 and sys.argv[1] == "collect":
        collect(Path(sys.argv[2]), Path(sys.argv[3]))
    elif len(sys.argv) == 3 and sys.argv[1] == "report":
        report(Path(sys.argv[2]))
    else:
        print(__doc__, file=sys.stderr)
        raise SystemExit(0 if len(sys.argv) == 2 and sys.argv[1] in ("-h", "--help") else 2)


if __name__ == "__main__":
    main()
