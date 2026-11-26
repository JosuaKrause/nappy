# grassy-beaver — The car-free start: no new cars until the crossing with cars · 2026-11-26

The item car-free-start (day 1 starts with no new cars; the crossing bubble is the thought bubbles'),
built from the design's section for it (`.claude/briefs/designs/grassy-beaver.md`, not committed).
Its file is deleted.

## What the player said

"in the title screen we have the normal density we have today. then on the first day we show the
park and then go back to home. when showing the park, turn off car spawning so when the camera comes
back home no cars are around anymore" (minty-dolphin #867), and, on what ends it, no cars on the
first block, then cars only at the second crossing lesson or when she leaves the tutorial route,
one full block away, so she can turn around; once started they keep spawning (gentle-owl #1253).

## What was built

- **`CarEntryHold`** (shared by the crowd and every agent it makes) says whether new cars are held.
  While held, `LaneMover._recycle()` of a car does nothing but mark it, and the crowd parks it
  after the agents' step (`Crowd._park_the_held_cars()`): out of `_agents` and out of the tree, so
  it is not stepped, indexed or drawn. **Every slot a car holds is rebuilt each tick from the cars in
  the crowd** (the traffic index, the junction boxes, the gates), so parking has nothing to release
  one by one; the design had parking as a fifth way out of a shared slot, and the code has none to
  give back.
- **`Crowd.hold_new_cars()`** also parks at once every car nobody can see; a car in her view
  drives on and is parked when it leaves the box. **`let_cars_in()`** re-enters the parked cars
  through the ordinary recycle, one after another over `Crowd.LET_IN_OVER` (6 s). A morning started
  held populates its cars parked.
- **`CarFreeStart`** (`src/crowd/car_free_start.gd`), ticked by the crowd with her position, holds
  on the first tick of play and lets the cars in once, for good, when she stands on the fourth street
  of the route or is one street's length (`CityMap.period()` tiles) from the route's streets.
  `DayDirector` wires it when the spec walks the tutorial and lets the cars in before any other
  day's morning.

## Differences from the design

- **The title and the opening shot.** The crowd is handed her, and so ticks the piece, only when
  play begins, so the first tick is play's and the title keeps its density with no `main.gd` edit.
  A walk with a title in front of it (the boot's first walk, a resumed day's included, which shows the
  title) holds on that tick; every day 1 with none (a retry, a checkpoint carried on, a rig's
  `--no-title`) holds before its morning, so its cars are parked. `main` hands the director which
  it is (`DayDirector.use_a_title_in_front()`), not the boot's first-day flag, which a checkpoint's
  carry-on shares with a title's boot. The opening shot's item moves the crowd's box with its camera (it owns
  `main.gd`); nothing here needs it.
- **"Past lesson (4)'s zebra"** is the fourth street's ground (`TutorialRoute.lesson_streets()`
  index 2 and on), because the lessons' own zebra is not laid yet (the lessons on the route);
  when it is, this is the question to ask of the route.

## Open to the player's overturn

- **A retry of day 1 keeps the car-free start** (the design's pick, on lesson (4) being a crossing
  with no cars, gentle-owl #1253).
- **The cars come in on the fourth street**, a street before the player's "second crossing tutorial"
  (gentle-owl #1253), the design's pick: a recycled car takes seconds to reach a zebra, so letting
  them in at the second crossing's own street risks an empty crossing. The plainer alternative,
  the release at the second crossing's street (lesson (5)'s zebra), costs the same to build and
  risks that empty crossing.
- **One full block** is her straight-line distance from the nearest street of the route reaching one
  street's length, the same whichever way she left; the stagger over six seconds is the builder's.
