# minty-quail — The day's derived facts are objects built once and handed in · 2026-11-06

The player's note inbox #1156, built on their word in PR #1158; no queue item. Shown the
spoiled-ground rule as `EventScheduler._is_spoiled()`, the player asked why a property of the day
was a private member of the scheduler. They asked for one object that holds what the day derives,
built once and passed around, with no private method re-deriving it. They drew the line between a
save file and the state built from it. They then asked for the objects to be injectable so tests can
mock them, for the logic to be checked once on the real object, and for tests that do not test the
city never to build one. The design was shown on the PR and approved ("yes"), with the live form
after dawn as the next PR.

**What stood before.** The spoil rule was written twice in `EventScheduler`: a local `spoilers` map
in `_ensure_one_usable_park()`, and `_is_spoiled()` for `_calm_to_keep_reachable()`. The plan was a
bare `Array[Planned]` that every pass read and edited directly. Which areas she had not used was
worked out three times, an area's calm tiles six times, and the day-12 swing park was inferred from
which calm rect held a target tile. The tests held two more copies of the spoil rule:
`tests/spoiled_ground.gd`, and inline copies in `test_events_scheduler.gd` and
`test_events_costs.gd`. The inline copies had drifted: they grew the ground by `outer_radius` where
the game grows it by `field_reach()`, and one of them did not exempt a permanent body.

**Built.**
- `DayEvents` (`src/events/day_events.gd`). `build_day()` makes it with `over(calm, standing)` and
  is its only writer, through `add`, `add_all`, `remove` and `replace`. It keeps three things in
  step on every write: the rows spoiling each calm area, the rows that block the way (in plan order,
  since the repair's `sort_custom` is not stable), and a pursuit count. `build_day()` now returns
  it, and `DayPlanner` reads `placements()`.
- `CalmAreas` (`src/events/calm_areas.gd`), made by `DayPlanner` with `of(map, used, day, target)`.
  It holds the calm areas, their ground and calm tiles, which she used this act, and the one set
  aside. The set-aside area is decided in `of()`: the swing park read from
  `CityGenerator.swing_park()` on the swing day while the swing is a target and the park is calm.
  The read matched the old inference on seeds 4242, 90210, 1234567, 31337, 1000, 1031 and 1062, and
  the reviewer's check found the same on 90 day-12 seeds and on days 9, 11, 13 and 14 of 5 seeds. A
  park's calm rect is its whole lot, which holds the playground and so the swing.
- `DayRepairs` (`src/events/day_repairs.gd`): the two repairs, `ensure_one_usable_park()` and
  `ensure_the_city_is_still_walkable()`, made public and handed both objects. The name is for what
  the class is, a pair of repairs, under the player's naming rule (inbox #1156); `WinnableDay`,
  named for what a caller gets, was its first name and reads as an interface's.
- `Planned.reaches()`, `spoils()`, `obstructs()` and `blocking_radius()` hold the rules about one
  row.
- Gone: `_is_spoiled()`, the `spoilers` map, `_calm_to_leave_alone()`, `_calm_block_holding()`,
  `NO_CALM`, `_reaches_rect()` and `_blocking_radius()`. The placement judge (`_best_of()` and the
  checks under it) still takes an `Array[Planned]`, since `WalkSiting` after dawn shares it; at dawn
  it is handed `placements()`.

**Tests.** Each object's logic is checked once on hand-built inputs, with no generated city:
`test_day_events`, `test_calm_areas` and `test_day_repairs`. The fakes are
`tests/fake_day_events.gd` and `tests/fake_calm_areas.gd`. Each overrides only what the code it is
handed to asks, and their values are copied from what the real objects answer for seed 4242: the
clean-park cases hold all nine of its calm areas and their spoiler counts on day 4. The spoil-rule
copies are deleted, and the checks that read them now ask the `DayEvents` a day returns. Those
checks are one park stays usable, the calm she has not used is left alone, the city remembers where
she went, the spent park, the scar suite's reachability and the run lesson. Their assertions now
follow the game's own rule rather than the drifted copies, which were weaker. The #1147
closed-streets check stays as the integration check of the day's planning choosing the clean area on
a real day: it makes the calm areas through `DayPlanner`'s call, `CalmAreas.of()` from the day and
its target, so it reaches the set-aside choice, and plans through `build_day()`. A first version of
this PR handed it the swing park directly, so nothing tested the set-aside choice; the review's
mutant (the choice always answering none) passed every suite. It fails both `test_calm_areas` and
this check now. `test_resistance_reach_narrow` reads a booted day after dawn, so it asks
`Planned.spoils()` of each row until the next PR hands the live plans a reader.

**Times, before and after**, from local runs of the suites rewritten in place (ms). Before is `main`
before this PR, and after is this branch merged with `main` after #1160:

| Suite | Before | After |
|---|---|---|
| `test_acts` | 26839 | 19664 |
| `test_events_costs` | 52656 | 41544 |
| `test_events_pursuit` | 15112 | 12484 |
| `test_events_scheduler` | 81085 | 71622 |
| `test_resistance_reach_narrow` | 60020 | 52072 |
| `test_spent_park` | 93494 | 101608 |
| `test_day_events`, `test_calm_areas`, `test_day_repairs` (new) | — | 33, 34, 40 |

The machine was shared with other agents' runs, and the same suites ran up to a fifth apart from one
run to the next, so these show no change either way. `build_day()` itself was timed directly: 84
days (three seeds, days 1 to 14, twice) took 74.0 s before and 73.9 s after.

**The dawn plans are the same.** `tests/probes/placement_fingerprint.gd` printed the same 15787
placements on `main` and on this branch (escape city, building and days 1, 4, 8, 9, 10, 12 and 14 of
two seeds).

**Left for the next PR, the live form after dawn.** `WalkSiting` still works out what blocks the
way, the unused calm and an area's calm tiles from the manager's live list, and builds its own
`CalmAreas` for the leave-alone ground. `recipe_placement()` builds `CalmAreas.of(map)` for the same
ground, since its caller in `src/dev/` is outside this PR. `ResistanceDirector` and the park cordon
still work out what blocks the way for themselves. `ClosurePlanner` and `RouteTree` keep their own
calm-tile loops.

**Remeasure at the refactor's end.** Nothing moved on purpose, and the fingerprint above shows the
plans did not.
