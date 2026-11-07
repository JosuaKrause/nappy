"""Run bounded, serial danger-prediction comparisons with identical native collectors.

The runner is the shared `tools/lib_measure_native.py`; this file names what is this experiment's own:
the two sources whose hashes the provenance records, and the alternating launch order.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools"))

import lib_measure_native  # noqa: E402

if __name__ == "__main__":
    lib_measure_native.main(
        __doc__.splitlines()[0],
        "./danger-prediction-output",
        default_order="alternating",
        sources=("src/events/event_instance.gd", "src/crowd/crowd_agent.gd"),
    )
