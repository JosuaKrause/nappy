"""Reads a frame record (`nappy-frame-record`, schema 1) and prints the tables README.md quotes.

    uv run python docs/evidence/m159-phone-frame-record-2026-10-04/analyse.py
    uv run python docs/evidence/m159-phone-frame-record-2026-10-04/analyse.py <record.json>

With no argument it reads the phone's record beside it. Standard library only; it writes nothing.
Every figure is in milliseconds unless its label says otherwise. The phone's clock is the
browser's, quantized to `environment.timer_resolution_usec` (100us here), so a single short
interval reads as 0 or one step and only sums and means over many frames carry information below
a millisecond.
"""

from __future__ import annotations

import json
import statistics
import sys
from collections import Counter, defaultdict
from collections.abc import Callable, Iterable, Sequence
from itertools import pairwise
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT = HERE / "nappy-frames-seed478156010-2026-10-04T12-27-57.json"
BUCKETS = [
    "draw",
    "crowd",
    "cues",
    "events",
    "process_rest",
    "influence",
    "physics_rest",
    "scenery",
    "wait",
]
JOBS = [
    "jobs_ground",
    "jobs_building",
    "jobs_prop",
    "jobs_shadow",
    "jobs_decal",
    "guard_preparations",
]
# Day 1's first forty seconds against the rest: the run's own time series (section 3) shows the
# whole frame slowing after about forty seconds, on the same streets she walked fast before.
SPLIT_SECONDS = 40.0

Row = dict[str, int]


def ms(usec: float) -> float:
    return usec / 1000.0


def pct(sorted_values: Sequence[float], fraction: float) -> float:
    """The nearest-rank percentile, the same rule the record's own summary uses."""
    index = max(0, min(len(sorted_values) - 1, -(-len(sorted_values) * fraction // 1) - 1))
    return sorted_values[int(index)]


def median(values: Iterable[float]) -> float:
    return statistics.median(list(values))


def mean(values: Iterable[float]) -> float:
    return statistics.fmean(list(values))


def jobs(row: Row) -> int:
    return sum(row[name] for name in JOBS)


def table(header: Sequence[str], rows: Iterable[Sequence[object]]) -> None:
    print("| " + " | ".join(header) + " |")
    print("|" + "|".join("---" if i == 0 else "---:" for i in range(len(header))) + "|")
    for row in rows:
        cells = [f"{c:.1f}" if isinstance(c, float) else str(c) for c in row]
        print("| " + " | ".join(cells) + " |")
    print()


def heading(text: str) -> None:
    print(f"## {text}\n")


def load(path: Path) -> tuple[dict[str, object], list[Row]]:
    record = json.loads(path.read_text())
    columns: list[str] = record["columns"]
    rows = [dict(zip(columns, values, strict=True)) for values in record["rows"]]
    for row in rows:
        spent = sum(row[f"{b}_usec"] for b in BUCKETS)
        if spent != row["frame_usec"]:
            raise SystemExit(f"buckets do not add up to the frame at {row['process_frame']}")
    return record, rows


def coverage(record: dict[str, object], rows: list[Row]) -> None:
    heading("1. What the record saw")
    env = record["environment"]
    assert isinstance(env, dict)
    print(f"build {env['build']}, seed {env['run_seed']}, ground mode {env['ground_mode']}")
    print(f"user agent: {env['user_agent']}")
    print(
        f"clock step {env['timer_resolution_usec']}us, one timing pair "
        f"{env['timer_pair_usec']}us, refresh assumed: {env['refresh_assumed']}\n"
    )
    slow = sum(r["slow"] for r in rows)
    summary = record["summary"]
    assert isinstance(summary, dict)
    print(
        f"kept frames {len(rows)}, overwritten {record['overwritten']}, slow {slow} "
        f"(slow means longer than {summary['slow_after_ms']}ms)"
    )
    first, last = rows[0], rows[-1]
    span = last["process_frame"] - first["process_frame"] + 1
    print(
        f"process frames {first['process_frame']}..{last['process_frame']} ({span}); "
        f"kept {len(rows)} = {100 * len(rows) / span:.0f}%\n"
    )
    print("Spans the record did not keep (between kept frames):\n")
    gaps = []
    for before, after in pairwise(rows):
        skipped = after["process_frame"] - before["process_frame"] - 1
        if skipped:
            idle = after["start_usec"] - before["start_usec"] - before["frame_usec"]
            gaps.append(
                (
                    before["process_frame"],
                    skipped,
                    ms(idle),
                    ms(idle) / skipped,
                    f"day {before['day']} -> {after['day']}",
                )
            )
    table(["after process frame", "frames not kept", "lasting", "ms each", "days"], gaps)
    days = Counter(r["day"] for r in rows)
    played: dict[int, float] = defaultdict(float)
    for r in rows:
        played[r["day"]] += r["frame_usec"]
    table(
        ["day", "kept frames", "seconds of play kept", "frames a second"],
        [(d, days[d], played[d] / 1e6, days[d] / (played[d] / 1e6)) for d in sorted(days)],
    )


def distribution(rows: list[Row]) -> None:
    heading("2. Frame time")
    frame = sorted(ms(r["frame_usec"]) for r in rows)
    work = sorted(ms(r["frame_usec"] - r["wait_usec"]) for r in rows)
    wait = sorted(ms(r["wait_usec"]) for r in rows)
    fractions = [0.05, 0.25, 0.5, 0.75, 0.95, 0.99]
    table(
        ["", "p5", "p25", "p50", "p75", "p95", "p99", "max", "mean"],
        [
            (name, *(pct(v, f) for f in fractions), v[-1], mean(v))
            for name, v in [("frame", frame), ("callbacks (frame - wait)", work), ("wait", wait)]
        ],
    )
    print("Frame length, 4ms bins:\n")
    bins = Counter(int(f // 4) * 4 for f in frame)
    table(
        ["from ms", "frames", "share"],
        [(f"{b}-{b + 4}", bins[b], f"{100 * bins[b] / len(frame):.1f}%") for b in sorted(bins)],
    )


def seconds(rows: list[Row], row: Row) -> float:
    return (row["start_usec"] - rows[0]["start_usec"]) / 1e6


def over_time(rows: list[Row]) -> None:
    heading("3. Over the run, five-second windows")
    windows: dict[int, list[Row]] = defaultdict(list)
    for r in rows:
        windows[int(seconds(rows, r) // 5)].append(r)
    out = []
    for w in sorted(windows):
        rs = windows[w]
        out.append(
            (
                f"{w * 5}s",
                rs[0]["day"],
                len(rs),
                median(ms(r["frame_usec"]) for r in rs),
                f"{mean(r['physics_steps'] for r in rs):.2f}",
                *(mean(ms(r[f"{b}_usec"]) for r in rs) for b in BUCKETS[:-2]),
                round(mean(r["draw_calls"] for r in rs)),
                round(mean(r["render_objects"] for r in rs)),
                round(mean(r["live_events"] for r in rs)),
                round(mean(r["player_y"] for r in rs)),
            )
        )
    table(
        [
            "from",
            "day",
            "frames",
            "frame p50",
            "steps",
            *BUCKETS[:-2],
            "draw calls",
            "objects",
            "events live",
            "her y",
        ],
        out,
    )
    print("Same streets, out and back (day 1, her y in a band; out = first 25s, back = after 45s):\n")
    out = []
    for low, high in [(1800, 2200), (2200, 2600), (2600, 2800)]:
        for name, earliest, latest in [("out", 0.0, 25.0), ("back", 45.0, 70.0)]:
            rs = [
                r
                for r in rows
                if r["day"] == 1 and low <= r["player_y"] < high and earliest <= seconds(rows, r) < latest
            ]
            out.append(
                (
                    f"{low}-{high}",
                    name,
                    len(rs),
                    median(ms(r["frame_usec"]) for r in rs),
                    f"{mean(r['physics_steps'] for r in rs):.2f}",
                    median(ms(r["draw_usec"]) for r in rs),
                    median(ms(r["crowd_usec"]) for r in rs),
                    median(ms(r["cues_usec"]) for r in rs),
                    median(ms(r["process_rest_usec"]) for r in rs),
                    round(mean(r["draw_calls"] for r in rs)),
                    round(mean(r["render_objects"] for r in rs)),
                    round(mean(r["live_events"] for r in rs)),
                )
            )
    table(
        [
            "her y",
            "pass",
            "frames",
            "frame p50",
            "steps",
            "draw p50",
            "crowd p50",
            "cues p50",
            "process_rest p50",
            "draw calls",
            "objects",
            "events live",
        ],
        out,
    )


def phase(rows: list[Row], row: Row) -> str:
    if row["day"] != 1:
        return f"day {row['day']}"
    return "day 1, first 40s" if seconds(rows, row) < SPLIT_SECONDS else "day 1, after 40s"


def buckets(record: dict[str, object], rows: list[Row]) -> None:
    heading("4. Which system the time goes to")
    ordered = sorted(rows, key=lambda r: r["frame_usec"])
    worst10 = ordered[-len(rows) // 10 :]
    worst1 = ordered[-max(1, len(rows) // 100) :]
    groups = [("all", rows), ("worst 10%", worst10), ("worst 1%", worst1)]
    out = []
    for b in BUCKETS:
        cells: list[object] = [b]
        for _, rs in groups:
            total = sum(r["frame_usec"] for r in rs)
            spent = sum(r[f"{b}_usec"] for r in rs)
            cells += [ms(spent) / len(rs), f"{100 * spent / total:.0f}%"]
        out.append(cells)
    table(
        [
            "bucket",
            "mean, all",
            "share, all",
            f"mean, worst 10% ({len(worst10)})",
            "share",
            f"mean, worst 1% ({len(worst1)})",
            "share",
        ],
        out,
    )
    # A tie is counted apart rather than handed to whichever bucket comes first in BUCKETS: the
    # record's own summary breaks ties its own way, so a silent tie-break would disagree with it.
    largest: Counter[str] = Counter()
    ties = []
    for r in rows:
        top = max(r[f"{b}_usec"] for b in BUCKETS[:-1])
        tied = [b for b in BUCKETS[:-1] if r[f"{b}_usec"] == top]
        if len(tied) > 1:
            ties.append((r["process_frame"], " and ".join(tied), ms(top)))
        else:
            largest[tied[0]] += 1
    print("Largest cost in each frame, outright (wait excluded):", dict(largest.most_common()), "\n")
    if ties:
        print("Frames where two or more buckets tie for the largest:\n")
        table(["process frame", "tied", "ms each"], ties)
    summary = record["summary"]
    assert isinstance(summary, dict)
    print("The record's own summary, ties broken its own way:", summary["largest_cost_in_slow_frames"], "\n")
    print("By stretch of the run:\n")
    stretches: dict[str, list[Row]] = defaultdict(list)
    for r in rows:
        stretches[phase(rows, r)].append(r)
    table(
        ["stretch", "frames", "frame p50", "steps", *BUCKETS],
        [
            (
                name,
                len(rs),
                median(ms(r["frame_usec"]) for r in rs),
                f"{mean(r['physics_steps'] for r in rs):.2f}",
                *(mean(ms(r[f"{b}_usec"]) for r in rs) for b in BUCKETS),
            )
            for name, rs in stretches.items()
        ],
    )
    print("The ten longest frames:\n")
    table(
        ["process frame", "day", "frame", "steps", *BUCKETS[:-1], "timer calls", "jobs"],
        [
            (
                r["process_frame"],
                r["day"],
                ms(r["frame_usec"]),
                r["physics_steps"],
                *(ms(r[f"{b}_usec"]) for b in BUCKETS[:-1]),
                r["timer_calls"],
                jobs(r),
            )
            for r in sorted(rows, key=lambda r: -r["frame_usec"])[:10]
        ],
    )


def steps(rows: list[Row]) -> None:
    heading("5. Physics steps per frame (the tick is 30 a second)")
    by: dict[tuple[str, int], list[Row]] = defaultdict(list)
    for r in rows:
        by[(phase(rows, r), r["physics_steps"])].append(r)
    out = []
    for (name, n), rs in sorted(by.items()):
        out.append(
            (
                name,
                n,
                len(rs),
                median(ms(r["frame_usec"]) for r in rs),
                *(median(ms(r[f"{b}_usec"]) for r in rs) for b in BUCKETS),
            )
        )
    table(["stretch", "steps", "frames", "frame p50", *(f"{b} p50" for b in BUCKETS)], out)
    total = Counter(r["physics_steps"] for r in rows)
    print("Frames by step count, whole record:", dict(sorted(total.items())))
    several = sum(v for k, v in total.items() if k > 1)
    print(f"Two or more steps: {several} of {len(rows)} ({100 * several / len(rows):.0f}%)\n")
    print("What the frame before a step count looked like (frame p50 of the previous frame):\n")
    prev: dict[int, list[float]] = defaultdict(list)
    for before, row in pairwise(rows):
        if row["process_frame"] == before["process_frame"] + 1:
            prev[row["physics_steps"]].append(ms(before["frame_usec"]))
    table(
        ["steps", "frames", "previous frame p50"],
        [(k, len(v), median(v)) for k, v in sorted(prev.items())],
    )
    # A two-step frame follows a longer frame, and a frame after a longer one costs more in every
    # bucket (section 6), so a bare one-against-two comparison overstates what the step adds.
    # Comparing within 5ms bands of the previous frame's length takes most of that out.
    print(
        "What one more step adds, matched on the previous frame's length (day 1's first 40s, "
        "two-step mean less one-step mean in each 5ms band of the previous frame, weighted by "
        "the two-step frames in it):\n"
    )
    groups: dict[tuple[int, int], list[Row]] = defaultdict(list)
    for before, row in pairwise(rows):
        if row["process_frame"] == before["process_frame"] + 1 and phase(rows, row) == "day 1, first 40s":
            groups[(row["physics_steps"], before["frame_usec"] // 5000 * 5)].append(row)
    bands = [low for (n, low) in groups if n == 2 and groups.get((1, low)) and len(groups[(2, low)]) >= 8]
    weight = sum(len(groups[(2, low)]) for low in bands)
    added = []
    for b in ["frame", *BUCKETS]:
        column = f"{b}_usec"
        difference = sum(
            len(groups[(2, low)])
            * (mean(r[column] for r in groups[(2, low)]) - mean(r[column] for r in groups[(1, low)]))
            for low in bands
        )
        added.append((b, ms(difference / weight)))
    print(f"bands {sorted(bands)}ms, {weight} two-step frames\n")
    table(["bucket", "added by the second step, ms"], added)


def least_squares(columns: Sequence[Sequence[float]], ys: Sequence[float]) -> tuple[list[float], float]:
    """Ordinary least squares with an intercept: answers the coefficients, the intercept first,
    and R squared. The normal equations are solved by Gaussian elimination with partial pivoting,
    which is exact enough for four regressors over a few hundred rows."""
    n = len(ys)
    design = [[1.0, *(column[i] for column in columns)] for i in range(n)]
    width = len(design[0])
    normal = [[sum(row[a] * row[b] for row in design) for b in range(width)] for a in range(width)]
    target = [sum(row[a] * y for row, y in zip(design, ys, strict=True)) for a in range(width)]
    for col in range(width):
        pivot = max(range(col, width), key=lambda r: abs(normal[r][col]))
        normal[col], normal[pivot] = normal[pivot], normal[col]
        target[col], target[pivot] = target[pivot], target[col]
        for r in range(col + 1, width):
            factor = normal[r][col] / normal[col][col]
            for c in range(col, width):
                normal[r][c] -= factor * normal[col][c]
            target[r] -= factor * target[col]
    coefficients = [0.0] * width
    for r in reversed(range(width)):
        known = sum(normal[r][c] * coefficients[c] for c in range(r + 1, width))
        coefficients[r] = (target[r] - known) / normal[r][r]
    fitted = [sum(c * x for c, x in zip(coefficients, row, strict=True)) for row in design]
    average = statistics.fmean(ys)
    residual = sum((y - f) ** 2 for y, f in zip(ys, fitted, strict=True))
    total = sum((y - average) ** 2 for y in ys)
    return coefficients, 1.0 - residual / total


def tracking(rows: list[Row]) -> None:
    heading("6. What draw time tracks")
    consecutive = [
        (before, row) for before, row in pairwise(rows) if row["process_frame"] == before["process_frame"] + 1
    ]
    draw = [float(r["draw_usec"]) for r in rows]
    against: list[tuple[str, str]] = []
    for counter in ["draw_calls", "render_objects", "primitives", "physics_steps", "live_events"]:
        against.append((counter, f"{statistics.correlation(draw, [r[counter] for r in rows]):.2f}"))
    after = [float(r["draw_usec"]) for _, r in consecutive]
    for label, column in [("previous frame's length", "frame_usec"), ("previous frame's draw", "draw_usec")]:
        earlier = [float(b[column]) for b, _ in consecutive]
        against.append((label, f"{statistics.correlation(earlier, after):.2f}"))
    table(["draw against", "correlation, every frame"], against)
    # One stretch and one step count, and only frames whose previous frame was kept, so every
    # model below is fitted to the same frames. Draw follows the previous frame's length (the
    # phone's speed drifts), so a fit on draw calls alone credits the drift to the counter and to
    # the intercept; the second and third models hold the previous frame's length fixed.
    steady_pairs = [
        (before, row)
        for before, row in consecutive
        if phase(rows, row) == "day 1, first 40s" and row["physics_steps"] == 1
    ]
    steady = [row for _, row in steady_pairs]
    calls = [float(r["draw_calls"]) for r in steady]
    previous = [ms(b["frame_usec"]) for b, _ in steady_pairs]
    objects = [float(r["render_objects"]) for r in steady]
    primitives = [float(r["primitives"]) for r in steady]
    drawn = [float(r["draw_usec"]) for r in steady]
    print(
        f"Draw fitted by least squares within one stretch and one step count (day 1's first 40s, one"
        f" step, previous frame kept: {len(steady)} frames; draw calls {min(calls):.0f}-{max(calls):.0f},"
        f" previous frame {min(previous):.1f}-{max(previous):.1f}ms):\n"
    )
    models: list[tuple[str, list[list[float]]]] = [
        ("draw calls", [calls]),
        ("draw calls + previous frame", [calls, previous]),
        ("draw calls + previous frame + objects + primitives", [calls, previous, objects, primitives]),
    ]
    fits = []
    for name, columns in models:
        coefficients, r_squared = least_squares(columns, drawn)
        fits.append(
            (
                name,
                f"{coefficients[1]:.1f}us",
                ms(coefficients[0]),
                f"{coefficients[2] / 1000:.2f}" if len(columns) > 1 else "-",
                f"{r_squared:.2f}",
            )
        )
    table(
        ["model", "per draw call", "draw at zero calls (intercept), ms", "draw ms per ms of previous frame", "R2"],
        fits,
    )
    bins: dict[int, list[float]] = defaultdict(list)
    for r in steady:
        bins[r["draw_calls"] // 50 * 50].append(ms(r["draw_usec"]))
    table(
        ["draw calls", "frames", "draw p50"],
        [(f"{b}-{b + 49}", len(v), median(v)) for b, v in sorted(bins.items())],
    )
    print(
        "By the previous frame's length and this frame's step count (day 1's first 40s, medians;"
        " groups of fewer than 8 frames left out):\n"
    )
    by_previous: dict[tuple[int, int], list[Row]] = defaultdict(list)
    for before, row in consecutive:
        if phase(rows, row) == "day 1, first 40s" and row["physics_steps"] in (1, 2):
            by_previous[(row["physics_steps"], before["frame_usec"] // 5000 * 5)].append(row)
    table(
        ["steps", "previous frame, ms", "frames", "draw", "cues", "process_rest", "crowd"],
        [
            (
                n,
                f"{low}-{low + 5}",
                len(rs),
                *(median(ms(r[f"{b}_usec"]) for r in rs) for b in ["draw", "cues", "process_rest", "crowd"]),
            )
            for (n, low), rs in sorted(by_previous.items())
            if len(rs) >= 8
        ],
    )
    print("Where draw jumps, which moves first (day 2, standing at the doorstep):\n")
    jumps = []
    for before, row in consecutive:
        if row["day"] == 2 and row["draw_usec"] - before["draw_usec"] >= 7000:
            jumps.append(
                (
                    row["process_frame"],
                    ms(before["frame_usec"]),
                    before["physics_steps"],
                    ms(before["draw_usec"]),
                    row["physics_steps"],
                    ms(row["draw_usec"]),
                    ms(row["crowd_usec"] - before["crowd_usec"]),
                    ms(row["cues_usec"] - before["cues_usec"]),
                    ms(row["process_rest_usec"] - before["process_rest_usec"]),
                )
            )
    table(
        [
            "process frame",
            "frame before",
            "its steps",
            "its draw",
            "steps",
            "draw",
            "crowd change",
            "cues change",
            "process_rest change",
        ],
        jumps,
    )


def workload(rows: list[Row]) -> None:
    heading("7. Crowd, events and cues against what is alive")
    agents = Counter(r["crowd_agents"] for r in rows)
    print(f"crowd_agents takes the values {dict(agents)}: no variation to track.\n")
    steady = [r for r in rows if phase(rows, r) == "day 1, first 40s" and r["physics_steps"] == 1]
    bins: dict[int, list[Row]] = defaultdict(list)
    for r in steady:
        bins[r["live_events"] // 4 * 4].append(r)
    table(
        ["live events", "frames", "events p50", "cues p50", "crowd p50", "influence mean"],
        [
            (
                f"{b}-{b + 3}",
                len(rs),
                median(ms(r["events_usec"]) for r in rs),
                median(ms(r["cues_usec"]) for r in rs),
                median(ms(r["crowd_usec"]) for r in rs),
                mean(ms(r["influence_usec"]) for r in rs),
            )
            for b, rs in sorted(bins.items())
        ],
    )
    # The live-event count rises over the same stretch in which the phone drifts slower, so the
    # slope is fitted again with the previous frame's length held fixed, as draw's is in section 6.
    pairs = [
        (before, row)
        for before, row in pairwise(rows)
        if row["process_frame"] == before["process_frame"] + 1
        and phase(rows, row) == "day 1, first 40s"
        and row["physics_steps"] == 1
    ]
    live = [float(r["live_events"]) for _, r in pairs]
    previous = [ms(b["frame_usec"]) for b, _ in pairs]
    out = []
    totals = [0.0, 0.0]
    for b in ["events", "cues", "crowd", "influence"]:
        ys = [float(r[f"{b}_usec"]) for _, r in pairs]
        alone, alone_r2 = least_squares([live], ys)
        held, _ = least_squares([live, previous], ys)
        totals[0] += alone[1]
        totals[1] += held[1]
        out.append(
            (
                b,
                f"{alone[1]:.0f}us",
                f"{statistics.correlation(live, ys):.2f}",
                f"{alone_r2:.2f}",
                f"{held[1]:.0f}us",
            )
        )
    out.append(("all four", f"{totals[0]:.0f}us", "", "", f"{totals[1]:.0f}us"))
    print(f"Slope per live event, day 1's first 40s, one step, previous frame kept ({len(pairs)} frames):\n")
    table(
        ["bucket", "per live event, alone", "correlation", "R2", "per live event, previous frame held fixed"],
        out,
    )


def scenery(rows: list[Row]) -> None:
    heading("8. Scenery")
    with_jobs = [r for r in rows if jobs(r)]
    print(
        f"frames with a scenery update {sum(1 for r in rows if r['scenery_updates'])}, "
        f"with a job {len(with_jobs)}; jobs by kind "
        f"{ {name: sum(r[name] for r in rows) for name in JOBS} }"
    )
    over = [r["scenery_over_budget_usec"] for r in rows if r["scenery_over_budget_usec"]]
    print(
        f"over its 2ms budget in {len(over)} frames, by at most {ms(max(over, default=0)):.1f}ms; "
        f"deferred share {ms(sum(r['scenery_deferred_usec'] for r in rows)):.1f}ms of "
        f"{ms(sum(r['scenery_usec'] for r in rows)):.1f}ms in all\n"
    )
    neighbours = []
    for i, r in enumerate(rows):
        if not jobs(r):
            continue
        near = [
            rows[j]
            for j in range(max(0, i - 3), min(len(rows), i + 4))
            if j != i and not jobs(rows[j]) and abs(rows[j]["process_frame"] - r["process_frame"]) <= 3
        ]
        if near:
            neighbours.append(
                (
                    ms(r["frame_usec"]) - median(ms(n["frame_usec"]) for n in near),
                    ms(r["scenery_usec"]) - median(ms(n["scenery_usec"]) for n in near),
                )
            )
    table(
        ["", "frames", "frame p50", "scenery mean", "scenery max"],
        [
            (
                "with a job",
                len(with_jobs),
                median(ms(r["frame_usec"]) for r in with_jobs),
                mean(ms(r["scenery_usec"]) for r in with_jobs),
                max(ms(r["scenery_usec"]) for r in with_jobs),
            ),
            (
                "without",
                len(rows) - len(with_jobs),
                median(ms(r["frame_usec"]) for r in rows if not jobs(r)),
                mean(ms(r["scenery_usec"]) for r in rows if not jobs(r)),
                max(ms(r["scenery_usec"]) for r in rows if not jobs(r)),
            ),
        ],
    )
    print(
        f"A job frame against its job-free neighbours (three frames either side), "
        f"{len(neighbours)} frames: frame longer by p50 "
        f"{median(n[0] for n in neighbours):.1f}ms, scenery by p50 "
        f"{median(n[1] for n in neighbours):.1f}ms\n"
    )


def limits(record: dict[str, object], rows: list[Row]) -> None:
    heading("9. The clock and the record's own cost")
    env = record["environment"]
    assert isinstance(env, dict)
    step = int(env["timer_resolution_usec"])
    off_step = sum(1 for r in rows for b in BUCKETS if r[f"{b}_usec"] % step)
    print(f"bucket values not a whole number of {step}us steps: {off_step}")
    calls = [r["timer_calls"] for r in rows]
    pair = float(env["timer_pair_usec"])
    print(
        f"timed calls a frame p50 {median(calls):.0f} (max {max(calls)}); "
        f"pair {pair}us, so the pairs alone are {pair * median(calls) / 1000:.1f}ms a frame, "
        f"{100 * pair * median(calls) / median(r['frame_usec'] for r in rows):.0f}% of the median frame"
    )
    print(
        f"influence (one interval a step) reads 0 in "
        f"{sum(1 for r in rows if r['physics_steps'] and not r['influence_usec'])} of "
        f"{sum(1 for r in rows if r['physics_steps'])} frames with a step\n"
    )
    outside = [r for r in rows if r["frame_usec"] - r["wait_usec"] < int(env["display_budget_usec"])]
    print(f"frames whose callbacks fit one 60Hz budget (outside_callbacks): {len(outside)}\n")


SECTIONS: list[Callable[[dict[str, object], list[Row]], None]] = [
    coverage,
    lambda _record, rows: distribution(rows),
    lambda _record, rows: over_time(rows),
    buckets,
    lambda _record, rows: steps(rows),
    lambda _record, rows: tracking(rows),
    lambda _record, rows: workload(rows),
    lambda _record, rows: scenery(rows),
    limits,
]


def main(argv: list[str]) -> int:
    if any(a in ("-h", "--help") for a in argv):
        print(__doc__)
        return 0
    if len(argv) > 1 or any(a.startswith("-") for a in argv):
        print(f"unrecognized argument(s): {' '.join(argv)}\n\n{__doc__}", file=sys.stderr)
        return 2
    record, rows = load(Path(argv[0]) if argv else DEFAULT)
    for section in SECTIONS:
        section(record, rows)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
