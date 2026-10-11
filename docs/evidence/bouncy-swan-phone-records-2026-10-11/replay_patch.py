"""Makes `Stroller` replay a recorded position track in a scratch checkout. Never applied to the branch.

usage: replay_patch.py <checkout>

With `NAPPY_REPLAY=<track>` in the environment, her position follows the track's `seconds x y`
lines on the physics clock and her velocity is the step between two ticks, so every system that
reads where she is and where she is going sees the phone's walk. Without it she is unchanged.
"""
import sys

BLOCK1 = 'var _replay_t := PackedFloat64Array()\nvar _replay_p := PackedVector2Array()\nvar _replay_clock := 0.0\nvar _replay_i := 0\nvar _replay_loaded := false\n\nfunc _replay_target() -> Vector2:\n\tif not _replay_loaded:\n\t\t_replay_loaded = true\n\t\tvar path := OS.get_environment("NAPPY_REPLAY")\n\t\tif path != "":\n\t\t\tfor line in FileAccess.get_file_as_string(path).split("\\n"):\n\t\t\t\tvar f := line.split(" ")\n\t\t\t\tif f.size() >= 3:\n\t\t\t\t\t_replay_t.append(float(f[0]))\n\t\t\t\t\t_replay_p.append(Vector2(float(f[1]), float(f[2])))\n\t\t\tprint("REPLAY loaded ", _replay_t.size())\n\tif _replay_t.is_empty():\n\t\treturn Vector2.INF\n\twhile _replay_i + 1 < _replay_t.size() and _replay_t[_replay_i + 1] <= _replay_clock:\n\t\t_replay_i += 1\n\tif _replay_i + 1 >= _replay_t.size():\n\t\treturn _replay_p[_replay_p.size() - 1]\n\tvar a := _replay_t[_replay_i]\n\tvar b := _replay_t[_replay_i + 1]\n\tvar w := clampf((_replay_clock - a) / maxf(b - a, 0.0001), 0.0, 1.0)\n\treturn _replay_p[_replay_i].lerp(_replay_p[_replay_i + 1], w)\n\n'
BLOCK2 = '\tvar _rt := _replay_target()\n\tif _rt != Vector2.INF:\n\t\t_replay_clock += delta\n\t\tvar jump := _rt - global_position\n\t\tvelocity = jump / delta if jump.length() < 40.0 else Vector2.ZERO\n\t\tif velocity.length() > 0.5:\n\t\t\t_turn_toward(velocity.normalized(), delta)\n\t\tglobal_position = _rt\n\t\t_update_view()\n\t\t_advance_walk_phase(velocity.length() * delta)\n\t\t_update_camera(delta)\n\t\tqueue_redraw()\n\t\treturn\n'

path = sys.argv[1] + "/src/player/stroller.gd"
s = open(path).read()
anchor1 = "func _physics_process(delta: float) -> void:\n"
assert s.count(anchor1) == 1, "physics anchor"
s = s.replace(anchor1, BLOCK1 + anchor1 + BLOCK2)
open(path, "w").write(s)
assert open(path).read().count("_replay_target()") == 2
print("replay patched", path)
