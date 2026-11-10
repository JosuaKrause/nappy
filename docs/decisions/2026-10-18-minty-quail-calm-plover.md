# minty-quail — The day's open locations go through the walk's draw, all of them at dawn · 2026-11-09

minty-quail's `placement-by-construction.md`: the walk's drawing machinery, landed before the item's
numbered steps, with the game using it once, at dawn. The step before it is downy-toad.

**Built.** The dawn draws every location its phases leave open, each once, through the walk's draw
(`WalkDraw.draw_everywhere()`, called at the end of `EventScheduler._plan_the_dawn()`), from its
view's bag (`LocationDraw`), in the day's order (`DayLocations.drawing_order()` on `LOCATIONS_SALT`),
judged by every rule of the day, the reach among them. `build_day()` holds the whole day.

- **The band stays and draws nothing.** `WalkDraw.draw_ahead()` (the nearest location out of her
  view in a band past the stream radius, a step a tick, a sidewalk after its section, nothing in
  her view) runs each tick and finds no location open. Its index is rebuilt of the open locations
  after the dawn's draw, so a tick asks nothing.
- **A retry is the same day** (PLAYTEST-119 27): the same day started twice stands the same rows on
  the same tiles, whichever way she walks (`test_event_manager`'s
  `_test_a_retry_is_the_same_day_whichever_way_she_walks`).
- **A step of a draw**: one marble from the view's bag, or one tile of a row's offer
  (`LocationGround.begin_offer()`, `RuledOffer`, `ViewBag.Drawing`); a candidate kept over ticks is
  asked again if what the rules read changed since.
- **Each draw stands as it is drawn** (`RuledLocationGround.stand()`), and a place her walk gives a
  plan the ground already holds is seen by the next draw (`_one_was_sited()`): a poster crew sited
  in the middle of an undrawn location leaves no tile of it offered
  (`tests/test_ruled_location_ground.gd`).
- **A sidewalk that holds an event closes its section to a draw**
  (`StreetLocations.close_the_section_of()`), since a dawn phase can fill a sidewalk before the
  draw reaches its section.
- **The reach rule** works out what a body cuts off by growing the pieces beside its disc rather
  than flooding the city again (`tests/test_route_rules.gd` holds that it answers what the flood
  answers), and a disc over home cuts off everything.
- `GROUND_WEIGHTS` and `WALL_VIEW_SCALES` hold the values they had before this step, and the daily
  caps count draws. No table is fitted.

**Why at dawn** (the orchestrator's ruling on the pull request, #1262, open to the player's
overturn). The player's design draws a street as she comes near it (`placement-by-construction.md`,
step 2); that needs a street's draw not to depend on her path, which the unit draw of step 2 gives
and this machinery alone does not. Until then the one draw is made where a retry is trivially the
same day.

**The builder's choices, each open to overturn:**

- **The draw is made at the end of the dawn, not by `EventManager`** as the brief said. Three things
  read the day's drawn rows at dawn: the run lesson (`_ensure_the_run_is_taught()` adds day 3's
  lesson dog only when the plan holds no pursuit, and a drawn charging dog is one), day 13's
  uncovered count in the run log, and what the manager takes from the plan (`DayReach`, the crowd's
  bodies). `EventManager.draw_everywhere()` is deleted.
- **A crew is handed to her walk as it is drawn** (`LocationDraw._as_drawn()`), unplaced, so the
  rows drawn after it are spaced without it. This is the one systematic difference from the draw
  before this step.
- **A section closed by its sidewalk is recorded as drawn empty**, not left open, so the per-tick
  draw does not ask it again.

**Tried and replaced: the dawn standing only the rows that block, the walk drawing the rest.** The
pull request's first two heads (through `7b14fd6a2`) swept every location at dawn, kept only the
rows that block the way and the crews, and had the walk draw every other location again, from a
second set of bags, as she came near (`WALK_SHARE_SCALES`, caps spread as a rate on
`WALK_CAPS_SALT`, `EventDef.blocks_the_way()`, `tests/drawn_day.gd`). Two reviews came back not
ready. What ended it:

- **A retry was not the same day.** The walk drew from one running stream per bag in the order she
  reached locations, so a different path gave a different day (PLAYTEST-119 27).
- **The player called the two draws redundant** (inbox #1268 in olive-ferret) and set exact parity with main aside
  as the bar.
- **It needed a refit that did not close.** Fitted on two samples of cities and checked on two
  more (64 cities), four passes over three tables took the cells outside 2σ pooled from 128 of 498
  to 24, 6 of them on two samples with the same sign where chance puts about 1 (the chatting mother
  on a junction box, the alley mouse in an alley, the square's poster crew, the pigeon flock on
  open ground).
- **Its frame cost, for step 2 to compare against**: three cities, 42 walks, the walk's draw a
  median tick of 1 µs, a p99 of 0.59 ms and a worst tick of 11.3 ms, with 0.11% of the locations
  drawn whole on one tick because she came within `WalkDraw.MUST_DRAW` of them.

**Measured.** 18 cities from 90210 in steps of 31, days 1 to 14, against main at `38ce03823`.
`tests/probes/placement_rows.gd` counts what each day places; `tests/probes/walk_rows.gd` plans
each day as the game does and walks the day's longest route out and home, counting each placed row
as it comes within the stream radius.

| view | placed, main | placed, head | met on the walk, main | met on the walk, head |
|---|---|---|---|---|
| on her route | 6290 | 6302 | 4142 | 4176 |
| route-adjacent | 7124 | 7156 | 4602 | 4612 |
| off the route | 12487 | 12471 | 4218 | 4235 |
| all | 25901 | 25929 | 12962 | 13023 |

The per-row table is in the pull request's description. Over the walk probe's 252 walks the
per-tick draw drew no location. The dawn's planning time (`EventScheduler.build_day()`), main and
head run side by side under the same load over 84 days: a median of 2.28 s on main and 2.31 s on
the head. Run one after the other the head's median was 4.41 s against 2.09 s, with other agents'
suites loading the machine during the head's run.

**For the end-of-refactor remeasure.** Changed on purpose: a crew is handed on as it is drawn, so
later draws are spaced without it; a sidewalk that holds an event closes its section. The counts
above are what moved.
