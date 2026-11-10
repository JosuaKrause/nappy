# minty-quail — The checkpoint doors, the events' sources and the encounter watch ask a live event through methods, and the watch keeps its own records (minty-quail, the events' interface) · 2026-11-10


**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
events' interface design (`docs/todo/2026-10-18-minty-quail/event-interface.md`) cuts its step "a
live event's behaviours ask it through one interface" into seven pull requests; this is the one for
three files inside the events folder that are callers of a live event like any caller outside it.

## What was built

- **The checkpoint doors** (`checkpoint_controller.gd`: the doors' holds, their guards' raised
  hands and the boom) ask the live event: `detains_her()`, `detain_distance()`, `detains_for()`,
  `detains_again()`, `is_a_boom()`, `solid_reach()`, `raise_its_guards_hand(on)`,
  `is_its_guard_warning()`, beside `row_id()`, `is_gone()` and `is_on_its_way_out()`, which
  existed. The file reads no field of a live event or of its row but the two `baby_awake` reads
  that belong to the pull request moving where she is.
- **The events' sources** (`event_sources.gd`, the day's live events as things that charge the
  baby) ask `source()` and `counts_as_one_barrier()`.
- **The encounter watch** (`encounter_watch.gd`, the run log's and GoatCounter's count of what she
  met) asks `detains_her()` and `source()`, and keeps its records in a table of its own. `EventInstance.encounter`, the watch's record stored on the event, is deleted.
- **On the row** (`event_def.gd`): `detains_for()`, `detains_again()`, `is_a_boom()` and
  `counts_as_one_barrier()`, each the design's name; the live event's questions answer through
  them.
- **Typing.** `checkpoint_controller.gd` lost its opt-out line. The engine then failed two kinds
  of access: the latches' dictionary is iterated with a loop variable declared `Variant`, and the
  bus is typed through a preload of its script (`event_bus.gd`), so its two signals are emitted
  as before and a misspelt name fails the parse.
- `tools/field_reads.txt` lost 16 lines and gained none.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `origin/main` and on the builder's commit `c15e5cefa`: what every source charges her
tick by tick (`probes/excitement_fingerprint.gd`, its `XF` lines less `XF_COST`), and every event,
crowd agent and baby meter on every tick (`probes/m159_tick_sweep_events_cost.gd`, the `chain`
values). The commits after it change no answer and the probes were not run again: the bus is the
same object reached through a typed name, the deleted identity check's branch never ran, and the
rest is comments and a deleted test.

## Choices the builder made where the design was silent, open to the player's overturn

- **All four of the doors' reads of `obstructs_radius` ask `solid_reach()`**: the boom's reach
  across the carriageway, the clearance a release waits for, the reach at which a line is crossed
  and the hut wall the guard steps out at each mean where her centre comes to rest against the
  body, none ground closed to routes. The door rows are point shapes, so no number moved.
- **`counts_as_one_barrier()` and `solid_reach()` stand on the live event as well as the row**,
  since the design's first rule lets no caller write `instance.row().x()`.
- **`raise_its_guards_hand(on)` takes a yes or no**, where the design's fourth rule prefers a
  change told as what happened: the controller sets it every frame, so it is a frame's state.
- **The watch's table is keyed by the instance's id.** Records of gone instances are let go at the
  end of each tick, after the open encounters are closed, and the table is cleared at the end of
  the day.

## Tried and replaced

- **A check that a record names the instance asked**, on the brief's premise that an instance's
  id is reused once a node is freed. The review made and freed 200,000 nodes on the project's
  engine and saw no id twice, so the check had nothing to catch and was deleted.
- **The bus signalled by name** (`emit_signal`), the first answer to the engine failing a signal
  read off a plain `Node`: a misspelt name then parsed and failed only when the line ran. The
  preloaded type replaced it.
- **A new check in `tests/test_encounters.gd`** that an event made after a freed one starts its own
  encounter: it passed under the mutation it named, since the freed event's record is closed in
  the same tick. It was deleted.

## What stays public, and who still reads it

`def`, `excitement`, `is_finished` and `is_leaving` of the live event are read across the events
folder, the resistance, the dev tools, the day director and the tests; `guard_warns_her` by the
looks and the tests; the row's `barrier_structure` by the event manager, the catalogue and the
tests. Each goes private in the step that converts its last reader.

## Held by a test

No check is added. That two events are two encounters is held by
`_test_two_instances_are_two_encounters` in `tests/test_encounters.gd`; the table's letting go and
its clearing at the day's end have no behaviour a test can see, in a state the game can reach,
without reading private state. The
new questions are one-line forwards and are held through the suites of the doors, the holds and
the encounters.
