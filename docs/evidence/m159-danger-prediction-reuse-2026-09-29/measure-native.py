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
    requested = args.godot or os.environ.get("GODOT")
    godot = shutil.which(requested) if requested else (
        shutil.which("godot") or shutil.which("/Applications/Godot.app/Contents/MacOS/Godot"))
    if not godot:
        parser.error("Godot executable unavailable; provide --godot or GODOT")
    godot = str(Path(godot).resolve())
    args.baseline = args.baseline.resolve()
    args.after = args.after.resolve()
    args.output = args.output.resolve()
    for root in [args.baseline, args.after]:
        if not (root / "tools/check.sh").is_file():
            parser.error(f"Not a project checkout: {root}")
    args.output.mkdir(exist_ok=False)

    check_commands = {}
    for name, root in [("before", args.baseline), ("after", args.after)]:
        command = ["./tools/check.sh"]
        check_commands[name] = {"cwd": str(root.resolve()), "argv": command}
        with (args.output / f"{name}-check.log").open("w") as log:
            subprocess.run(command, cwd=root, env=dict(os.environ, GODOT=godot),
                           stdout=log, stderr=subprocess.STDOUT,
                           check=True, timeout=180)

    collector_files = ["entity_frame_profile.gd", "entity_frame_profile.tscn",
                       "entity_frame_profile_observer.gd"]
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
        "collectors_sha256": hashes,
        "analyzer_sha256": hashlib.sha256(analyzer.read_bytes()).hexdigest(),
        "warmup_seconds": 5,
        "active_seconds": 6,
        "mode": args.mode,
        "order": args.order,
        "runs": runs,
        "revisions": {
            name: subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root,
                                          text=True).strip()
            for name, root in [("before", args.baseline), ("after", args.after)]
        },
    }
    (args.output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")

    roots = {"before": args.baseline, "after": args.after}
    for run in runs:
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
