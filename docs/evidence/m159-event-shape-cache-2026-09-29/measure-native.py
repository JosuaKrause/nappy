"""Run bounded, serial event-shape-cache comparisons with identical native collectors."""

import argparse
import gzip
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def _resolve_godot(parser, requested):
    if requested:
        candidate = requested
        source = "--godot"
    elif os.environ.get("GODOT"):
        candidate = os.environ["GODOT"]
        source = "GODOT"
    else:
        on_path = shutil.which("godot")
        if on_path:
            return str(Path(on_path).resolve())
        if sys.platform == "darwin":
            candidate = "/Applications/Godot.app/Contents/MacOS/Godot"
            source = "the macOS application fallback"
        else:
            parser.error("no Godot executable found; use --godot, set GODOT, or put godot on PATH")

    resolved = shutil.which(candidate)
    if resolved is None:
        parser.error(
            f"{source} does not name an executable Godot binary: {candidate!r}; "
            "use --godot, set GODOT, or put godot on PATH"
        )
    return str(Path(resolved).resolve())


def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog=(
            "example: measure-native.py --baseline ../before --after ../after "
            "--output ./event-shape-output --godot ./bin/godot"
        ),
    )
    parser.add_argument("--baseline", required=True, type=Path, help="checkout of the recorded baseline revision")
    parser.add_argument("--after", required=True, type=Path, help="checkout of the recorded changed revision")
    parser.add_argument(
        "--output", required=True, type=Path, help="new directory for captures, logs, summaries and provenance"
    )
    parser.add_argument("--godot", help="Godot executable (then GODOT, PATH, or the macOS app)")
    parser.add_argument(
        "--mode",
        choices=["both", "profiled", "disabled"],
        default="both",
        help="collect profiled and/or profiler-disabled pairs (default: both)",
    )
    parser.add_argument(
        "--order",
        choices=["before-after", "after-before"],
        default="before-after",
        help="launch order inside every pair (default: before-after)",
    )
    args = parser.parse_args()
    godot = _resolve_godot(parser, args.godot)
    args.output.mkdir(exist_ok=False)

    check_commands = {}
    check_environment = dict(os.environ, GODOT=godot)
    for name, root in [("before", args.baseline), ("after", args.after)]:
        command = ["./tools/check.sh"]
        check_commands[name] = {
            "cwd": str(root.resolve()),
            "argv": command,
            "environment": {"GODOT": godot},
        }
        with (args.output / f"{name}-check.log").open("w") as log:
            subprocess.run(
                command, cwd=root, env=check_environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180
            )

    collector_files = ["entity_frame_profile.gd", "entity_frame_profile.tscn", "entity_frame_profile_observer.gd"]
    hashes = {}
    for filename in collector_files:
        before = (args.baseline / "tests/probes" / filename).read_bytes()
        after = (args.after / "tests/probes" / filename).read_bytes()
        assert before == after, filename
        hashes[filename] = hashlib.sha256(after).hexdigest()
    analyzer = args.after / "tests/probes/entity_frame_profile_analyze.py"
    before_analyzer = args.baseline / "tests/probes/entity_frame_profile_analyze.py"
    assert before_analyzer.read_bytes() == analyzer.read_bytes(), analyzer.name
    spec = importlib.util.spec_from_file_location("analyzer", analyzer)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    modes = ["profiled", "disabled"] if args.mode == "both" else [args.mode]
    sides = args.order.split("-")
    runs = []
    for mode in modes:
        for pair in range(1, 4):
            for side in sides:
                runs.append({"side": side, "mode": mode, "pair": pair})
    provenance = {
        "command": {"cwd": str(Path.cwd()), "argv": sys.argv},
        "check_commands": check_commands,
        "collectors_sha256": hashes,
        "analyzer_sha256": hashlib.sha256(analyzer.read_bytes()).hexdigest(),
        "warmup_seconds": 5,
        "active_seconds": 6,
        "godot": godot,
        "mode": args.mode,
        "order": args.order,
        "runs": runs,
        "revisions": {
            name: subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
            for name, root in [("before", args.baseline), ("after", args.after)]
        },
    }
    (args.output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")

    roots = {"before": args.baseline, "after": args.after}
    for run in runs:
        side = run["side"]
        disabled = run["mode"] == "disabled"
        prefix = args.output / f"{side}-{run['mode']}-{run['pair']}"
        environment = dict(
            check_environment,
            ENTITY_PROFILE_OUTPUT=str(prefix),
            ENTITY_PROFILE_RENDERED="1",
            ENTITY_PROFILE_DISABLED="1" if disabled else "0",
        )
        command = [godot, "--headless", "--path", str(roots[side]), "--script", "tests/probes/entity_frame_profile.gd"]
        with prefix.with_suffix(".log").open("w") as log:
            subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=60)
        summary = module.analyze(prefix, profiler_disabled=disabled)
        Path(str(prefix) + "-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
        for suffix in ["-scene.json", "-profiler.json"]:
            raw = Path(str(prefix) + suffix)
            Path(str(raw) + ".gz").write_bytes(gzip.compress(raw.read_bytes(), mtime=0))
            raw.unlink()
        print(
            json.dumps(
                {
                    "run": prefix.name,
                    "accepted": summary["accepted"],
                    "rejections": summary["rejections"],
                    "native_ms": summary.get("native_ms"),
                    "callback_interval_ms": summary["callback_interval_ms"],
                }
            ),
            flush=True,
        )
        if not summary["accepted"]:
            raise SystemExit("Rejected capture retained; investigate before further launches")


if __name__ == "__main__":
    main()
