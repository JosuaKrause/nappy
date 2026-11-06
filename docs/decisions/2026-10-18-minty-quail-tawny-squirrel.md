# minty-quail — The city, building and scenery suites stop calling functions only tests call (tests through public seams) · 2026-11-05



minty-quail's `tests-unseen-reads.md`, the city, building and scenery build, under the player's
rule that a public member only tests call is deleted where possible, the tests going through a
fake or what the game shows (curly-rabbit #1095), and `tests-hold-nothing.md`'s findings in the
same suites.

**Built.**
- Deleted from `src/`: `City.close_ground()`, which nothing in the game called, with the two
  helpers only it used (`CityMap.repaint_tile()`, `SceneryGround.set_cell()`); and
  `SceneryGround.has_water()`, whose suites now ask a test fixture (`tests/fixtures/ground_water.gd`)
  that reads the resident chunk's water cells.
- `test_scenery_residency.gd` no longer edits the ground before following the view; its two cancel
  checks call `SceneryGround.cancel()`, which the residency itself calls.
- `test_blackout.gd` writes no crowd focus and no signal state: the spine-traffic check stands a
  stroller on the sidewalk beside the spine and lets forty seconds of real physics ticks pass, the
  signals' clock is advanced through `TrafficSignals.advance()`, and the lights go out through the
  sabotage flag and the blackout's own update.
- The audit's findings in `test_blackout.gd` (the dark spine's horn check, a duplicate of the crowd
  rig's fairness check, and a luminance band), `test_ground_floor.gd` (two loops reading the
  extension table back), `test_main.gd` (the 500 ms constant read back) and
  `test_scenery_animation.gd` (a rotor pixel) held and went. Each suite's count moved by exactly
  those checks, apart from the residency suite's two per-tile checks of the ground the removed edit
  had spoiled.

**Kept.** `City.home_door_is_sealed()`, read by a resistance suite outside this build. The run's
sabotage flag and a hand-built building's day, condition and power, written as fixture state the
game writes too. `Crowd.set_focus()` and `step()`, which the crowd build's suites still use.

**Open to overturn:** the shared water fixture in place of a public query on the ground; the
stroller on the sidewalk rather than the carriageway, where cars would stop for her or strike her;
the two helpers deleted with `close_ground()`.
