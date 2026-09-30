"""Instrument a disposable baseline checkout to count equivalent gross sampling requests.

The source still evaluates every sample. This is a demand audit, never a timing comparison.
Run the existing entity_frame_profile collector afterward; its scene output carries the counts.
"""

import argparse
from pathlib import Path


EVENT_KEY = """[global_position, player_position, player_velocity, velocity,
\t\tlive_intensity, def.intensity, def.inner_radius, def.outer_radius,
\t\tdef.falloff_power, def.core_intensity, def.core_radius, _solid_axis(),
\t\tdef.shape.kind if def.shape else -1,
\t\tdef.shape.half_length if def.shape else 0.0,
\t\tdef.shape.half_extents if def.shape else Vector2.ZERO]"""
CROWD_KEY = """[global_position, player_position, player_velocity, vel, kind,
\t\t_jolt, _jolt_for, _jolt_intensity, _jolt_inner, _jolt_outer]"""


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
    args = parser.parse_args()
    instrument(args.checkout)


if __name__ == "__main__":
    main()
