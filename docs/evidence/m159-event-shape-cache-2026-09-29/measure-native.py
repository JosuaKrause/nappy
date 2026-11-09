"""Run bounded, serial event-shape-cache comparisons with identical native collectors.

The runner is the shared `tools/lib_measure_native.py`; this experiment launches before-after by default.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools"))

import lib_measure_native  # noqa: E402

if __name__ == "__main__":
    lib_measure_native.main(__doc__.splitlines()[0], "./event-shape-output")
