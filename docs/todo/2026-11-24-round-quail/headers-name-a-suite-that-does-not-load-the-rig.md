# The basement walk rig's headers name a suite that does not load it

`tests/basement_walk_rig.gd` says in its header that `tests/test_interior.gd` shares the rig, and the header of `tests/probes/basement_meter.gd` says that `tests/test_interior.gd` "pins what this prints". `test_interior.gd` never preloads or calls the rig: the only file that loads it is the probe, and the only thing `test_interior.gd` shares with the walk is the corridor, `scene.map().basement_walk()`. So nothing asserts what the rig measures, and two headers say something does.

**How it shows:** `grep -rn basement_walk_rig tests` lists the probe and the rig's own header and no suite.

**What would fix it:** either `test_interior.gd` (or a suite of its own named for the basement's cost) loads the rig and pins the numbers the probe prints, or both headers say the rig is the probe's alone and that no suite holds its numbers. A builder picks by whether the basement's cost is a number worth holding (**writing-tests**: what a test holds). The header of `tests/building_events.gd` lists the rig as a sharer of that file, which is true and stays.
