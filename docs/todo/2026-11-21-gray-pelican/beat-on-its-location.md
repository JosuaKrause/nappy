# The location is the one place that says a beat stands on it

**What is wrong.** That a beat stands on a location is written in three places, kept in step by
two private methods of `WalkSiting` (`_stand()` and `_give_back()`): on the location
(`Location._plan`, through `DayLocations.take_for_her_walk()`), on the location's unit
(`PlacementUnit._rigged`, through `rig()` and `unrig()`), and in the siting's own
`_laid`. The unit already holds its locations, so the unit's list is the same fact stored twice.
The written design asked for it (its section 4.11), so this corrects the design, not the build.
What the second copy costs today:

- `WalkSiting` is handed `DayUnits` only to write that copy and to ask whether a location's unit
  has filled in, which the location itself answers: `MarbleDraw.draw()` records every open
  location of a unit as it fills in, so a free location is open exactly while its unit has not.
- `SitingMaker` groups a throwaway set of units for a walk that never fills any in (a scene
  recipe's), only so the siting has units to ask.
- `WalkSiting` carries three `if _units else null` guards, a rule of its own for "a location no
  unit holds" (the record's departure 4), and a repair after the fact: a location given back in a
  unit that filled in meanwhile is re-recorded as drawn-empty by the siting, because the unit's
  draw passed over it while it was taken.
- `DayUnits.unit_of()` and its index exist for the siting alone.

**The design.** The location says who stands on it; the unit reads its locations; the unit's draw
leaves every location of the unit drawn.

1. `src/events/location.gd` (model). `take_for_her_walk(plan)` stands the plan and remembers it
   as a beat; `give_back(plan)` forgets both; `beat() -> EventPlan` answers the beat while it is
   still what stands there, else null (so a section swapped in over it, day 13's task roadblock,
   ends it without a second call). `DayLocations.take_for_her_walk()` calls the new method.
2. `src/events/marble_draw.gd` (model). The closing loop of `draw()` records as drawn every
   location of the unit that is open **or holds a beat**; what stands on it is left
   (`Location.record(null)` only sets the drawn mark). After a unit fills in, a location given
   back reads drawn-empty with no repair.
3. `src/events/placement_unit.gd` (model). `rig()`, `unrig()`, `rigged()` and `_rigged` are
   deleted; `beats() -> Array[EventPlan]` answers its locations' beats, in the locations' order,
   each once.
4. `src/events/unit_draw.gd` (model). `_draw_alone()` asks `unit.beats()` and
   `other.beats()`. Its class comment names the method.
5. `src/events/walk_siting.gd` (simulation). The `units` argument and field go. A free location
   is of a unit that has not filled in exactly when `location.is_open()`. `_stand()` takes the
   location; `_give_back()` gives it back; the guards, the repair and the sentence "a location no
   unit holds counts as drawn" go.
6. `src/events/siting_maker.gd` (simulation) builds no units; `src/events/day_units.gd` loses
   `unit_of()` and `_unit_of` once `rg -n "unit_of\\(" src tests` shows no other caller.

**Tests.** `tests/test_walk_siting.gd`: its `_Units` stand-in goes, and a location is made "of a
unit that has filled in" by recording it; the rig and unrig checks become "the location holds the
beat, and gives it back on a move". `tests/test_placement_unit.gd`: `beats()` answers what her
walk stood on its locations, not what a draw or a dawn phase put there, and not a beat given
back. `tests/test_marble_draw.gd`, a new check that fails on main: a location that held a beat while its
unit filled in reads drawn-empty once given back. `tests/test_unit_draw.gd`,
`tests/test_day_units.gd`, `tests/test_event_manager_units.gd`, `tests/fake_walk_siting.gd`,
`tests/probes/walk_rows.gd`: `rigged()` and `unit_of()` become `beats()`.

**Parity: nothing a player sees changes.** `tests/probes/placement_rows.gd` identical before and
after. `tests/probes/walk_rows.gd` for day 3, the run the record names: `WC`, `WS` and `WR`
identical to the base commit's (the record has `WS 3 136 29 107 101` and `WR 3 7674 3 3 0 0`).
Two corners the builder checks and names in the description:

- the unit's beats now come in its locations' order, not the order laid. The rules a draw is
  judged by read a set, so no draw moves; if a probe line moves, stop and report;
- a street section a dawn phase closed reads as drawn while its unit has not filled in, so it
  would be offered in the second tier, not the first. No beat's ground is carriageway today, so
  none is offered there.

**Docs made false:** `docs/EVENTS.md` (item 1 of "Where the code differs from the design" names
`PlacementUnit.rigged()`), `docs/ARCHITECTURE.md`'s lines for `placement_unit.gd`,
`walk_siting.gd` and `siting_maker.gd`, `plan-and-excitement.md` (names `PlacementUnit.rig()`;
a skill change, flagged). While those sentences are open: `docs/MECHANICS.md` ("A retry is the
same day"), the events skill and `plan-and-excitement.md` say the one exception is a unit a beat
stands in or beside; the record's departure 3 shows a difference may also carry to a unit
touching one that differs. Each gains that clause.

**Cost.** One small pull request for a Sonnet builder: seven files under `src/`, about sixty
lines fewer, six suites and one probe touched. One day-3 probe run.

**What it collides with.** None of its files is on row 4b's lists except through 4b-10's scripted
rewrite, which a branch reruns after merging main; it runs beside 4b-3 to 4b-9. It shares
`plan-and-excitement.md` and `docs/EVENTS.md` with change 1 in different sentences: whichever
merges second merges main first. It should land before row 5's group for the event manager's
suites.
