# minty-quail — Three of the rules no suite held get checks, and the checkpoint suite's scratch file is its own · 2026-11-06

minty-quail's `tests-coverage-gaps.md`, the orchestrator's proposal from the reviews of the
underscore pass: a rule the player meets that no suite checks gets a check (curly-rabbit #1097,
read the other way). And `tests-isolated.md`'s scratch-path paragraph.

**Built**, tests only, each check shown to fail on a mutation of the rule and pass on the game:

- **A fixed-site mast's scar** (`tests/test_masts.gd`): a fixed-site mast silenced on day 5 through
  the manager and `RunState.add_scar()`; day 6 on the same city shows that site silenced while the
  other sites still speak. `_was_silenced()` made always false fails it.
- **The park's obstruction** (`tests/test_park_cordon.gd`): closures wall the longest taped side of
  the swing's park off from home before the director reads the day's obstruction; she stands
  beside that side and the cordon is played through the director, and the last stretch taped is
  away from her (94px on the game, 66px with the director handing `take_the_park({})`, against a
  2.5-tile, 80px, threshold).
- **The market boarded in her sight** (`tests/test_resistance_placement_kinds.gd`): she stands in
  front of each of the first two candidate blocks while the happenings run past `MARKET_GONE_BY`,
  and that block stays commercial; removing both out-of-sight distance guards fails it once per
  candidate.
- **The checkpoint suite's scratch file** (`tests/test_run_checkpoints.gd`) takes the process id,
  `user://test_run_checkpoints_scratch_<pid>.json`, as `tests/scene_recipe_lifecycle.gd`'s does, so
  two runs at once on one machine no longer share it.

**Not built: which calm ground is spoiled.** A day where `EventScheduler._is_spoiled()` changes
which calm ground the walkability repair keeps a route to is rare: with it mutated to answer "not
spoiled", eight `build_day` cases (about 2.7 s each under load) showed no difference, and a larger
sweep was cut off. The check needs a (seed, day, target) found by an offline search first; it needs
no `src/` change. `tests/spoiled_ground.gd` holds a copy of the rule on purpose, so the other suites
do not hold the choice either.

Added time: about a second each for the mast and market checks; the park check adds one fixture
and a cordon play, roughly 10 s on a loaded machine.
