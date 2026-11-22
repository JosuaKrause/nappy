priority: later

# teal-rabbit — The corner-runtime probe never reaches covered or emerged · filed 2026-11-22

**Found** by the agent of pull request #1631 (minty-quail row 4b), in its parity run.

**What holds.** `tests/probes/m226_corner_runtime.tscn` is a scene, not a suite: `tools/test.sh probes/m226_corner_runtime.gd` fails with `Nonexistent function 'run'` (the runner calls `run()` on a suite; this is a `Node`). Run as a scene headless, it prints `CORNER_RESULT covered=false emerged=false` and exits 1 at 12 seconds. The probe reads the charging dog's drawing against the screen edge, so it needs a charging dog, a joystick control scheme and a walk toward the dog; its header says only that it is "driven only by existing dev flags" and names none. With `--invincible --controls joystick --force charging_dog 3 --walk 20s` the only `CORNER` line is at 0.337 s with the dog 2512 px away (relative `(2512.0, 1808.0)`) and she never moves, because `--walk` builds no rig on a run with no `--screenshot` or timed `--after`; `tools/run.sh` now refuses that command line before the game starts (the record snowy-hedgehog), so the probe's command needs a carrier.

**The command that shows it:**

    /Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/probes/m226_corner_runtime.tscn -- --no-save --no-title --seed 4242 --day 6 --day-length 40 --invincible --controls joystick --force charging_dog 3 --walk 20s
    # CORNER_RESULT covered=false emerged=false, exit 1

**What the fix must hold.** The header names the exact command that reaches both states; the run reaches `covered` and `emerged` on main, headless or with the window it needs, or the header says plainly that it only runs windowed; and the exit code is 0 when both hold.
