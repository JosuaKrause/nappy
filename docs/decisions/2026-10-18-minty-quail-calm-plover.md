# minty-quail — A drawn poster crew is kept for her walk, a sidewalk's event closes its section, and the reach rule walks the cut · 2026-11-09

minty-quail's `placement-by-construction.md`: three changes to the dawn's one draw, landed before
the item's numbered steps, and what was tried for the walk's draw and replaced. The step before it
is downy-toad.

**Built.** The dawn draws every open location once, as on main (`EventScheduler._draw_the_locations()`:
`LocationDraw.draw_all()` over `DayLocations.drawing_order()`), with three changes on purpose:

- **A poster crew is handed to her walk as it is drawn** (`LocationDraw._as_drawn()`, asking
  `EventScheduler.owed_to_her_walk()`, which replaces `_hand_to_her_walk()`), unplaced, so the rows
  drawn after it are spaced without it (`tests/test_location_draw.gd`'s crew case,
  `tests/test_events_fire.gd`'s crew test).
- **A sidewalk a dawn phase fills closes its section to the draw**
  (`DayLocations.assign_to()` → `StreetLocations.close_the_section_of()`), so the draw places
  nothing over a dawn phase's sidewalk event (`tests/test_day_locations.gd`).
- **The reach rule** works out what a body cuts off by growing the pieces beside its disc rather
  than flooding the city again (`RouteReachRule._cut_off()`; `tests/test_route_rules.gd` holds that
  it answers what the flood answers), and a disc over home cuts off everything.

**A retry is the same day** (PLAYTEST-119 27): the same day started twice stands the same rows on
the same tiles, and walking moves nothing placed (`test_event_manager`'s
`_test_a_retry_is_the_same_day_whichever_way_she_walks`). With no draw during the walk it cannot
catch a draw that depends on her path; step 2's unit draw is what it is for.
`tests/probes/walk_rows.gd` plans each day as the game does and counts each placed row as it comes
within the stream radius on the day's longest walk.

**The builder's choices, each open to overturn:** `DayEvents.replace()` is deleted with its
replacement branch, its one caller having been `_hand_to_her_walk()`; the files the walk's draw had
changed went back to main's text verbatim, docs included.

**Tried and replaced: the walk's draw.** Two designs were built on the pull request (#1262) and
neither is kept.

- **The dawn standing only the rows that block, the walk drawing the rest** (the first two heads,
  through `7b14fd6a2`): the walk drew every other location again, from a second set of bags, as she
  came near (`WALK_SHARE_SCALES`, caps spread as a rate on `WALK_CAPS_SALT`,
  `EventDef.blocks_the_way()`, `tests/drawn_day.gd`). A retry was not the same day, since the walk
  drew from one running stream per bag in the order she reached locations (PLAYTEST-119 27); the
  player called the two draws redundant (inbox #1268 in olive-ferret) and set exact parity with
  main aside as the bar; and the refit did not close: fitted on two samples of cities and checked
  on two more (64 cities), four passes over three tables took the cells outside 2σ pooled from 128
  of 498 to 24, 6 of them on two samples with the same sign where chance puts about 1. Its frame
  cost over 42 walks on three cities: a median tick of 1 µs, a p99 of 0.59 ms, a worst tick of
  11.3 ms, with 0.11% of locations drawn whole on one tick because she came within
  `WalkDraw.MUST_DRAW` of them.
- **Every open location drawn at dawn through the walk's machinery** (the next heads): `WalkDraw`'s
  band ahead of her, the draw sliced over ticks (`ViewBag.Drawing`, `LocationGround.Offer`,
  `LocationDraw.Asking`), `EventScheduler.RuledOffer`'s re-ask of a kept candidate, and
  `RuledLocationGround`'s walk branch with its `WeakRef`. The dawn drew everything, so the band
  found nothing and the walk branch was never reached; unreached code is deleted, not kept
  (inbox #1180 in gray-dolphin), and its dormant branch would have flooded the city during play
  (inbox #1173 in gray-dolphin). Before its index was rebuilt it cost a p99 of about 0.7 ms a tick
  for no draw. Step 2 builds the unit draw fresh.

**Measured.** 3 cities from 90210 in steps of 31, days 1 to 14, `tests/probes/placement_rows.gd`
on the head against main at `a4a7621e6`. With the crew and section changes reverted locally, every
per-row, per-view and per-kind line matches main but the poster crews', which the revert leaves
placed, so the head is main's draw plus exactly the two changes. With them, days 1 to 4 match
exactly; from day 5 the rows drawn after a crew are spaced without it, and a day's total moves by
−9 to +9.

| view | placed, main | placed, head |
|---|---|---|
| on her route | 997 | 989 |
| route-adjacent | 1191 | 1200 |
| off the route | 2087 | 2087 |

The per-row table is in the pull request's description.

**For the end-of-refactor remeasure.** Changed on purpose: a crew is handed on as it is drawn, so
later draws are spaced without it; a sidewalk a dawn phase fills closes its section. The counts
above are what moved.
