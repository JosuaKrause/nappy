# minty-quail — The checkpoint doors, the events' sources and the encounter watch ask a live event through methods, and the watch keeps its own records (minty-quail, the events' interface) · 2026-11-10


**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
step "a live event's behaviours ask it through one interface" of the events' interface design
(`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as seven pull requests,
a cut the orchestrator's planning agent made and no tracked file holds; this is the one for three
files inside the events folder that are callers of a live event like any caller outside it.

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

## Measured

The per-frame cost, by a separate measuring agent, on `origin/main` (`521439a75`) and on this pull
request at `3d39389a6`, the commit before the review's fixes (which typed the bus, deleted a branch
that never ran and changed comments). Four probes, each run alone, twelve rounds alternated base,
head, head, base, on a machine where other agents were working; the load average is the one-minute
figure before the round. Nothing is concluded from it, no cut is held or tuned for a time (inbox
#1278 in olive-ferret), and the cut is listed for the remeasure at the end of the step.

| Round | Tree | Load | Events' step, ms | Baby's sweep, ms | Halo's frame, ms | Fields, seed 4242, ms | Fields, seed 5551212, ms | Crowd tick, ms (control) |
|---|---|---|---|---|---|---|---|---|
| 1 | base | 6.20 | 14399.0 | 160.5 | 3835.8 | 30.0 | 30.4 | 51929.9 |
| 2 | head | 6.68 | 14560.9 | 147.8 | 3479.2 | 31.8 | 36.1 | 54511.9 |
| 3 | head | 5.83 | 15530.4 | 156.5 | 3595.7 | 40.2 | 36.2 | 46265.8 |
| 4 | base | 3.76 | 13084.5 | 140.0 | 3753.8 | 30.1 | 34.8 | 49955.1 |
| 5 | base | 3.22 | 12686.0 | 137.7 | 3786.7 | 40.1 | 38.0 | 54171.1 |
| 6 | head | 3.59 | 16644.1 | 174.8 | 4366.8 | 46.4 | 42.1 | 63530.7 |
| 7 | head | 6.80 | 15147.4 | 147.2 | 3676.0 | 33.2 | 40.8 | 49401.0 |
| 8 | base | 4.77 | 13181.0 | 140.3 | 3895.6 | 46.6 | 39.4 | 48861.3 |
| 9 | base | 3.83 | 12375.1 | 133.1 | 3622.4 | 30.6 | 30.5 | 51663.9 |
| 10 | head | 5.12 | 14041.8 | 140.7 | 3296.1 | 33.8 | 34.9 | 48361.6 |
| 11 | head | 3.63 | 12890.9 | 130.4 | 3324.3 | 32.8 | 33.7 | 47265.9 |
| 12 | base | 4.15 | 11578.4 | 126.8 | 3222.6 | 30.4 | 31.1 | 43956.0 |
| median | base | | 12885.2 | 138.8 | 3770.2 | 30.5 | 33.0 | 50809.5 |
| median | head | | 14854.2 | 147.5 | 3537.5 | 33.5 | 36.2 | 48881.3 |

The columns: the events' step and the baby's sweep are the totals of
`probes/m159_tick_sweep_events_cost.gd`'s whole-mode lines over its 36 runs; the halo's frame is
the sum of `probes/excitement_fingerprint.gd`'s nine `XF_COST` figures; the fields are
`probes/calm_pelican_fields_layer_cost.gd`'s whole map, cold, for two seeds; the control is
`probes/m159_crowd_tick_cost.gd`'s whole-mode total, a path this pull request does not touch. The
sweep probe's own split-against-whole checks fail on both trees alike (6 of 36), and its timing
lines print regardless.

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
