# minty-quail — Eight event and day suites use runs of their own (run state handed in: G4) · 2026-11-04

minty-quail's `run-state-handed-in.md`: `tests/test_destination_drawing.gd`, `test_dev_rig.gd`,
`test_pause.gd`, `test_day6_yeller_met.gd`, `test_burnt_door.gd`, `test_day7_van.gd`,
`test_event_parts.gd` and `test_day_controller.gd`. Tests only.

**Built.** Each suite hands a fresh `RunState` to what it tests: a city on a run of its own through
`RunCity.with_own_run()`, where a check depends on the run's seed on the seed the runner used to
reset the global to, named; an event world its own run and the manager one through `use_run()`; the
day's controller one through `DayController.setup()`; the pause and title screens one through
`use_run()`, and the summary models one each. The saved and restored fields are gone. The one check
about the global itself, that the pelican's bag drew none from the game's own run, goes with it, and
the scar test checks instead that its run starts with none; the burnt door suite resets its own
run's resistance before each front, since reading a mark completes a step of that run. Eight
mutation runs fail them.
