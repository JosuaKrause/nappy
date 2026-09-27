"""Decode native profiler records and reject incomplete active-play windows."""

import argparse
import collections
import gzip
import json
import math
import statistics
from pathlib import Path


def stats(values):
    ordered = sorted(values)
    if not ordered:
        return None
    return {
        "median": statistics.median(ordered),
        "p95": ordered[math.ceil(len(ordered) * 0.95) - 1],
        "p99": ordered[math.ceil(len(ordered) * 0.99) - 1],
        "max": ordered[-1],
        "mean": statistics.mean(ordered),
    }


def read_json(path):
    if path.exists():
        return json.loads(path.read_text())
    return json.loads(gzip.decompress(Path(str(path) + ".gz").read_bytes()))


def analyze(prefix, profiler_disabled=False):
    scene = read_json(Path(str(prefix) + "-scene.json"))
    raw = read_json(Path(str(prefix) + "-profiler.json"))
    messages = raw["messages"]
    signatures = {
        data[1]: data[0]
        for name, _thread, data in messages
        if name == "servers:function_signature"
    }
    frames = {}
    for name, _thread, data in messages:
        if name != "servers:profile_frame":
            continue
        offset = 7
        for _ in range(data[6]):
            offset += 2 + data[offset + 1]
        count = data[offset]
        offset += 1
        assert count % 5 == 0 and len(data) == offset + count
        assert data[0] not in frames
        functions = {}
        for i in range(offset, len(data), 5):
            signature = signatures[data[i]]
            assert signature not in functions
            functions[signature] = data[i + 1 : i + 5]
        # All emitted self times must agree with the engine's emitted script total.
        assert abs(sum(f[1] for f in functions.values()) - data[5]) < 0.000002
        frames[data[0]] = (data, functions)
    rows = scene["rows"]
    selected = [r for r in rows if 5000000 <= r[4] < 11000000]
    reasons = []
    if raw["timed_out"]:
        reasons.append("receiver timeout")
    if not selected or rows[-1][4] < 11000000:
        reasons.append("truncated window")
    if any(not r[5] or r[6] for r in rows):
        reasons.append("paused or ended day")
    distance = sum(
        math.dist(a[7:9], b[7:9]) for a, b in zip(selected, selected[1:])
    )
    north_distance = selected[0][8] - selected[-1][8] if selected else 0
    if north_distance < 450:
        reasons.append("northward net movement below 450 pixels; expected about 552")
    input_evidence = all(r[12] for r in selected) if selected and len(selected[0]) > 12 else None
    if input_evidence is False:
        reasons.append("north input not held throughout retained window")
    if distance < 50:
        reasons.append("player travels less than 50 pixels in measured window")
    if not any(r[10] for r in selected):
        reasons.append("no moving cars")
    errors = [data for name, _thread, data in messages if name == "error" and not data[9]]
    if errors:
        reasons.append("native debugger errors")
    enabled = not profiler_disabled
    assert raw.get("profiler_enabled", enabled) == enabled, "Profiler mode disagrees with capture"
    missing = [r[0] for r in selected if r[0] not in frames] if enabled else []
    if enabled and missing:
        reasons.append("missing profile frames")
    effective_cap = min(raw.get("requested_max_functions", 16384),
                        scene.get("profiler_max_functions", 16384))
    if frames and any(len(frames[r[0]][1]) >= effective_cap for r in selected if r[0] in frames):
        reasons.append("function record cap reached")
    if len(signatures) >= scene.get("profiler_max_functions", 16384):
        reasons.append("engine signature storage cap reached")
    counts = {
        name: stats([r[9][i] for r in selected])
        for i, name in enumerate(scene["count_columns"])
    }
    previous = {b[0]: a for a, b in zip(rows, rows[1:])}
    ticks = {r[0]: r[1] - previous[r[0]][1] for r in selected if r[0] in previous}
    drawn = [r[2] - previous[r[0]][2] for r in selected if r[0] in previous]
    if scene["display"] != "headless" and (not drawn or sum(drawn) < len(drawn) * 0.95):
        reasons.append("rendered frame counter advances on fewer than 95% of measured frames")
    mismatches = []
    for r in selected:
        if r[0] not in frames:
            continue
        baby_calls = sum(f[0] for s, f in frames[r[0]][1].items()
                         if "baby.gd" in s and s.endswith("._physics_process"))
        if baby_calls != ticks[r[0]]:
            mismatches.append(r[0])
    if mismatches:
        reasons.append("profiler physics callback counts disagree with scene tick deltas")
    summary = {
        "prefix": str(prefix), "accepted": not reasons, "rejections": reasons,
        "frames": len(selected), "profile_frames": len(frames),
        "profiler_enabled": enabled, "physics_alignment_mismatches": mismatches,
        "unique_function_signatures": len(signatures),
        "missing_profile_frames": missing, "population": counts,
        "player_path_pixels": distance,
        "northward_net_pixels": north_distance, "north_input_held": input_evidence,
        "draws_per_process_frame": dict(collections.Counter(drawn)),
        "moving_cars_per_frame": stats([r[10] for r in selected]),
        "ticks_per_frame": dict(collections.Counter(ticks.values())),
        "callback_interval_ms": stats([
            (r[3] - previous[r[0]][3]) / 1000 for r in selected if r[0] in previous
        ]),
        "observer_ms": stats([r[11] / 1000 for r in selected]),
        "compiler_warnings": sum(name == "error" and data[9] for name, _, data in messages),
        "errors": errors,
        "environment": {k: v for k, v in scene.items() if k != "rows"},
    }
    if not frames:
        return summary
    selected = [r for r in selected if r[0] in frames]
    ids = [r[0] for r in selected]
    active_signatures = set().union(*(frames[i][1] for i in ids))
    totals = {}
    for signature in active_signatures:
        values = [frames[i][1].get(signature, [0, 0, 0, 0]) for i in ids]
        totals[signature] = {
            "self_ms": stats([f[1] * 1000 for f in values]),
            "inclusive_ms": stats([f[2] * 1000 for f in values]),
            "calls": stats([f[0] for f in values]),
        }
        if signature.endswith("._physics_process"):
            one_tick = [frames[i][1].get(signature, [0, 0, 0, 0]) for i in ids if ticks[i] == 1]
            totals[signature]["one_tick_inclusive_ms"] = stats([f[2] * 1000 for f in one_tick])
            totals[signature]["one_tick_samples"] = len(one_tick)
    summary["functions"] = dict(sorted(totals.items(), key=lambda x: -x[1]["self_ms"]["mean"]))
    summary["native_ms"] = {
        name: stats([frames[i][0][n] * 1000 for i in ids])
        for n, name in [(1, "frame_main_loop_wall"), (2, "process_and_render_submit"),
                        (3, "worst_physics_tick_in_frame"), (5, "script_self_sum")]
    }
    summary["emitted_functions_per_frame"] = stats([len(frames[i][1]) for i in ids])
    summary["most_expensive_frames"] = sorted(
        [{"frame": i, "main_loop_wall_ms": frames[i][0][1] * 1000, "ticks": ticks[i],
          "top_self": sorted(
              [[s, f[1] * 1000, f[0]] for s, f in frames[i][1].items()],
              key=lambda f: -f[1])[:10]} for i in ids],
        key=lambda f: -f["main_loop_wall_ms"],
    )[:10]
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("prefix", type=Path, help="Prefix of -scene.json and -profiler.json")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--profiler-disabled", action="store_true",
                        help="Require the companion mode without function profiling")
    args = parser.parse_args()
    result = analyze(args.prefix, args.profiler_disabled)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k not in
                      ("functions", "environment", "most_expensive_frames")}, indent=2))
    for name, values in list(result.get("functions", {}).items())[:12]:
        print(name, "self", values["self_ms"], "calls", values["calls"])


if __name__ == "__main__":
    main()
