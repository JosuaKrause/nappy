"""Summarize retained native comparison records without pooling unlike runs."""

import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    report = []
    for path in sorted(args.directory.glob("*-summary.json")):
        data = json.loads(path.read_text())
        functions = data.get("functions", {})
        work = {}
        for title, fragment, suffix in [
            ("building_draw", "building.gd", "._draw"),
            ("event_owner_draw", "event_instance.gd", "._draw"),
            ("small_parts_draw", "scenery_layer.gd", "._draw"),
            ("atlas_region", "atlas_library.gd", ".region"),
        ]:
            matches = [value for key, value in functions.items()
                       if fragment in key and key.endswith(suffix)]
            assert len(matches) <= 1
            if matches:
                value = matches[0]
                work[title] = dict(value, calls_in_window=round(
                    value["calls"]["mean"] * data["frames"]))
            elif data["profiler_enabled"]:
                work[title] = {"calls_in_window": 0}
        report.append({"run": path.name.removesuffix("-summary.json"),
                       "accepted": data["accepted"], "frames": data["frames"],
                       "native_ms": data.get("native_ms"),
                       "callback_interval_ms": data["callback_interval_ms"],
                       "observer_ms": data["observer_ms"],
                       "population": data["population"], "work": work})
    (args.directory / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
    for row in report:
        wall = (row["native_ms"] or {}).get("frame_main_loop_wall")
        print(row["run"], wall or row["callback_interval_ms"])
        for name, value in row["work"].items():
            print(" ", name, "total", value["calls_in_window"], "calls", value.get("calls"),
                  "inclusive_ms", value.get("inclusive_ms"))


if __name__ == "__main__":
    main()
