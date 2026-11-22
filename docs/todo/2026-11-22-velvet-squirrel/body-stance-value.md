# How a body stands on its street is one value, derived once

**What is wrong today.**

- **The asker holds the stance.** `BodyStance` (`src/events/body_stance.gd`, model) is a class of statics, and two of them take the others' answers as arguments. `solid_axis_of(row, heading, spread_vertical, side_on)` and `pieces_laid_out(body, center, axis, vertical)` are handed what `lies_vertically_at()` and `stands_side_on()` answered.
- **The live body keeps two of the answers as its own state.** `EventBody` (the part of a live event that is its collision body) holds `_spread_vertical`, handed in by `EventInstance.setup()` and `move_to()`, and `_stationary_vehicle_side`, which it works out itself in `land_at()`. It passes both back in on every `solid_axis()` and `standing_pieces()`.
- **One body's pieces reach the live body by two paths.** `standing_pieces()` lays them out from the two answers it holds. `tiles_at()`, which a guard's line of sight asks (`EventInstance.clear_line_to()`), goes to a static of the spawner (`EventSpawner.obstructed_footprint()`), which asks `BodyStance.pieces_at()` and works the whole stance out again from the map. `EventBody`'s comment says the two "cannot disagree"; they agree because both are fed the same point and facing.
- **Two more askers lay the same pieces again.** The look's shadow (`EventLook._draw_body_shadow()`, with a cache of its own) and the physics footprint (`EventFootprints.solid_footprint_of(body, axis, spread_vertical)`) both work from answers fetched off the event.
- **The inputs are uneven.** Some statics take the row and others the row's body part (`BodySpec`). The kerb half of "where it stands" is a static of the plan that reads no plan (`EventPlan.stands_without_a_map(row, at)`).

This is the smell designing-classes names: a fact derived in more than one place, where one object should derive it once and be handed around.

**The design.** `BodyStance` becomes the value (the method names are my proposals).

- **`BodyStance.of(map, row, at, facing)`** derives once how a body of `row` built at `at` stands. It answers:
  - where its center stands (the kerb, the middle of its sidewalk band);
  - whether it lies down the screen;
  - whether a vehicle standing still shows its side;
  - the direction its spine lies along (the heading it is asked with for a car that drives, its street's for everything else);
  - its pieces where they stand (`StandingPiece`, as today).
- **`BodyStance.of_plan(map, plan)`** is the same for a planned body, in place of `planned_body_at()` and `pieces_at()`.
- **A stance is made from a build point, never from a stance**, so a point cannot be stood twice.
- **Two statics stay.** The lattice-only reading the plan's `body_at()` asks, since a plan holds no map; it moves here from `EventPlan.stands_without_a_map()`. And `lies_vertically_at(map, at)`, which is a question about a street that the dev rig also asks.

**Who builds it and hands it.**

- `EventInstance.setup()` derives one and hands it to `EventBody` (in place of `at`, `face` and `vertical`) and to its look.
- `move_to()` derives a new one and tells the body it landed.
- `EventBody`'s two fields go, and `tiles_at()` asks its stance's pieces, not the spawner.
- The look's shadow and `EventFootprints.solid_footprint_of()` take the stance's pieces; the shadow's own cache goes for a body that does not drive.
- The spawner's record of standing bodies, the walk's ground and the route rig ask `of()` or `of_plan()`. Each keeps its own filter (which rows it counts), as curly-stork left them.

**Order.** One pull request: the class, the live event and its body, the look and the footprint, the planned-side callers, the suites.

**What holds parity.** Nothing a player sees changes. These are identical on base and branch:

- `tests/probes/curly_stork_piece_layout.gd` (the pieces of every recorded body);
- `tests/probes/placement_rows.gd`;
- the `XF` lines of `tests/probes/excitement_fingerprint.gd`;
- the `LK` lines of `tests/probes/look_fingerprint.gd` (the shadows).

`tests/test_body_stance.gd` keeps its cases through `of()`.

**Cost.** Small to medium. About ten files under `src/`: `body_stance.gd`, `event_body.gd`, `event_instance.gd`, `event_footprints.gd`, `views/event_look.gd`, `event_spawner.gd`, `walk_ground.gd`, `plan_builder.gd`, `event_plan.gd`, and the two rigs under `src/dev/`. Also the suites that call the statics: `test_body_stance`, `test_events_catalogue`, `test_crowd_bodies`.

**What it collides with.**

- minty-newt, the events' looks are handed the drawn view: it rewrites the same look constructors, so one follows the other.
- Row 5's live-event and drawing suites: this lands before them, so they are written once.
