# minty-quail — The scene recipe stretch, runtime and lifecycle suites drive public seams, and the dead door clause goes (tests through public seams: W13) · 2026-11-04

minty-quail's `tests-public-seams.md`: the scene recipe stretch, runtime and lifecycle suites and
the lifecycle helper `tests/scene_recipe_lifecycle.gd`, and the clause in
`SceneRecipeRuntime._mast_placement()` that kept a mast clear of the doors.

**Built.** The stretch suite (private-read lines 13 to 0) reads the red arrow's ground through
`WalkField.ground_for()` and the draft through `record()` and `compose()`, checking the junction
box at both ends of the street where the old check read one; its checks that an observation needs
sight run a scripted scene in a child game, since an unmet observation ends the game and would end
the runner, which costs the suite some seconds. The runtime suite (9 to 0) hands a real director to
`install()` as `DayDirector` does and lets a task expire or be refused on the runtime's own physics
ticks, and its probe asks `GameSave.uses_save()`. The lifecycle helper (9 to 0) boots `main` in the
runner through `tests/booted_main.gd` on a fresh `RunState`, counts reloads through
`main.use_reload()` and lets real physics ticks pass; the stretch-edge check walks to the void's
edge, where the old one pressed toward it for a fixed time and passed with the wall removed. Each
fact is a check of its own, so the lifecycle suites count more checks and run faster. The baby's
meters are no longer compared between a free and a scripted boot, since they move with the ticks a
boot lets pass before a suite can read them; `manifest.initial_actors` is compared instead.

The door clause had no reachable case: the runtime stands only street doors, and
`RegionPlanner.stand_door()` and `MastSites.possible_door_points()` place them by the same
expression, so `MastSites.is_eligible()` refuses that ground first (a probe found every one of 354
door bodies on a door point, over seven cities on days 9 and 13). It goes, with its `doors`
parameter; a new stretch check states that every street door a day plans stands on a point
`MastSites` reads. About twenty mutation runs.

**Not done, and what each wants:** the director's own use of the arrow ground, which wants a task
scene of several targets on a stretch; the sight check run in the runner, which would want the
runtime handed what it ends the game with, a door no other game class would use; the bounded
scene's check that no event body stands outside the authored ground, vacuous on today's recipes as
it was before, which wants a bounded recipe that names a gate. A lifecycle scene that fails to
stand now quits the whole runner rather than one child game.
