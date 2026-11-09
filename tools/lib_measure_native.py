#!/usr/bin/env python3
"""The shared runner for native entity-frame comparisons between two checkouts.

An experiment under `docs/evidence/` that compares a baseline checkout with a changed one on the
`tests/probes/entity_frame_profile*` collectors calls `main()` here from its own `measure-native.py`
with its description, the source files whose hashes its provenance records, and its default launch
order. Every refusal (a checkout that is not a directory, one with dirty tracked files, an output
path that exists, collectors that differ between the two) happens before any launch.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path
from typing import Any, NoReturn

COLLECTOR_FILES = ("entity_frame_profile.gd", "entity_frame_profile.tscn", "entity_frame_profile_observer.gd")
ANALYZER = "tests/probes/entity_frame_profile_analyze.py"
ORDERS = ("before-after", "after-before", "alternating")


def _git_output(parser: argparse.ArgumentParser, root: Path, *args: str) -> str:
    try:
        return subprocess.check_output(["git", *args], cwd=root, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        parser.error(f"cannot inspect project checkout {root}: {error}")


def _validate_output(parser: argparse.ArgumentParser, output: Path) -> None:
    if output.exists():
        parser.error(f"output path already exists: {output}")
    if not output.parent.is_dir():
        parser.error(f"output parent is not a directory: {output.parent}")


def _snapshot_inputs(parser: argparse.ArgumentParser, roots: dict[str, Path], sources: Sequence[str]) -> dict[str, Any]:
    required = ["tools/check.sh", *(f"tests/probes/{name}" for name in COLLECTOR_FILES), ANALYZER, *sources]
    for name, root in roots.items():
        if not root.is_dir():
            parser.error(f"{name} checkout is not a directory: {root}")
        missing = [relative for relative in required if not (root / relative).is_file()]
        if missing:
            parser.error(f"{name} checkout {root} is missing: {', '.join(missing)}")
        if _git_output(parser, root, "status", "--porcelain", "--untracked-files=no"):
            parser.error(f"{name} checkout has dirty tracked files: {root}")

    hashes = {}
    for filename in COLLECTOR_FILES:
        relative = f"tests/probes/{filename}"
        after = (roots["after"] / relative).read_bytes()
        if (roots["before"] / relative).read_bytes() != after:
            parser.error(f"collector differs between checkouts: {relative}")
        hashes[filename] = hashlib.sha256(after).hexdigest()
    after_analyzer = (roots["after"] / ANALYZER).read_bytes()
    if (roots["before"] / ANALYZER).read_bytes() != after_analyzer:
        parser.error(f"collector differs between checkouts: {ANALYZER}")
    snapshot: dict[str, Any] = {
        "revisions": {name: _git_output(parser, root, "rev-parse", "HEAD") for name, root in roots.items()},
        "collectors_sha256": hashes,
        "analyzer_sha256": hashlib.sha256(after_analyzer).hexdigest(),
    }
    if sources:
        snapshot["source_sha256"] = {
            name: {relative: hashlib.sha256((root / relative).read_bytes()).hexdigest() for relative in sources}
            for name, root in roots.items()
        }
    return snapshot


def _require_unchanged(
    parser: argparse.ArgumentParser,
    expected: dict[str, Any],
    roots: dict[str, Path],
    sources: Sequence[str],
    moment: str,
) -> None:
    if _snapshot_inputs(parser, roots, sources) != expected:
        parser.error(f"measurement inputs changed {moment}")


def _resolve_godot(parser: argparse.ArgumentParser, requested: str | None) -> str:
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


def _fail(message: str) -> NoReturn:
    raise SystemExit(message)


def main(
    description: str,
    example_output: str,
    default_order: str = "before-after",
    sources: Sequence[str] = (),
) -> None:
    """Runs the comparison. `sources` are files both checkouts must hold, hashed into the provenance."""
    parser = argparse.ArgumentParser(
        description=description,
        epilog=f"example: measure-native.py --baseline ../before --after ../after --output {example_output}",
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
        choices=ORDERS,
        default=default_order,
        help=f"launch order inside every pair (default: {default_order})",
    )
    args = parser.parse_args()
    baseline = args.baseline.resolve()
    after = args.after.resolve()
    output = args.output.resolve()
    roots = {"before": baseline, "after": after}
    inputs = _snapshot_inputs(parser, roots, sources)
    _validate_output(parser, output)
    godot = _resolve_godot(parser, args.godot)
    try:
        output.mkdir()
    except OSError as error:
        parser.error(f"cannot create output directory {output}: {error}")

    check_commands = {}
    check_environment = dict(os.environ, GODOT=godot)
    for name, root in roots.items():
        command = ["./tools/check.sh"]
        check_commands[name] = {"cwd": str(root), "argv": command, "environment": {"GODOT": godot}}
        with (output / f"{name}-check.log").open("w") as log:
            subprocess.run(
                command, cwd=root, env=check_environment, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=180
            )

    _require_unchanged(parser, inputs, roots, sources, "during boot checks")
    spec = importlib.util.spec_from_file_location("analyzer", after / ANALYZER)
    if spec is None or spec.loader is None:
        _fail(f"cannot load the analyzer: {after / ANALYZER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    modes = ["profiled", "disabled"] if args.mode == "both" else [args.mode]
    runs: list[dict[str, Any]] = []
    for mode in modes:
        for pair in range(1, 4):
            order = ("after-before" if pair % 2 == 0 else "before-after") if args.order == "alternating" else args.order
            for side in order.split("-"):
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
    if sources:
        provenance["source_sha256"] = inputs["source_sha256"]
    (output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")

    for run in runs:
        _require_unchanged(parser, inputs, roots, sources, "before a capture")
        side = run["side"]
        disabled = run["mode"] == "disabled"
        prefix = output / f"{side}-{run['mode']}-{run['pair']}"
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
            _fail("Rejected capture retained; investigate before further launches")


if __name__ == "__main__":
    _fail("tools/lib_measure_native.py is called from an experiment's measure-native.py, not run itself")
