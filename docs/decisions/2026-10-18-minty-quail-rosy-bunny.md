# minty-quail — Five checks no test held, outside the events, become tests · 2026-11-19

minty-quail's `tests-public-seams.md` (its open gaps) and the records of the day's underscore passes
(`2026-10-18-minty-quail-gray-gecko`, `2026-10-18-minty-quail-golden-toad`): five behaviours outside
the events and the resistance that deleting failed nothing. Each gets a check that fails when the
behaviour is removed and passes on the code as it is, through public seams and real frames. Tests
only; no behaviour changed.

**Built.**

- **The scenery round where she is put down** (`tests/test_day_director.gd`). A start, on a day and on
  an authored scene's day, asks the city's dressing to prepare its scenery once
  (`CityDressing.prepare_scenery_in()`), over the world her camera shows round where she stands, after
  she is put down and before the clock runs. The fake her stands in the tree with a real, current
  `Camera2D` at the scene's zoom, off physics interpolation, since the fake `reset_at()` does not reset
  it as `Stroller.reset_at()` does; the fake dressing records each view. `test_camera_start.gd`'s dawn
  check stays as it is: it holds the real boot's order, and this check holds the director's ask.
- **`DaySummary`'s `_continuing` guard** (`tests/test_pause.gd`, which already drives the summary's tap
  continue). A second tap landing while the first tap's two-frame acknowledgement is open continues
  the summary once.
- **The won day's unmet fire** (`tests/test_day_director.gd`). A won walk home asks the events to light
  what she never met (`EventManager.light_what_she_never_met()`), at her position; a lost day and the
  escape's city section won ask nothing. The fake events record the ask.
- **The screen-edge badge coming down once she sees its thing** (new suite `tests/test_danger_edge.gd`).
  `DangerEdge` alone, handed a stand-in event source (`instances()`, `visible_view()`) and one
  stand-in live convoy moved by hand between real frames, the edge hidden so it draws nothing. A badge
  raised out past the margin stays up every frame its thing is out of sight and is down on the first
  frame any of it shows; and a convoy closing from inside the badge's margin, out of sight throughout,
  is raised no badge.
- **A recycled walker's heading** (new suite `tests/test_lane_mover.gd`). One seeded walker on a
  hand-laid nine by nine lattice (`StreetLayout.lay()`), in a crowd field of its own, recycled forty
  times through its lane's own event (`Lane.be_recycled()`): it comes in both ways along both axes, and
  each time from behind the field's edge it walks in through.

**Mutations run**, each reverted and never committed:

- Removing `_prepare_the_scenery_round_her()` after she is put down fails the day's case; removing it
  after a scene installs fails the scene's.
- Removing the early return of `_continuing` in `_acknowledge_and_continue()` fails the double tap
  (two continues).
- Removing the call to light the unmet fire fails the won walk home; dropping its won term fails the
  lost day; dropping its goal term fails the city section.
- Making `DangerEdge._shows()` always false fails the badge coming down. Making `_sees()` always false,
  or dropping its margin, fails the margin check.
- Removing the recycle's lane re-roll (`_choose_lane()` in `LaneMover._recycle()`) fails the walker's
  headings (one heading), and `test_recipe_composition.gd` still passes it; a walker whose direction is
  never rolled fails them too (two headings); a recycle placed at the edge it walks out through fails
  the entry side.

**What the golden-toad record's mutation does.** Making `_sees()` always false does not keep a badge up
after she sees its thing: `_shows()` also asks whether any of the drawn box is in sight, and a row's
box holds its feet, so the box path takes the badge down. What the mutation changes is the raising: a
thing inside the margin is raised a badge. The margin check holds that; the masked-man badge suite
still passes the mutation.

**Not done: the won day's city term.** The fire is asked only on a walk home, and the only world with no
city is the escape's building (`DaySpec.World.BUILDING`), whose goal is the service exit, so no game
path reaches a won walk home outside a city. The term (`_in_a_city` in `DayDirector.finish_day()`)
guards nothing the game reaches, and a check of it would stand on a setup the game cannot reach
(**writing-tests**). Deleting the term is a change under `src/`, outside a tests-only pass, and goes
with `test_day_director.gd`'s won day with a player and no city, which stands on the same unreachable
world.

**Remeasure:** nothing; no behaviour changed.
