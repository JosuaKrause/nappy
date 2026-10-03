#!/usr/bin/env python3
"""Capture a bounded lazy-scenery probe to a new scratch folder, with source identity."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="new scratch directory")
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT"),
        metavar="PATH",
        help="Godot executable (required unless GODOT is set)",
    )
    args = parser.parse_args()
    if not args.godot:
        parser.error("--godot is required when GODOT is not set")
    repo = Path(__file__).resolve().parents[3]
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--"], cwd=repo, check=True, stdout=subprocess.DEVNULL)
    paths = [*sorted((repo / "src").rglob("*.gd")), *sorted((repo / "tests/probes").glob("lazy_scenery_*.gd")), repo / "project.godot", Path(__file__).resolve()]
    hashes = {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    args.output.mkdir(parents=True, exist_ok=False)
    command = [args.godot, "--headless", "--path", str(repo), "res://tests/tests.tscn", "--", "probes/lazy_scenery_measure.gd", "--no-save", "--seed", "4242"]
    started = time.time()
    with (args.output / "raw.log").open("w") as stream:
        process = subprocess.Popen(command, cwd=repo, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=90)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
            raise RuntimeError("probe exceeded external 90-second bound") from None
    raw = (args.output / "raw.log").read_text()
    if code or any(word in raw for word in ["ERROR:", "SCRIPT ERROR", "Parse Error", "WARNING:", "FAIL "]):
        raise RuntimeError("probe rejected; inspect raw.log")
    rows = []
    for line in raw.splitlines():
        if line.startswith("LAZY_"):
            kind, value = line.split(" ", 1)
            rows.append({"kind": kind, "value": json.loads(value)})
    counts = {kind: sum(row["kind"] == kind for row in rows) for kind in {row["kind"] for row in rows}}
    assert counts == {"LAZY_META": 1, "LAZY_ATLAS": 6, "LAZY_STAGE": 24, "LAZY_BOOT": 2, "LAZY_COVERAGE": 4, "LAZY_SUBSET": 8, "LAZY_REAL_BOOT": 1}, counts
    assert "14 checks, 0 failures" in raw
    assert hashes == {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    result = {"revision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip(), "started_unix": started, "elapsed_seconds": time.time() - started, "command": command, "hashes": hashes, "rows": rows}
    (args.output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"Accepted {len(rows)} rows; compact results exactly decoded from {args.output / 'raw.log'}")


if __name__ == "__main__":
    main()
