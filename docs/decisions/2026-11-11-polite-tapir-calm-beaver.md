# polite-tapir — Which tiles a row may stand on is RowGround, one object a walk derives once and hands around · 2026-11-12


**The ask.** The event scheduler is broken up into pieces of their own (`scheduler-breakup.md`, the design review's
breakup, which the player approved, inbox #1268 in olive-ferret); this piece answers which tiles a row may stand on.
A fact derived from stored data lives in one object that derives it once and is handed around (inbox #1156 in
gray-dolphin), and the ground was derived at dawn and again by every walk siting.

## What was built

- **`RowGround`** (`src/events/row_ground.gd`, the model layer): handed the map, the corridor, the home-street rule,
  five weights and a function that says whether a wall is one by cost; it names no scheduler. It scans the map once
  per question a row asks and keeps the answer for the walk: `tiles_for()`, `offers_for()` and `offers_for_role()`.
  `EventScheduler.row_ground()` makes it once a day at dawn.
- **It travels as the day's locations do**: every dawn pass, then the walk (`DayEvents`, `DayPlanner.Plan`,
  `WalkEvents.ground()`); `EventsAhead` hands it to every `WalkSiting`, and the resistance director's day-8 fronts ask
  it. For a walk no dawn planned (a scene recipe's, a rig's), `EventsAhead` makes one under the walk's own rule
  and the resistance director one under the day's.
- **Eight functions left the scheduler**: `open_ground_for()`, `ground_for()`, `_copies_of()`, `_wants_this_side()`,
  `_is_a_corner()`, `_burns_its_front()`, `_street_tree_tiles()` and `_open_ground_counts()`.
- **Nothing a day places changed**: the placement fingerprints (`FP`, `DP`, `ESCAPE_SPACING`, `TA`) are identical to
  the base's, and `tools/test.sh observers` passes with its fixture untouched.
- Built by a Fable agent, which the brief told to write the code as well as design it; the model table now leaves
  that choice to the Fable designer (the record 2026-11-12-breezy-rabbit).

## Choices open to overturn

- **The weights are handed in as numbers and the wall question as a function**, since `view_weight()` reads the same
  five weights; reading them from the new file would have moved them into `Tuning`.
- **`StreetInvalidation`, `RouteJunctionsRule` and `_best_of()` take no ground**: their one use was the list of
  junction boxes, which the junction rule now keeps itself, once per rule object.
- **A role's answer is a tile-to-times dictionary**, with no list, since nothing rolls an index into it; its cache key
  also says whether the row burns its front, which the scheduler's key left out; and `WalkSiting`'s set key,
  which left out the spread and the burn and gave day 3's fire and a poster crew one key, goes. The two never
  share a day, so nothing moved.
- **The home-street rule is set when the ground is made**: `WalkSiting` takes the ground in its constructor and its
  own flag goes. A rig that calls `EventManager.use_the_spec()` mid-walk no longer changes later sitings' rule.
- **`EventDef.stands_only_in_alleys()` replaces the scheduler's `_refuses_required_alleys()`**; `street_ground()` and
  `_weight_in()` stay in the scheduler, handed the ground.
- **The scene recipes still scan for themselves in three places** (`recipe_placement()`, `_finale_placement()`, and a
  recipe's walk, which carries no ground), left in minty-quail's `re-derived-cases.md`.
