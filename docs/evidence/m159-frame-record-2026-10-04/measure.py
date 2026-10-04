"""Measure the per-system frame record on the player's seed-67 route, native and windowed.

Two parts, run serially, one engine at a time:

  cost   the record's cost: `main` against this branch with the record off, and this branch
         with the record off against on, VSync off so a frame's length is its work. The same
         collector (`--frame-trace`, identical bytes in both checkouts) times every run.
  modes  a sample recording (`--frame-record`) in ground mode 2 and in mode 1, VSync on as a
         player plays, for the summary's slow-frame counts with and without a scenery job.

Each part runs one warmup per condition (discarded), then rotated rounds. Before every capture it
waits for every other Godot process to end; a capture another engine ran beside is kept under a
rejected name and taken again in the same slot. Both checkouts must be clean, and their runtime
files are hashed before the first capture and checked again before every one.
"""

import argparse
import gzip
import hashlib
import json
import os
import shutil
import statistics
import subprocess
import sys
import threading
import time
from pathlib import Path

# The player's route (docs/playtests/2026-10-03-quiet-yak.md, "## #510": "seed 67 one block to the
# right walking up all the way squeezing through car accident and going middle between stalls and
# then walking back"): east from the door to the street at tile column 87, north up it, stepping
# a block-width west round the car accident at (87,38) and back, to the city's top edge, then the
# same back down to the door's row.
WALK = "2.6e15.5n1w4n1e11n11s1w4s1e15.5s"
AFTER_SECONDS = 70
BASE_FLAGS = ["--seed", "67", "--no-title", "--invincible", "--no-focus-pause", "--no-save",
              "--no-telemetry", "--after", str(AFTER_SECONDS), "--walk", WALK]
COLLECTOR = ["src/telemetry/frame_trace.gd", "src/telemetry/frame_trace_buffer.gd"]
RUNTIME_PATHS = ["src", "scenes", "project.godot", "assets"]
RUN_TIMEOUT_SECONDS = 180
WAIT_FOR_ENGINES_SECONDS = 3600


def conditions(part):
    if part == "cost":
        engine = ["--always-on-top", "--disable-vsync", "--resolution", "1280x720"]
        common = BASE_FLAGS + ["--player-view", "--frame-trace"]
        return [
            {"name": "main-off", "tree": "main", "engine": engine, "flags": common},
            {"name": "branch-off", "tree": "branch", "engine": engine, "flags": common},
            {"name": "branch-on", "tree": "branch", "engine": engine,
             "flags": common + ["--frame-record"]},
        ]
    engine = ["--always-on-top", "--resolution", "1280x720"]
    return [
        {"name": f"mode{mode}", "tree": "branch", "engine": engine,
         "flags": BASE_FLAGS + ["--frame-record", "--ground-mode", str(mode)]}
        for mode in (2, 1)
    ]


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root, text=True).strip()


def snapshot(root):
    if git(root, "status", "--porcelain", "--untracked-files=no"):
        raise SystemExit(f"checkout has tracked changes: {root}")
    digest = hashlib.sha256()
    for name in sorted(git(root, "ls-files", *RUNTIME_PATHS).splitlines()):
        digest.update(name.encode() + b"\0" + hashlib.sha256((root / name).read_bytes()).digest())
    return {"revision": git(root, "rev-parse", "HEAD"), "runtime_sha256": digest.hexdigest(),
            "collector_sha256": {name: hashlib.sha256((root / name).read_bytes()).hexdigest()
                                 for name in COLLECTOR}}


def other_engines(engine_name):
    found = []
    for line in subprocess.check_output(["ps", "-axo", "pid=,args="], text=True).splitlines():
        parts = line.split(None, 2)
        if len(parts) < 2:
            continue
        program = os.path.basename(parts[1])
        if program in ("Godot", engine_name) and int(parts[0]) != os.getpid():
            found.append(line.strip()[:200])
    return found


def wait_for_quiet(engine_name):
    deadline = time.time() + WAIT_FOR_ENGINES_SECONDS
    while True:
        others = other_engines(engine_name)
        if not others:
            return
        if time.time() > deadline:
            raise SystemExit(f"another Godot process kept running: {others}")
        time.sleep(5)


def load_average():
    return os.getloadavg()


def capture(godot, root, condition, label, output):
    """Launches one run; answers (status, log path, competition lines)."""
    log_path = output / f"{label}.log"
    command = [godot, "--path", str(root), *condition["engine"], "--", *condition["flags"]]
    competition = []
    with log_path.open("w") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT)
        stop = threading.Event()

        def sample():
            name = os.path.basename(godot)
            while not stop.wait(1.0):
                for line in other_engines(name):
                    if not line.startswith(f"{process.pid} "):
                        competition.append(line)

        sampler = threading.Thread(target=sample, daemon=True)
        sampler.start()
        try:
            status = process.wait(timeout=RUN_TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired:
            process.kill()
            status = "timeout"
        stop.set()
        sampler.join()
    return command, status, log_path, competition


def trace_summary(path):
    data = json.loads(path.read_text())
    columns = data["columns"]
    rows = data["samples"]
    interval = columns.index("interval_usec")
    ys = [row[columns.index("player_y_millipx")] / 1000.0 for row in rows]
    days = {row[columns.index("day")] for row in rows}
    intervals = sorted(row[interval] for row in rows if row[interval] > 0)
    # A covered window skips its draw step on macOS, and the trace samples only drawn frames: a
    # process frame between two consecutive samples of one segment is a frame that was not drawn.
    process = columns.index("process_frame")
    undrawn = sum(max(0, row[process] - previous[process] - 1)
                  for previous, row in zip(rows, rows[1:]) if row[interval] > 0)
    return {
        "frames": len(intervals),
        "undrawn_process_frames": undrawn,
        "dropped_after_capacity": data["dropped_after_capacity"],
        "mean_ms": round(statistics.fmean(intervals) / 1000.0, 4),
        "p50_ms": data["summary"]["p50_ms"],
        "p95_ms": data["summary"]["p95_ms"],
        "p99_ms": data["summary"]["p99_ms"],
        "max_ms": data["summary"]["max_ms"],
        "over_60hz_budget": data["summary"]["over_60hz_budget"],
        "over_30hz_budget": data["summary"]["over_30hz_budget"],
        "northmost_y_px": round(min(ys), 1),
        "last_y_px": round(ys[-1], 1),
        "days": sorted(days),
        "median_live_events": statistics.median(row[columns.index("live_events")] for row in rows),
        "median_crowd": statistics.median(row[columns.index("crowd_agents")] for row in rows),
        "vsync_mode": data["environment_start"].get("vsync_mode"),
        "refresh_hz": data["environment_start"].get("refresh_hz"),
        "window_size": data["environment_start"].get("window_size"),
    }


def record_summary(path):
    data = json.loads(path.read_text())
    columns = data["columns"]
    rows = data["rows"]
    calls = [row[columns.index("timer_calls")] for row in rows]
    drawn = sum(row[columns.index("drawn")] for row in rows)
    ys = [row[columns.index("player_y")] for row in rows]
    summary = data["summary"]
    environment = data["environment"]
    return {
        "rows": len(rows),
        "undrawn_rows": len(rows) - drawn,
        "overwritten": data.get("overwritten"),
        "ground_mode": environment.get("ground_mode"),
        "refresh_hz": environment.get("refresh_hz"),
        "display_budget_usec": environment.get("display_budget_usec"),
        "timer_pair_usec": environment.get("timer_pair_usec"),
        "timer_resolution_usec": environment.get("timer_resolution_usec"),
        "mean_timer_calls": round(statistics.fmean(calls), 1),
        "own_cost_us_per_frame": round(statistics.fmean(calls) * environment["timer_pair_usec"], 1),
        "northmost_y_px": min(ys),
        "last_y_px": ys[-1],
        "summary": summary,
    }


def found_path(log_path, prefix):
    match = None
    for line in log_path.read_text(errors="replace").splitlines():
        if line.startswith(prefix):
            match = Path(line[len(prefix):].strip())
    return match


def accept(condition, status, log_path, trace, record):
    text = log_path.read_text(errors="replace")
    reasons = []
    if status != 0:
        reasons.append(f"exit {status}")
    if "SCRIPT ERROR" in text:
        reasons.append("script error in log")
    wants_trace = "--frame-trace" in condition["flags"]
    wants_record = "--frame-record" in condition["flags"]
    if wants_trace and trace is None:
        reasons.append("no frame trace written")
    if wants_record and record is None:
        reasons.append("no frame record written")
    track = trace or record
    if track is not None:
        if track["northmost_y_px"] > 200:
            reasons.append(f"never reached the top edge (northmost y {track['northmost_y_px']})")
        if track["last_y_px"] < 2300:
            reasons.append(f"never came back down (last y {track['last_y_px']})")
    if trace is not None and trace["undrawn_process_frames"] > trace["frames"] // 200:
        reasons.append(f"{trace['undrawn_process_frames']} process frames not drawn (covered window)")
    if record is not None and record["undrawn_rows"] > record["rows"] // 200:
        reasons.append(f"{record['undrawn_rows']} recorded frames not drawn (covered window)")
    if trace is not None:
        if trace["dropped_after_capacity"]:
            reasons.append("trace capacity exceeded")
        if trace["days"] != [1]:
            reasons.append(f"left day 1: {trace['days']}")
    if record is not None and "--ground-mode" in condition["flags"]:
        wanted = int(condition["flags"][condition["flags"].index("--ground-mode") + 1])
        if record["ground_mode"] != wanted:
            reasons.append(f"ran ground mode {record['ground_mode']}, not {wanted}")
    return reasons


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--branch", required=True, type=Path, help="checkout of this branch")
    parser.add_argument("--main", required=True, type=Path, help="checkout of origin/main")
    parser.add_argument("--output", required=True, type=Path, help="new scratch directory")
    parser.add_argument("--godot", help="Godot executable (else GODOT, else the macOS app)")
    parser.add_argument("--part", choices=["cost", "modes", "all"], default="all")
    parser.add_argument("--cost-rounds", type=int, default=5)
    parser.add_argument("--mode-rounds", type=int, default=3)
    args = parser.parse_args()
    roots = {"branch": args.branch.resolve(), "main": args.main.resolve()}
    output = args.output.resolve()
    if output.exists():
        parser.error(f"output already exists: {output}")
    godot = args.godot or os.environ.get("GODOT") or "/Applications/Godot.app/Contents/MacOS/Godot"
    godot = shutil.which(godot) or godot
    if not os.access(godot, os.X_OK):
        parser.error(f"not executable: {godot}")
    identity = {name: snapshot(root) for name, root in roots.items()}
    if identity["branch"]["collector_sha256"] != identity["main"]["collector_sha256"]:
        parser.error("the frame trace collector differs between the checkouts")
    output.mkdir(parents=True)
    for name, root in roots.items():
        with (output / f"{name}-check.log").open("w") as log:
            subprocess.run(["./tools/check.sh"], cwd=root, env=dict(os.environ, GODOT=godot),
                           stdout=log, stderr=subprocess.STDOUT, check=True, timeout=600)
        if snapshot(root) != identity[name]:
            raise SystemExit(f"runtime changed during the boot check: {root}")

    parts = ["cost", "modes"] if args.part == "all" else [args.part]
    schedule = []
    for part in parts:
        listed = conditions(part)
        rounds = args.cost_rounds if part == "cost" else args.mode_rounds
        for condition in listed:
            schedule.append((part, condition, "warmup"))
        for round_index in range(rounds):
            shift = round_index % len(listed)
            for condition in listed[shift:] + listed[:shift]:
                schedule.append((part, condition, f"r{round_index + 1}"))
    provenance = {"command": sys.argv, "godot": godot, "identity": identity,
                  "walk": WALK, "after_seconds": AFTER_SECONDS,
                  "schedule": [[part, c["name"], trial] for part, c, trial in schedule]}
    (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")

    results = []
    engine_name = os.path.basename(godot)
    for order, (part, condition, trial) in enumerate(schedule):
        root = roots[condition["tree"]]
        label = f"{order:02d}-{part}-{condition['name']}-{trial}"
        for attempt in range(1, 6):
            if snapshot(root) != identity[condition["tree"]]:
                raise SystemExit(f"runtime changed before {label}: {root}")
            wait_for_quiet(engine_name)
            load = load_average()
            started = time.strftime("%Y-%m-%dT%H:%M:%S")
            print(f"{started} {label} attempt {attempt} load {load[0]:.2f}", flush=True)
            command, status, log_path, competition = capture(godot, root, condition, label, output)
            trace_path = found_path(log_path, "Frame trace: ")
            record_path = found_path(log_path, "Frame record: ")
            if competition:
                for kind, path in [("log", log_path), ("trace", trace_path),
                                   ("record", record_path)]:
                    if path and path.exists():
                        shutil.move(path, output / f"{label}.attempt{attempt}-rejected.{kind}")
                results.append({"label": label, "attempt": attempt, "rejected": True,
                                "reasons": ["another Godot process ran beside it"],
                                "competition": sorted(set(competition))[:5]})
                continue
            break
        else:
            raise SystemExit(f"every attempt at {label} ran beside another engine")
        trace = record = None
        if trace_path and trace_path.exists():
            kept = output / f"{label}.trace.json"
            shutil.move(trace_path, kept)
            trace = trace_summary(kept)
        if record_path and record_path.exists():
            kept = output / f"{label}.record.json"
            shutil.move(record_path, kept)
            record = record_summary(kept)
        reasons = accept(condition, status, log_path, trace, record)
        entry = {"label": label, "order": order, "part": part, "condition": condition["name"],
                 "trial": trial, "attempt": attempt, "started": started,
                 "load_average_before": [round(value, 2) for value in load],
                 "command": command[:1] + ["--path", condition["tree"]] + command[3:],
                 "status": status, "rejected": bool(reasons), "reasons": reasons,
                 "trace": trace, "record": record}
        results.append(entry)
        (output / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        brief = {key: (trace or {}).get(key) for key in ("frames", "p50_ms", "p95_ms", "p99_ms",
                                                         "max_ms")}
        print(f"  -> {'REJECTED ' + '; '.join(reasons) if reasons else 'ok'} {brief}", flush=True)
        if reasons:
            raise SystemExit(f"capture rejected: {label}; investigate before more launches")
    for path in output.glob("*.json"):
        if path.name.endswith((".trace.json", ".record.json")):
            path.with_suffix(".json.gz").write_bytes(gzip.compress(path.read_bytes(), mtime=0))
            path.unlink()
    print(f"results: {output / 'results.json'}")


if __name__ == "__main__":
    main()
