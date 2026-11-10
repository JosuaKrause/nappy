# minty-quail — A live event's behaviours that walk, wait and hold ask it through Figure, and are handed the rest (minty-quail, the events' interface) · 2026-11-10


**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
step "the live event's behaviours ask it through `Figure`, and are handed the rest" of the events'
interface design (`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as
seven pull requests, a cut the orchestrator's planning agent made and no tracked file holds; this
is the third, after the doors, the sources and the encounter watch (minty-quail-velvet-owl) and
where she is as one object (minty-quail-olive-finch).

## What was built

- **`EventInstance.Figure`**, an inner class of the live event, as `LaneMover.Lane` is the lane
  mover's view of itself. The live event makes one over its own place, heading, way covered,
  clocks and phase, and `setup()` passes it to the composer, which hands it to the behaviours; no
  public method of the live event hands it out. A behaviour asks it questions and tells it what
  happened. The stored phase still changes only in `transition()`, asked for through
  `Figure.begin(phase)`; the notice clock and the charge record stay private to the event.
- **Seven behaviours no longer hold their event**: the departure, the route walk, the hold (the
  chatting mother's conversation, a checkpoint hut's or post's inspection), the unmarked van's
  take of a bystander, the flock's birds, the notice run (the alley mouse, the flock's flush, the
  masked man) and the row retired when it cannot reach her. Each is handed what never changes in
  its constructor and reads no field of the live event.
- **What each is handed**: the departure the figure, where she is, the row, the map, the
  navigator, the mover, the barrier post and the man on foot (either may be none); the route walk
  the figure, the row, the navigator and the mover; the hold the figure and the row; the take the
  figure, where she is, the row and its `AbductionSpec`; the flock the figure and the row; the
  notice run the figure, where she is, the row, its `NoticeSpec` and the route walk (or none); the
  retired row the figure and where she is.
- **The composer** makes the siblings another behaviour is handed (the man on foot, the barrier
  post, the route walk) before the behaviours handed them; the order the behaviours tick in is
  unchanged. `setup()` sets the map, the navigator and the mover before it composes.
- **The pursuit, the man on foot, the barrier post, the far guard, the investigation and the car
  keep their event** (`attach()` and the base's `event`), until the pull requests that follow.
- `docs/EVENTS.md` and `docs/ARCHITECTURE.md` say what a behaviour is handed and asks through.
  `tools/field_reads.txt` lost 42 lines and gained none. No test changed.

## `Figure`'s questions and events

The design's: `place()`, `heading()`, `travelled()`, `age()`, `chase_age()`, `walks()`, the phase
questions (`is_waiting()`, `is_telegraphing()`, `is_telegraphing_still()`, `is_on_its_way_out()`,
`has_parked()`, `is_only_its_barrier()`, `is_gone()`), `notice_has_run()`; and the events
`turn_to(heading)`, `walk_on(distance)`, `step_by(delta)`, `begin(phase)`, `be_done()`,
`charge_began()`.

Not in the design, each one call the event already made for itself, and each the builder's choice
open to the player's overturn: the questions `notice_time()`, `field_reaches(point)` and `trace()`;
the events `arrive_at(at)`, `end_its_route()`, `notice_her()`, `warning_went_up()` and
`wait_for_her_again()`.

Named by the design and not added, since no converted behaviour calls them yet (a method with no
caller is code nothing reaches): `drop_its_body()`, `hold_the_notice(delta)`, `charge_ended()`.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `main` at `6cfefd380`, the commit this branch was made from, and on the code commit
`8979970a8`: what every source charges her tick by tick (`probes/excitement_fingerprint.gd`, its
`XF` lines less `XF_COST`), and every event, crowd agent and baby meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values). Two more probes,
`probes/m110_bodies.gd` and `probes/event_car_give_way_trace.gd`, print the same lines on both
trees once their timing figures are taken out; they are compared because the crowd's conversion
broke on a path its cost probe did not reach (minty-quail-brisk-lark).

## Choices the builder made where the design was silent, open to the player's overturn

- **`walks()` answers the route itself**, as the plan's `walks()` does; the route walk walks it and
  the others ask whether it has more than one point.
- **`arrive_at(at)` beside `step_by(delta)`**: a walk through the navigator ends at a point, and
  setting the place to it is not the same number as stepping by the difference, so parity needs
  the absolute form.
- **The place, the way covered and the heading are told as three events** (`step_by()`,
  `walk_on()`, `turn_to()`), not one.
- **`notice_has_run()` answers the event's `_telegraph_ended`**, the reading of the design's row.
- **`be_done()` keeps its argument** (`may_park`), which the departure's walk down a given way
  passes as false; `begin(Phase.DONE)` stands where the private `_finish()` stood.
- **The base holds `_figure` and `_where`, and each converted behaviour sets them in its own
  constructor**, since a base constructor would need defaults for the behaviours that still use
  `attach()`.
- **The notice run no longer tests its `NoticeSpec` for none**: the composer makes it only for a
  row with one.

## Reads left, and why

- **`AbductionSpec.taken_over` and `NoticeSpec.runs_within`**: the design's methods have the
  fields' names, a method and a variable cannot share a name in one class, and the fields stay
  while the looks, the catalogue and the row read them.
- **The masked man's own line warning** (`Warning.length`, `cancel_if`, `on_expired` in the notice
  run): a `Warning` the behaviour owns, not the event's notice clock, so no event on `Figure`
  replaces it. The brief read it as the event's notice, wrongly.
- **The row's fields read through the handed row**, where the row has no method yet (the
  departure's `mobile` and `vehicle`, the route walk's `speed` and `paces`, the take's `pursuit`,
  `duration` and `id`, the flock's and the notice run's sizes and reaches); where it has one, the
  method is asked (the hold asks `detains_for()` and `detains_again()`).
- **Every field of the live event the seven stopped reading stays public**, since the unconverted
  behaviours, the looks, streaming and the suites still read it; the step that converts a field's
  last reader makes it private.
