"""Summarise one scratch-instrumentation run: each counter's mean per frame, and per-call costs.

    python3 scratch-summary.py <m159_scratch.json>
"""

import json
import statistics
import sys
from pathlib import Path


def main():
    with Path(sys.argv[1]).open() as handle:
        rows = json.load(handle)
    # Only the frames the day was running: the crowd or the events reported in them.
    rows = [r for r in rows if r.get("crowd_n", 0) > 0 or r.get("ev_n_in", 0) + r.get("ev_n_off", 0) > 0]
    n = len(rows)
    keys = sorted({k for r in rows for k in r if k != "frame"})
    print(f"frames {n}")
    for k in keys:
        vals = [r.get(k, 0.0) for r in rows]
        print(f"{k:34s} mean/frame {sum(vals) / n:10.2f}  p50 {statistics.median(vals):8.1f}  max {max(vals):8.0f}")

    def ratio(a, b):
        top = sum(r.get(a, 0) for r in rows)
        bottom = sum(r.get(b, 0) for r in rows)
        return top / bottom if bottom else float("nan")

    print("crowd draw us/call", ratio("crowd_draw_us", "crowd_draw_n"))
    print("event draw us/call", ratio("ev_draw_us", "ev_draw_n"))
    print("event key us/call in", ratio("ev_key_us_in", "ev_n_in"), "off", ratio("ev_key_us_off", "ev_n_off"))
    print("event caret us/computation", ratio("ev_caret_us", "ev_caret_n"))
    print("crowd caret us/call in", ratio("crowd_caret_us_in", "crowd_caret_n_in"),
          "off", ratio("crowd_caret_us_off", "crowd_caret_n_off"))


if __name__ == "__main__":
    main()
