# polite-tapir — The day's fills are one object, by view and kind of ground (placement step 3, the seam) · 2026-11-16

**The ask.** Placement step 3 of `placement-by-construction.md`: the density of the city's events becomes one declared
table (the player approved the design review's points, inbox #1268 in olive-ferret). This is the pull request #1473, the
first of two halves of the Fable design `placement-declared-table-design.md` (a brief, not in the repository), its section
12: the seam the table fills. It changes no day. The second half, #1488, is the record `polite-tapir-coral-owl`.

## What was built

- **`PlacementGround`** (`src/events/placement_ground.gd`, data): `PlacementGround.Kind { STREET, JUNCTION, ALLEY, OPEN }`,
  the four kinds of ground a unit is, moved out of `PlacementUnit.Kind`. It moves because a catalogue row (data) names a
  kind of ground in the second half, and data naming `PlacementUnit` (model) would break the layering, which CI fails. The
  31 uses (`day_units.gd`, `marble_draw.gd`, `unit_room.gd`, five suites and `tests/probes/walk_rows.gd`) are a typed rename,
  and `PlacementUnit.kind()` returns a `PlacementGround.Kind`. `PlacementUnit._KIND_NAMES` carries a comment: it follows the
  enum's order, and a unit's name enters its rank and stream seeds, so a member added or reordered moves every draw.
- **`UnitFills`** (`src/events/unit_fills.gd`, model): `UnitFills.of(view, ground)` answers the fill a unit draws from. Here it
  answers today's fill for the view, ignoring the ground: on the first ask it calls `EventScheduler.view_fills()` once and
  keeps the result for the day. The second half swaps in the declared table's body without touching a caller.
- **`UnitDraw`** takes a `UnitFills` as its third argument (it took a dictionary keyed by view) and asks
  `_fills.of(view, unit.kind())`; the bag's seed string is unchanged. `DawnDraw` builds the `UnitFills` where it called
  `view_fills()`. `tests/probes/walk_rows.gd` builds one the way `DawnDraw` does.
- `tools/layer_map.py` places `placement_ground.gd` under data and `unit_fills.gd` under model; `docs/ARCHITECTURE.md` lists
  both and says what is true at this head: `UnitFills` is asked by view and kind of ground and answers by the view whatever
  the ground.
- **Tests**: `tests/test_unit_draw.gd` hands `UnitDraw` a `_Fills` stand-in that extends `UnitFills`, answers a fill set by hand
  for each view and ground and records each ask; its new test draws a street and a junction box on the route from one-marble
  fills with different marbles and checks each draw takes its own ground's marble and each unit asks for its own view and
  ground. With `unit.kind()` in `_draw_alone()` replaced by `JUNCTION` or by `STREET`, 3 of 13 checks fail.

## Measured

No day changes: the `FP` lines of `tests/probes/placement_fingerprint.gd` are identical on main (`0296c814f`) and on the
branch, 15,217 lines each, with the same `shasum -a 256` over them; the run-log fixture is untouched and `observers` passes
against it. `walk_rows.gd` parses and runs with its `UnitFills` and printed `WC all 0 0` and `WS all 126 0 46 64` before its
local run hit the 900-second timeout; it is not compared with main, the fingerprint being the identity proof.

## Rejected, with the reason

- **A second enum with the same members** beside `PlacementUnit.Kind`: one fact in two places.
- **`PlacementGround.holds()`** (the design's 3.2, which tile types a kind of ground holds): nothing reads it until the
  second half, and code nothing reaches is not kept.
- **The second half's constructor**, `(rows, day, wall_share, weights, wall_by_cost)`, in this pull request: it would add
  parameters nothing reads. The seam's constructor is `(rows, day, spec)`, the arguments `view_fills()` takes. Open to overturn.
- **Computing the view fills in the constructor**: they are worked out on the first `of()`, as design 3.4 has it; `view_fills()`
  is pure, so the day is the same either way, which the fingerprint shows.
- **Typing `PlacementUnit.view()` by the enum**: the design gives this half only the rename in `placement_unit.gd`, so `view()`
  keeps its `int` return and `UnitDraw` casts it to `PlacementView.View` when it asks `of()`.
- **The design's section 8.1 and its sequencing lines** (the routes-first draw, not built, inbox #1460): ignored by the brief,
  and nothing here depends on them.

## Review

One review, three findings, all taken. Three lines said the fills differ by kind of ground, which they do not at this head (the
`docs/ARCHITECTURE.md` entries and `PlacementGround`'s class comment, fixed); the description's reason for leaving
`PlacementUnit.view()` an `int` was untrue as first written (it is scope, not that the file is outside the pull request); and
the preference for the `_KIND_NAMES` comment, taken. The delta review approved after a merge of main that was Git's own.

## What stays open

Nothing of this half: the declared table is `polite-tapir-coral-owl`.
