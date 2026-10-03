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


COLLECTOR_FILES = ["entity_frame_profile.gd", "entity_frame_profile.tscn", "entity_frame_profile_observer.gd"]


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

    hashes = {}
    for filename in COLLECTOR_FILES:
        relative = f"tests/probes/{filename}"
        before = (roots["before"] / relative).read_bytes()
        after = (roots["after"] / relative).read_bytes()
        if before != after:
            parser.error(f"collector differs between checkouts: {relative}")
        hashes[filename] = hashlib.sha256(after).hexdigest()
    analyzer_relative = "tests/probes/entity_frame_profile_analyze.py"
    before_analyzer = (roots["before"] / analyzer_relative).read_bytes()
    after_analyzer = (roots["after"] / analyzer_relative).read_bytes()
    if before_analyzer != after_analyzer:
        parser.error(f"collector differs between checkouts: {analyzer_relative}")
    return {
        "revisions": {
            name: _git_output(parser, root, "rev-parse", "HEAD") for name, root in roots.items()
        },
        "collectors_sha256": hashes,
        "analyzer_sha256": hashlib.sha256(after_analyzer).hexdigest(),
    }


def _require_unchanged(parser, expected, roots, moment):
    if _snapshot_inputs(parser, roots) != expected:
        parser.error(f"measurement inputs changed {moment}")


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
    args.baseline = args.baseline.resolve()
    args.after = args.after.resolve()
    args.output = args.output.resolve()
    roots = {"before": args.baseline, "after": args.after}
    inputs = _snapshot_inputs(parser, roots)
    _validate_output(parser, args.output)
    godot = _resolve_godot(parser, args.godot)
    try:
        args.output.mkdir()
    except OSError as error:
        parser.error(f"cannot create output directory {args.output}: {error}")

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

    _require_unchanged(parser, inputs, roots, "during boot checks")
    analyzer = args.after / "tests/probes/entity_frame_profile_analyze.py"
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
        "collectors_sha256": inputs["collectors_sha256"],
        "analyzer_sha256": inputs["analyzer_sha256"],
        "warmup_seconds": 5,
        "active_seconds": 6,
        "godot": godot,
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
