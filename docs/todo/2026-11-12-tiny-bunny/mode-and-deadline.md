# The ground-frames probe runs in the mode `--ground-mode` names, and a full run fits its deadline

**The mode it names is not the mode it measures.** The probe's header says its coverage runs in the
ground mode `--ground-mode` names, defaulting to 2. The mode decides how the ground lays a region
the camera is about to need: 1 lays every needed region in one frame, 2 at most one whole region a
frame, 3 spreads one region over frames. The probe builds its city through
`tests/fixtures/run_city.gd` (`RunCity.with_own_run()`), and that never hands the city a mode. Only
the game's boot does that (`main.gd` copies `RunConfig.ground_mode` into `City.ground_mode`, which
`City` hands to `SceneryGround.use_mode()`). So the city keeps its default, `SceneryGround.Mode.ONE`
(mode 2), whatever the command line says, and the mode-3 check (it fails when stepping never spans
frames) never runs. A fix hands the probe's city the mode from `DevFlags.ground_mode()` before the
city builds. The probe would then need a run in each mode to cover what its header promises.

**A full run does not finish inside its own deadline.** The probe stops itself after two minutes
(`ground_frames exceeded its two-minute deadline`). One full run, by the orchestrating session before the
one that filed this, hit that stop. It was not run again to see whether the machine's load played a part.
A fix either cuts the work (fewer warm-up passes, fewer comparison modes per run, or a shorter
itinerary than its `rate * 30` frames a leg) or gives the deadline the time a full run measures.

**Deleting it instead** loses the one check of the ground's residency against real process frames
outside `tests/test_scenery_residency.gd`. That suite hands each mode in itself
(`scene.ground.use_mode()`), but it ticks in steps rather than in engine frames.
