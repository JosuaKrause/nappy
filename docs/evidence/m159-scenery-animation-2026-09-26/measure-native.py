"""Run bounded, serial alternating scenery comparisons with identical native collectors."""

import argparse
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", required=True, type=Path)
    parser.add_argument("--after", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    args.output.mkdir(exist_ok=False)
    godot = "/Applications/Godot.app/Contents/MacOS/Godot"
    collector_files = ["entity_frame_profile.gd", "entity_frame_profile.tscn",
                       "entity_frame_profile_observer.gd"]
    hashes = {}
    for filename in collector_files:
        before = (args.baseline / "tests/probes" / filename).read_bytes()
        after = (args.after / "tests/probes" / filename).read_bytes()
        assert before == after, filename
        hashes[filename] = hashlib.sha256(after).hexdigest()
    analyzer = args.after / "tests/probes/entity_frame_profile_analyze.py"
    spec = importlib.util.spec_from_file_location("analyzer", analyzer)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    provenance = {"collectors_sha256": hashes,
                  "analyzer_sha256": hashlib.sha256(analyzer.read_bytes()).hexdigest(),
                  "warmup_seconds": 5, "active_seconds": 6,
                  "order": ["before", "after"] * 4,
                  "revisions": {name: subprocess.check_output(
                      ["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
                      for name, root in [("before", args.baseline), ("after", args.after)]}}
    (args.output / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    for pair in range(4):
        disabled = pair == 3
        for name, root in [("before", args.baseline), ("after", args.after)]:
            prefix = args.output / f"{name}-{'disabled' if disabled else pair + 1}"
            environment = dict(os.environ, ENTITY_PROFILE_OUTPUT=str(prefix),
                               ENTITY_PROFILE_RENDERED="1",
                               ENTITY_PROFILE_DISABLED="1" if disabled else "0")
            with prefix.with_suffix(".log").open("w") as log:
                subprocess.run([godot, "--headless", "--path", str(root), "--script",
                                "tests/probes/entity_frame_profile.gd"], env=environment,
                               stdout=log, stderr=subprocess.STDOUT, check=True, timeout=60)
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
