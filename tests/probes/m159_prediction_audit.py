"""Instrument a disposable baseline checkout to count equivalent gross sampling requests.

The source still evaluates every sample. This is a demand audit, never a timing comparison.
Run the existing entity_frame_profile collector afterward; its scene output carries the counts.
"""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess


EVENT_KEY = """[global_position, player_position, player_velocity, velocity,
\t\tlive_intensity, def.intensity, def.inner_radius, def.outer_radius,
\t\tdef.falloff_power, def.core_intensity, def.core_radius, _solid_axis(),
\t\tdef.shape.kind if def.shape else -1,
\t\tdef.shape.half_length if def.shape else 0.0,
\t\tdef.shape.half_extents if def.shape else Vector2.ZERO]"""
CROWD_KEY = """[global_position, player_position, player_velocity, vel, kind,
\t\t_jolt, _jolt_for, _jolt_intensity, _jolt_inner, _jolt_outer]"""


def git_output(parser, root, *args):
    try:
        return subprocess.check_output(["git", *args], cwd=root, text=True).strip()
    except (OSError, subprocess.CalledProcessError) as error:
        parser.error(f"cannot inspect project checkout {root}: {error}")


def validate_instrument_checkout(parser, checkout):
    if not checkout.is_dir():
        parser.error(f"checkout is not a directory: {checkout}")
    required = ["src/events/event_instance.gd", "src/crowd/crowd_agent.gd",
                "tests/probes/entity_frame_profile_observer.gd"]
    missing = [relative for relative in required if not (checkout / relative).is_file()]
    if missing:
        parser.error(f"checkout {checkout} is missing: {', '.join(missing)}")
    script_root = Path(__file__).resolve().parents[2]
    checkout_root = Path(git_output(parser, checkout, "rev-parse", "--show-toplevel")).resolve()
    if checkout_root == script_root:
        parser.error("refusing to instrument the repository that contains this audit script")
    if git_output(parser, checkout, "status", "--porcelain", "--untracked-files=no"):
        parser.error(f"checkout has dirty tracked files: {checkout_root}")


def replace_once(path, before, after):
    text = path.read_text()
    assert text.count(before) == 1, (path, before)
    updated = text.replace(before, after)
    path.write_text(updated)
    assert path.read_text() == updated


def instrument(root):
    for relative, key in [("events/event_instance.gd", EVENT_KEY),
                          ("crowd/crowd_agent.gd", CROWD_KEY)]:
        path = root / "src" / relative
        declarations = """static var prediction_audit: Dictionary = {}
var _audit_key: Array = []
var _audit_frame := -1

func _audit_prediction(key: Array) -> void:
\tvar frame := Engine.get_process_frames()
\tvar counts: Array = prediction_audit[frame]
\tcounts[1] += 1
\tif key == _audit_key:
\t\tcounts[2] += 1
\t\tif frame == _audit_frame:
\t\t\tcounts[3] += 1
\t_audit_key = key
\t_audit_frame = frame

"""
        anchor = "func expected_gross_at(player_position: Vector2) -> float:\n"
        replace_once(path, anchor, declarations + anchor + """\tvar audit_frame := Engine.get_process_frames()
\tif not prediction_audit.has(audit_frame):
\t\tprediction_audit[audit_frame] = [0, 0, 0, 0]
\tprediction_audit[audit_frame][0] += 1
""")
        if relative.startswith("events"):
            anchor = "\tvar live_intensity := _caret_intensity_over_horizon()\n"
            addition = "\tif _flock.is_empty():\n\t\t_audit_prediction(" + key + ")\n"
        else:
            anchor = "\tvar current_rate := contribution_at(player_position)\n"
            addition = "\t_audit_prediction(" + key + ")\n"
        replace_once(path, anchor, anchor + addition)
    observer = root / "tests/probes/entity_frame_profile_observer.gd"
    anchor = '\tmetadata["rows"] = rows\n'
    replace_once(observer, anchor, anchor + """\tmetadata["prediction_audit"] = {
\t\t"columns": ["requests", "sampled_nonflock", "identical_previous", "identical_same_frame"],
\t\t"event": EventInstance.prediction_audit, "crowd": CrowdAgent.prediction_audit}
""")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("--summarize", type=Path, help="Capture prefix to compact instead of instrumenting")
    parser.add_argument("--output", type=Path, help="New compact JSON file, with --summarize")
    args = parser.parse_args()
    args.checkout = args.checkout.resolve()
    if bool(args.summarize) != bool(args.output):
        parser.error("--summarize and --output are required together")
    if not args.summarize:
        validate_instrument_checkout(parser, args.checkout)
        instrument(args.checkout)
        return
    args.summarize = args.summarize.resolve()
    args.output = args.output.resolve()
    if args.output.exists():
        parser.error(f"output path already exists: {args.output}")
    if not args.output.parent.is_dir():
        parser.error(f"output parent is not a directory: {args.output.parent}")
    for suffix in ["-scene.json", "-summary.json"]:
        if not Path(str(args.summarize) + suffix).is_file():
            parser.error(f"missing capture input: {args.summarize}{suffix}")
    scene = json.loads(Path(str(args.summarize) + "-scene.json").read_text())
    summary = json.loads(Path(str(args.summarize) + "-summary.json").read_text())
    frames = {str(row[0]) for row in scene["rows"] if 5000000 <= row[4] < 11000000}
    result = {key: summary[key] for key in [
        "accepted", "rejections", "frames", "population", "player_path_pixels",
        "northward_net_pixels", "north_input_held", "draws_per_process_frame",
        "moving_cars_per_frame", "ticks_per_frame", "compiler_warnings", "errors"]}
    result["environment"] = {key: value for key, value in summary["environment"].items()
                             if key != "prediction_audit"}
    result["baseline"] = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=args.checkout, text=True).strip()
    result["columns"] = scene["prediction_audit"]["columns"]
    result["counts"] = {
        kind: [sum(value[index] for frame, value in scene["prediction_audit"][kind].items()
                   if frame in frames) for index in range(4)] for kind in ["event", "crowd"]}
    result["instrumented_sha256"] = {
        relative: hashlib.sha256((args.checkout / relative).read_bytes()).hexdigest()
        for relative in ["src/events/event_instance.gd", "src/crowd/crowd_agent.gd",
                         "tests/probes/entity_frame_profile_observer.gd"]}
    result["sampling_dt_seconds"] = 0.25
    result["samples_per_integral"] = 20
    result["timing_use"] = "None: instrumentation measures demand only and skips no sampling."
    with args.output.open("x") as output:
        output.write(json.dumps(result, indent=2) + "\n")
    assert json.loads(args.output.read_text()) == result


if __name__ == "__main__":
    main()
