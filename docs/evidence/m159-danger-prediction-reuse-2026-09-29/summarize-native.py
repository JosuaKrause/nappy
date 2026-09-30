"""Summarize retained danger-prediction comparisons without pooling unlike runs."""

import argparse
import json
from pathlib import Path


def _function(functions, suffix):
    matches = [value for key, value in functions.items() if key.endswith(suffix)]
    assert len(matches) <= 1, suffix
    return matches[0] if matches else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    args = parser.parse_args()
    report = []
    for path in sorted(args.directory.glob("*-summary.json")):
        data = json.loads(path.read_text())
        functions = data.get("functions", {})
        report.append({
            "run": path.name.removesuffix("-summary.json"),
            "accepted": data["accepted"],
            "rejections": data["rejections"],
            "frames": data["frames"],
            "profiler_enabled": data["profiler_enabled"],
            "acceptance": {
                "profile_frames": data["profile_frames"],
                "missing_profile_frames": data["missing_profile_frames"],
                "physics_alignment_mismatches": data["physics_alignment_mismatches"],
                "north_input_held": data["north_input_held"],
                "draws_per_process_frame": data["draws_per_process_frame"],
                "moving_cars_per_frame": data["moving_cars_per_frame"],
                "ticks_per_frame": data["ticks_per_frame"],
                "unique_function_signatures": data["unique_function_signatures"],
                "emitted_functions_per_frame": data.get("emitted_functions_per_frame"),
            },
            "diagnostics": {
                "compiler_warnings": data["compiler_warnings"],
                "runtime_debugger_errors": len(data["errors"]),
            },
            "environment": data["environment"],
            "player_path_pixels": data["player_path_pixels"],
            "northward_net_pixels": data["northward_net_pixels"],
            "population": data["population"],
            "native_ms": data.get("native_ms"),
            "callback_interval_ms": data["callback_interval_ms"],
            "observer_ms": data["observer_ms"],
            "work": {
                name: _function(functions, name)
                for name in [
                    "EventInstance.expected_gross_at", "EventInstance._sample_expected_landed",
                    "EventInstance.contribution_at", "EventInstance._process",
                    "CrowdAgent.expected_gross_at", "CrowdAgent._sample_expected_landed",
                    "CrowdAgent.contribution_at", "CrowdAgent._process",
                    "ExcitementHalo._process",
                ]
            } if data["profiler_enabled"] else {},
        })
    (args.directory / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
    for row in report:
        wall = (row["native_ms"] or {}).get("frame_main_loop_wall")
        print(row["run"], wall or row["callback_interval_ms"])
        for name, value in row["work"].items():
            print(" ", name, value)


if __name__ == "__main__":
    main()

