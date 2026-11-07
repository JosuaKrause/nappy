"""Compare desktop frame records (`--frame-record`) before and after over one game-time window.

Each record is the JSON a desktop run writes on scene exit (its path is the run's "Frame record:"
line). The window is counted in physics ticks from the first kept frame, so two runs of one seed
and one --walk are compared over the same stretch of play however fast each drew. Prints, per
record and pooled per side, the frames in the window and the median and mean of the draw calls,
the primitives, the `draw`, `render` and whole-frame times, and the crowd agents alive.

  python3 compare-frame-records.py --before b1.json b2.json --after a1.json a2.json
  python3 compare-frame-records.py --from-tick 150 --to-tick 750 --before b.json --after a.json
"""

import argparse
import json
import statistics
import sys

COLUMNS = ["draw_calls", "primitives", "draw_usec", "render_usec", "frame_usec", "crowd_agents"]


def _table(report):
    """The ledger dictionary inside a record: the one holding `columns` and `rows`."""
    stack = [report]
    while stack:
        node = stack.pop()
        if isinstance(node, dict):
            if "columns" in node and "rows" in node:
                return node
            stack.extend(node.values())
    raise SystemExit("no frame table (columns and rows) in the record")


def _window(path, from_tick, to_tick):
    with open(path, encoding="utf-8") as handle:
        table = _table(json.load(handle))
    columns = table["columns"]
    for name in COLUMNS + ["physics_steps"]:
        if name not in columns:
            raise SystemExit(f"{path}: no column {name}")
    index = {name: columns.index(name) for name in COLUMNS + ["physics_steps"]}
    ticks = 0
    kept = []
    for row in table["rows"]:
        ticks += row[index["physics_steps"]]
        if from_tick <= ticks < to_tick:
            kept.append([row[index[name]] for name in COLUMNS])
    return kept


def _line(label, rows):
    if not rows:
        return f"{label:<28} no frames in the window"
    parts = [f"{label:<28} {len(rows):5d} frames"]
    for i, name in enumerate(COLUMNS):
        values = [row[i] for row in rows]
        parts.append(f"{name} {statistics.median(values):.0f}/{statistics.fmean(values):.1f}")
    return "  ".join(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--before", nargs="+", required=True, help="the baseline's frame records")
    parser.add_argument("--after", nargs="+", required=True, help="the change's frame records")
    parser.add_argument("--from-tick", type=int, default=150, help="window start, physics ticks (default 150)")
    parser.add_argument("--to-tick", type=int, default=750, help="window end, physics ticks (default 750)")
    args = parser.parse_args()
    if args.to_tick <= args.from_tick:
        parser.error("--to-tick must be after --from-tick")
    print(f"window: ticks {args.from_tick} to {args.to_tick}; each column median/mean")
    for side, paths in (("before", args.before), ("after", args.after)):
        pooled = []
        for path in paths:
            rows = _window(path, args.from_tick, args.to_tick)
            pooled.extend(rows)
            print(_line(f"{side} {path.rsplit('/', 1)[-1][:20]}", rows))
        print(_line(f"{side} pooled", pooled))
    return 0


if __name__ == "__main__":
    sys.exit(main())
