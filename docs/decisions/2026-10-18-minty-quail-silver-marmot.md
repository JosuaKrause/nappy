# minty-quail — The live event's body is a part of its own (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method", "fields are not API
interaction between different objects need to go through APIs", and an ability an event has is a
part it is composed of (inbox #1173 in gray-dolphin). The step "the live event's behaviours ask it
through `Figure`, and are handed the rest" of the events' interface design
(`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a, which names "`EventBody` taken
out of `EventInstance`") is built as seven pull requests, a cut the orchestrator's planning agent
made and no tracked file holds; this is the seventh, built beside the sixth (the live event's field
asks its row, minty-quail-striped-magpie), after the records minty-quail-velvet-owl,
-olive-finch, -tiny-alpaca, -tawny-swan and -striped-hawk.

## What was built

- **`EventBody`** (`src/events/event_body.gd`), a part the live event composes, as it composes its
  excitement source. It holds what the event is on the ground: the collision body, the tiles it is
  recorded on, the axis it lies along on its street, the side a parked vehicle shows, a boom's body
  following its arm, the check that a body never goes down around her, the drop of a pursuer's body,
  and the barrier post's pin and the car's turn of the body.
- **What it is handed**: its row, the map, where she is, the node its collision body stands under
  (the live event, so the `StaticBody2D` is still the event's direct child), where it landed, the
  way it was sited facing and whether its street runs it vertically. What changes (where the event
  stands, its heading, whether the arm is up) is handed with each call; it tells nothing upward.
  A test builds it with a row, open ground, nobody, a bare node and no scene tree; no suite of its
  own was added, since the named suites hold every behaviour it has through the live event.
- **The live event's outward questions** (`is_solid()`, `runs_vertically()`, `stands_side_on()`,
  `solid_axis()`, `solid_part_centres()`, `solid_part_shapes()`) are answered by the body, and
  `Figure`'s five body members ask it directly.
- **The row's added questions**, beside `solid_reach()`: `ground_shape()`, `body_pieces()`,
  `has_a_body()`, `solid_from()`, `is_walked_round()`, `parks()`, `moves()`, under the body part's
  design names until the body has a settings class of its own (the design's 4b).
- `docs/EVENTS.md` and `docs/ARCHITECTURE.md` name the body; six comments in other files that named
  the deleted `_build_obstruction()` name `EventBody.go_down()`. `tests/test_prediction_reuse.gd`
  writes its two names on the body, where the fields now are. `tools/field_reads.txt` lost four
  lines and gained none.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `main` at `bf9798e0f`, the commit this branch was made from, and on the code commit
`ed0a07048`: what every source charges her tick by tick (`probes/excitement_fingerprint.gd`, its
`XF` lines less `XF_COST`), and every event, crowd agent and baby meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values).

## Choices the builder made where the design or the brief was silent, open to the player's overturn

- **What changes is handed with each call, not asked through `Figure`**, which keeps the body
  buildable with no live event at all; the plainer alternative is handing it the `Figure`.
- **The arm's state is handed per call**, since streaming and two suites write the event's
  `gate_state` after `setup()`; the event answers `is_raised()` itself, and the design's one setup
  call (its 3b) is where the body can hold the gate.
- **The live event still decides when a pursuer drops its body and when a car's body goes down**,
  asking the body `is_down()` and telling it `drop()` or `go_down()`: the condition asks the
  pursuit, the car and the barrier post, the event's parts and not the body's. The design's
  `Figure.drop_its_body()` is still not added.
- **The live event fills its move from the body's answers**, since `MoveProposal` has no setter for
  either and the field-read list may gain no line.
- **"Inside it" is measured with `solid_reach()`**, where the code read `obstructs_radius`; the two
  are the same number for every row with one piece, and the one row solid once it starts is one
  piece, so no answer changes.
- **`has_a_body()` is `obstructs_radius > 0`**, the reading the event made; the design's live
  `has_a_body()` for the contact point is a later step's.
- **Names beyond the design's**: `land_at()`, `is_down()`, `waits_to_come_down()`,
  `come_into_the_world()`, `go_down()`, `come_down_clear_of_her()`, `follow_the_arm()`,
  `tiles_at()`, `has_parked_from_the_start()`, `pin_at()` (the design's `pin_where_it_stands()`,
  pinned at a place the barrier post hands), `unpin()`, `turn_to()`.

## Left with the live event, and why

- **`EventInstance._spread_is_vertical()` stays a static of the live event**: the spawner, the
  footprints, the walk's ground, two dev rigs and a probe call it by that name, all outside this
  pull request's files, and a forwarder under the old name is ruled out (minty-dolphin #852). The
  event works the answer out and hands it to the body; it moves with the spawner's step (3b).
- **`gate_state` stays the live event's**, written by streaming and the suites after `setup()` and
  read by the looks.
- **`EventDef.parts()` stays beside `body_pieces()`** for its readers outside these files; the row
  written as its parts (4b) is where the one goes.
