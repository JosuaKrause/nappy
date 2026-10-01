#!/usr/bin/env python3
"""Capture actual daily generated-route coverage; no preparation timings are rerun."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path, help="new scratch directory")
    parser.add_argument("--godot", default=os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"))
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[3]
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--"], cwd=repo, check=True, stdout=subprocess.DEVNULL)
    paths = [*sorted((repo / "src").rglob("*.gd")), repo / "tests/probes/lazy_scenery_routes.gd", repo / "project.godot", Path(__file__).resolve()]
    hashes = {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    args.output.mkdir(parents=True, exist_ok=False)
    rows = []
    commands = []
    for seed in (4242, 3265820891):
        for day in (1, 8, 12):
            command = [args.godot, "--headless", "--path", str(repo), "res://tests/tests.tscn", "--", "probes/lazy_scenery_routes.gd", "--no-save", "--seed", str(seed), "--day", str(day)]
            commands.append(command)
            log = args.output / f"seed-{seed}-day-{day}.log"
            with log.open("w") as stream:
                process = subprocess.Popen(command, cwd=repo, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    code = process.wait(timeout=60)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                    raise RuntimeError(f"probe exceeds 60-second bound: {log}") from None
            raw = log.read_text()
            if code or any(word in raw for word in ("ERROR:", "SCRIPT ERROR", "WARNING:", "FAIL ")):
                raise RuntimeError(f"probe rejected: {log}")
            found = [json.loads(line.split(" ", 1)[1]) for line in raw.splitlines() if line.startswith("LAZY_ROUTES ")]
            assert len(found) == 1 and "4 checks, 0 failures" in raw
            assert found[0]["seed"] == seed and found[0]["day"] == day
            rows.extend(found)
    assert hashes == {str(p.relative_to(repo)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    result = {"revision": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip(), "commands": commands, "hashes": hashes, "rows": rows}
    (args.output / "routes.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"Accepted six daily offered-route rows from {args.output}")


if __name__ == "__main__":
    main()
