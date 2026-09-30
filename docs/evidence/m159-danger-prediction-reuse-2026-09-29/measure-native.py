"""Run bounded, serial danger-prediction comparisons with identical native collectors."""

import argparse
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


COLLECTOR_FILES = [
    "entity_frame_profile.gd",
    "entity_frame_profile.tscn",
    "entity_frame_profile_observer.gd",
]
SOURCE_FILES = ["src/events/event_instance.gd", "src/crowd/crowd_agent.gd"]


def _git_output(parser, root, *args):
    try:
        return subprocess.check_output(["git", *args], cwd=root, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        parser.error(f"cannot inspect project checkout {root}: {error}")


def _validate_output(parser, output):
    if output.exists():
        parser.error(f"output path already exists: {output}")
    if not output.parent.is_dir():
        parser.error(f"output parent is not a directory: {output.parent}")


def _snapshot_inputs(parser, roots):
    required = [
        "tools/check.sh",
        *(f"tests/probes/{filename}" for filename in COLLECTOR_FILES),
        "tests/probes/entity_frame_profile_analyze.py",
        *SOURCE_FILES,
    ]
    for name, root in roots.items():
        if not root.is_dir():
            parser.error(f"{name} checkout is not a directory: {root}")
        missing = [relative for relative in required if not (root / relative).is_file()]
        if missing:
            parser.error(f"{name} checkout {root} is missing: {', '.join(missing)}")
        dirty = _git_output(parser, root, "status", "--porcelain", "--untracked-files=no")
        if dirty:
            parser.error(f"{name} checkout has dirty tracked files: {root}")

    collector_hashes = {}
    for filename in COLLECTOR_FILES:
        relative = f"tests/probes/{filename}"
        before = (roots["before"] / relative).read_bytes()
        after = (roots["after"] / relative).read_bytes()
        if before != after:
            parser.error(f"collector differs between checkouts: {relative}")
        collector_hashes[filename] = hashlib.sha256(after).hexdigest()
    analyzer_relative = "tests/probes/entity_frame_profile_analyze.py"
    before_analyzer = (roots["before"] / analyzer_relative).read_bytes()
    after_analyzer = (roots["after"] / analyzer_relative).read_bytes()
    if before_analyzer != after_analyzer:
        parser.error(f"collector differs between checkouts: {analyzer_relative}")

    return {
        "revisions": {
            name: _git_output(parser, root, "rev-parse", "HEAD") for name, root in roots.items()
        },
        "collectors_sha256": collector_hashes,
        "analyzer_sha256": hashlib.sha256(after_analyzer).hexdigest(),
        "source_sha256": {
            name: {
                relative: hashlib.sha256((root / relative).read_bytes()).hexdigest()
                for relative in SOURCE_FILES
            }
            for name, root in roots.items()
        },
    }


def _require_unchanged(parser, expected, roots, moment):
    current = _snapshot_inputs(parser, roots)
    if current != expected:
        parser.error(f"measurement inputs changed {moment}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--after", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--godot", help="Godot executable; overrides GODOT and discovery")
    parser.add_argument("--mode", choices=["both", "profiled", "disabled"], default="both")
    parser.add_argument("--order", choices=["before-after", "after-before", "alternating"],
                        default="alternating")
    args = parser.parse_args()
    args.baseline = args.baseline.resolve()
    args.after = args.after.resolve()
    args.output = args.output.resolve()
    roots = {"before": args.baseline, "after": args.after}
    inputs = _snapshot_inputs(parser, roots)
    _validate_output(parser, args.output)
    requested = args.godot or os.environ.get("GODOT")
    godot = shutil.which(requested) if requested else (
        shutil.which("godot") or shutil.which("/Applications/Godot.app/Contents/MacOS/Godot"))
    if not godot:
        parser.error("Godot executable unavailable; provide --godot or GODOT")
    godot = str(Path(godot).resolve())
    try:
        args.output.mkdir()
    except OSError as error:
        parser.error(f"cannot create output directory {args.output}: {error}")

    check_commands = {}
    for name, root in [("before", args.baseline), ("after", args.after)]:
        command = ["./tools/check.sh"]
        check_commands[name] = {"cwd": str(root.resolve()), "argv": command}
        with (args.output / f"{name}-check.log").open("w") as log:
            subprocess.run(command, cwd=root, env=dict(os.environ, GODOT=godot),
                           stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=180)

    _require_unchanged(parser, inputs, roots, "during boot checks")
    analyzer = args.after / "tests/probes/entity_frame_profile_analyze.py"
    spec = importlib.util.spec_from_file_location("analyzer", analyzer)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    modes = ["profiled", "disabled"] if args.mode == "both" else [args.mode]
    runs = []
    for mode in modes:
        for pair in range(1, 4):
            order = ("after-before" if pair % 2 == 0 else "before-after") \
                if args.order == "alternating" else args.order
            for side in order.split("-"):
                runs.append({"side": side, "mode": mode, "pair": pair})
    provenance = {
        "command": {"cwd": str(Path.cwd()), "argv": sys.argv},
        "godot": godot,
        "check_commands": check_commands,
        "collectors_sha256": inputs["collectors_sha256"],
        "analyzer_sha256": inputs["analyzer_sha256"],
        "source_sha256": inputs["source_sha256"],
        "warmup_seconds": 5,
        "active_seconds": 6,
        "mode": args.mode,
        "order": args.order,
        "runs": runs,
        "revisions": inputs["revisions"],
    }
    (args.output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")

    for run in runs:
        _require_unchanged(parser, inputs, roots, "before a capture")
        side = run["side"]
        disabled = run["mode"] == "disabled"
        prefix = args.output / f"{side}-{run['mode']}-{run['pair']}"
        environment = dict(os.environ, ENTITY_PROFILE_OUTPUT=str(prefix),
                           ENTITY_PROFILE_RENDERED="1",
                           ENTITY_PROFILE_DISABLED="1" if disabled else "0")
        command = [godot, "--headless", "--path", str(roots[side]), "--script",
                   "tests/probes/entity_frame_profile.gd"]
        with prefix.with_suffix(".log").open("w") as log:
            subprocess.run(command, env=environment, stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=60)
        summary = module.analyze(prefix, profiler_disabled=disabled)
        Path(str(prefix) + "-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
        for suffix in ["-scene.json", "-profiler.json"]:
            raw = Path(str(prefix) + suffix)
            Path(str(raw) + ".gz").write_bytes(gzip.compress(raw.read_bytes(), mtime=0))
            raw.unlink()
        print(json.dumps({"run": prefix.name, "accepted": summary["accepted"],
                          "rejections": summary["rejections"],
                          "native_ms": summary.get("native_ms"),
                          "callback_interval_ms": summary["callback_interval_ms"]}), flush=True)
        if not summary["accepted"]:
            raise SystemExit("Rejected capture retained; investigate before further launches")


if __name__ == "__main__":
    main()
