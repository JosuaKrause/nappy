# minty-quail — The city is handed its settings, and city.gd is typed (city scene pass, C2) · 2026-11-24

minty-quail's city scene pass (lane C of the finish plan), pull request C2. `main._new_city()`
wrote eight fields of the city; it hands them through `equip(trace, atlas, timing)`,
`use_ground_recipe()`, `use_run()`, `schedule_scenery(mode, frame_locked)` and `leave_out(shadows)`, so
`main` equips the city and its builder alike. The ground mode, frame lock, shadow skip, timing, recipe and
the lights (`City.signals`) are private. The residency takes the frame lock through `lock_to_frames()`, the
still watch its trace through `use_trace()` and the touch controls their rotation through `use_rotated()`.
`city.gd` loses its opt-out line: two declarations are typed (the blocks loop and the boundary walls), and
`tools/check.sh` boots clean with nothing else typed.

**Where the tree differed from the design.** `City.run`, `trace` and `atlas` stay public vars written
only by `equip()` and `use_run()`, as the design says until C7, but the scene recipe runtime no longer
reads them (D1 stopped that), so the only readers left are tests, and `check_test_only_members.py` fails
them. They take three `[kept]` lines as deferrals, ending when the suites hold their own run, trace and
library (C6a, C6b). Typing `city.gd` also unmasked two members the check had counted as read through an untyped `.clear()`
in `city.gd`: `SceneryGround.clear`, read only by measuring probes and one residency suite, which takes a
`[kept]` line listing every reader, and `EventManager.clear`, which becomes `_clear`: its suite and probe callers
call `stand_down()`, the public end of a walk (`test_masts.gd` starts its masts through `start_recipe()` with a
focus far off the map instead). `City.build()` no longer makes a library when none was handed: it asserts that
`equip()` came first, which a suite cannot catch (an assert stops the run), so no check holds it.

**The frame lock's check.** The design breaks `immediate = immediate or _frame_locked` in `update()`; a check
after one update does not fail on that, since an update's first call prepares what it shows whether or not
the residency is locked (`relocated`), and the lock's other uses in the same update carry the rest. The check
reads a second update that moves the view under the relocation distance so one ground region enters the load
view past the guard: dropping the city's `lock_to_frames()` call fails it (a locked residency prepares the
region in that call, an unlocked one queues it).

**The touch controls' rotation has no check on `main`'s wiring.** A press at the pause button's presented
position in `test_camera_start.gd`'s portrait boot gives the same answer with `main`'s `use_rotated()` call
removed, because the press does not reach the controls in a boot with no walk; no suite reaches the wiring
cheaply, and the controls' own handling of the rotation is `test_orientation.gd`'s.

**Check counts.** `test_still_watch.gd` 29 to 30 (the watch's own check, that it writes its line into the
trace it was handed); `test_run_config.gd` 84 to 85 (the city's ground and shadows, and the residency's lock,
are two checks where one read the lock off the residency's field); every other touched suite is the same on
main and on the branch.
