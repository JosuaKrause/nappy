# minty-quail — The chase asks the live event through Figure: the pursuit, the man on foot, the barrier post and its far guard (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
step "the live event's behaviours ask it through `Figure`, and are handed the rest" of the events'
interface design (`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as
seven pull requests, a cut the orchestrator's planning agent made and no tracked file holds; this
is the fourth, after the doors, the sources and the encounter watch (minty-quail-velvet-owl), where
she is as one object (minty-quail-olive-finch) and the seven behaviours that walk, wait and hold
(minty-quail-tiny-alpaca), which built `EventInstance.Figure`.

## What was built

- **The pursuit, the man on foot, the barrier post and its far guard no longer hold their live
  event.** Each is handed what never changes in its constructor and asks what changes through
  `Figure`; none reads a field of the live event. The investigation and the car keep their event
  (`attach()` and the base's `event`) until the next pull request.
- **What each is handed**: the pursuit the figure, where she is, the row, its `PursuitSpec`, the
  navigator, the mover, the route walk (or none), the man on foot and the barrier post (or none);
  the man on foot the figure, where she is, the row, its `PursuitSpec`, the navigator and the
  mover, and after it is made the departure, and the vehicle that let him out as before; the
  barrier post the figure, where she is, the row, the map, the navigator and the mover, and after
  it is made the departure; the far guard, made in the barrier post's constructor, the same six,
  the band's place when he is sent off and the departure on each step he walks. No `NoticeSpec`
  is handed to any of the four: they ask only the row's `notice_within()`.
- **The departure is handed to the man on foot and the barrier post after it is made, held by a
  `WeakRef`**, as `WorldMap` holds its navigator: the departure is handed them in its own
  constructor, so a strong reference each way would be a cycle never freed.
- **The held lunge's pause and the stop-warning moved from the event into the pursuit**
  (`EventPursuit.pause_a_held_notice(delta)`, asked by the event at the same moment of its tick;
  `EventInstance._stop_warning()` is gone, and the pursuit tells its figure
  `wait_for_her_again()`, forgets its held lunge and puts a roadblock's guard back at his band).
  `EventInstance.notice_her_at()` tells the pursuit `was_set_on_her(her)`. The event reads no field
  of the pursuit; the held lunge is internal (`_lunge_held`).
- **`EventInstance.call_back_its_officers(stopped_by)`**, beside `let_out()`, is the vehicle's side
  of a man's stop, asked through `Figure.stopped_her(vehicle)`, since the man no longer holds his
  own event to name himself by. The event's tick asks the barrier post to walk its far guard
  (`walk_the_far_guard_off(delta)`) instead of reaching through it to the guard.
- **`ChargeRecord`** gains `count_as_over()`, is typed and loses its first-line opt-out.
  `PursuitSpec` gains `stands_for_its_notice()` and `is_drawn_over_the_street()`, `NoticeSpec`
  gains `is_quiet()`, each asked by the live event in place of the field.
- `docs/EVENTS.md` and `docs/ARCHITECTURE.md` say who still holds their event; the events skill's
  pursuit reference and `docs/MECHANICS.md` name the pause where it now is.
  `tools/field_reads.txt` lost 45 lines and gained none.
- **One suite changed**: `tests/test_event_behaviours.gd` sets and reads the held lunge through the
  state a stream-out carries (`save()`, `restore()`) instead of the field, in two checks that hold
  what they held.

## `Figure`'s questions and events

Added here, ten questions: `body_place()`, `runs_vertically()`, `solid_axis()`,
`clear_line_to(point)`, `would_stand_in_her_view()`, `warns_by_radius()`, `notice_is_a_warning()`,
`is_standing_for_its_notice()`, `charge_radius()`, `way_round_to_her()`; and eight events:
`charge_ended()` and `hold_the_notice(delta)` (the design's names), `give_up()`,
`stopped_her(vehicle)`, `be_only_its_barrier()`, `pin_its_body_at(at)`, `unpin_its_body()`,
`appear_where_it_stands()`. Each is a call, a read or a write the four already made on their
event, and each name beyond the design's is the builder's choice, open to the player's overturn.
`Figure` now has twenty-six questions and nineteen events.

**Not added: the design's `drop_its_body()`.** None of the four drops a body: the moving pursuer's
body comes down in the event's own tick, which this change leaves where it is, and the barrier
post pins and unpins its body. It comes with the car, if the car calls it.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `main` at `db614cdf5`, the commit this branch was made from, and on the code commit
`2f270fd52`: what every source charges her tick by tick (`probes/excitement_fingerprint.gd`, its
`XF` lines less `XF_COST`), and every event, crowd agent and baby meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values). `probes/charger_warning.gd` and
`probes/tall_osprey_catch.gd` print the same lines on both trees once their timing figures are
taken out.

## Two members kept public for the suites, open to the player's overturn

`tools/test_only_members.txt` gains two lines in its `[kept]` group, each with its reason, where
the brief said the list loses lines and gains none. Taking the four off their event removed the
last reader outside the event's own file of two members the suites and probes read:

- **`EventInstance.gave_up`** (whether a chase ended because she outran it), which the pursuit now
  sets through `Figure.give_up()`. Three probes and some 30 suite lines read it, and the probes
  were outside the brief's fence; the brief kept it public while a suite reads it.
- **`EventInstance.transition()`**, which the four now reach through `Figure.begin()`. Nine lines of
  five suites put an event in a phase with it directly; reaching each phase the way the game does
  is the design's test step (its 2.9, row 4a), and a suite changes here only as far as the code it
  reaches moved (inbox #1278 in olive-ferret).

The builder's choice, which the orchestrator kept. The plainer alternative is both made internal
and the probes and suites converted in this pull request. Each line goes once its readers ask
through `has_given_up()` and the phase questions.

## Choices the builder made where the design was silent, open to the player's overturn

- **The departure handed after it is made and held weakly** (above), rather than its three walking
  lines written again in the man on foot or the departure's constructor changed.
- **The held lunge's pause and the stop-warning in the pursuit** (above), so `hold_the_notice()`
  has its caller and the event stops reading the pursuit's field.
- **`stopped_her(vehicle)` is one event**: the stop, its counted catch and the vehicle's call-back.
- **`be_only_its_barrier()` is one event**: the spent phase and its notice stopped together, as
  both places that make a guard spent do both.
- **`pin_its_body_at()`, `unpin_its_body()` and `appear_where_it_stands()`** stand where the barrier
  post wrote the event's body and reset its interpolation; the design's `EventBody` is a later
  step's.
- **`give_up()`** sets the flag and ends the chase as the pursuit did, not through
  `give_up_the_chase()`, whose guard against a leaving or finished event is a different test.
- **`charge_began()` is told whenever the chase comes for her**, since `ChargeRecord.begin()` says
  it once; **`charge_ended()` answers `ChargeRecord.count_as_over()`**, the reading of the design's
  4.2 row for the barrier streamed in spent.
- **The far guard is handed the band's place and the departure per call** rather than holding the
  barrier post, which would be a cycle.

## Reads left, and why

- **`PursuitSpec.speed`, `walk_speed` and `stop_excitement`**: the design's names are the fields',
  and a method and a variable cannot share a name in one class.
- **The row's `shape` and `guard_sides`** (the barrier post): the row has no method for either
  until the row is written as its parts.
- **`PursuitSpec.leaves_its_body_standing()` is not added**: its one reader is
  `EventDef.leaves_its_body()`, a later step's file, so the method would have no caller.
- **Fields of the live event the four stopped reading stay public** where another file still reads
  them (the car, the investigation, the looks, streaming, the resistance, the suites); `_navigator`,
  `_mover`, `_spread_vertical`, `_guard_spent`, `_charge`, `_notice`, `_chase_way` and `gave_up`
  have no reader outside the event's own file in the game now.
