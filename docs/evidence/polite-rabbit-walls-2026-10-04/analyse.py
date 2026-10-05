"""Summarise native frame records: the influence sweep per physics step, the cue pass per frame.

Usage: python3 analyse.py RECORD.json [RECORD.json ...]

Prints one JSON line per record. The first WARM_STEPS physics steps are left out, so the boot
and the first streaming of the day are not in the window.
"""

import json
import statistics
import sys

WARM_STEPS = 150


def summarise(path):
    with open(path) as handle:
        record = json.load(handle)
    index = {name: i for i, name in enumerate(record["columns"])}
    steps = 0
    influence = 0
    counted_steps = 0
    cues = []
    for row in record["rows"]:
        steps += row[index["physics_steps"]]
        if steps < WARM_STEPS:
            continue
        cues.append(row[index["cues_usec"]])
        influence += row[index["influence_usec"]]
        counted_steps += row[index["physics_steps"]]
    cues.sort()
    return {
        "frames": len(cues),
        "influence_usec_per_step": influence / max(1, counted_steps),
        "cues_mean_usec": statistics.mean(cues),
        "cues_p95_usec": cues[int(len(cues) * 0.95)],
    }


def main(paths):
    if not paths or paths[0] in ("-h", "--help"):
        print(__doc__)
        return 0 if paths else 2
    for path in paths:
        print(json.dumps({"record": path.rsplit("/", 1)[-1], **summarise(path)}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
