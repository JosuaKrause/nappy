# minty-quail — The live event's field asks its row, and its source is handed the row (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
step "the live event's behaviours ask it through `Figure`, and are handed the rest" of the events'
interface design (`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as
seven pull requests, a cut the orchestrator's planning agent made and no tracked file holds; this
is the sixth, built beside the seventh (the live event's body as a part of its own), after the
five whose records are minty-quail-velvet-owl, -olive-finch, -tiny-alpaca, -tawny-swan and
-striped-hawk.

## What was built

- **The live event's section "emission" (`event_instance.gd`) asks its row and reads no field of
  it** the brief named: the swell and the pulse, the field's datum, the notice and its quiet, the
  telegraph, holding still, the hold's seconds and whether it ends the day. Until the field has a
  settings class of its own the row answers under the field part's design names, so the step that
  writes a row as its parts (the design's 4b) changes the receiver and nothing else.
- **The event's excitement source (`EventExcitement`) is handed the row and where she is** when its
  live event is set up (`use_row_and_where_she_is(row, where)`, in place of `use_where_she_is()`),
  asks the row what the field is, and asks its event only what changes: whether it is gone or on
  its way out (`is_gone()`, `is_on_its_way_out()`), its age, where it stands, its rate and course,
  its birds, its body's axis, and for a car whether its course strikes her (the new
  `EventInstance.will_strike(point)`).
- **The hub's read of `def.aftermath.on_finish`** in `_be_done()` asks the row's `leaves_behind()`.
- `tools/field_reads.txt` lost 19 lines and gained none.
- **One suite changed**: `tests/test_prediction_reuse.gd` no longer replaces a live event's row
  after setup, a state the game never reaches now that the source answers from the row it was
  handed; every in-place change it makes to the row still reaches the cache.

## The row's added questions

Each holds the expression it replaced, in the same order, on the same floats; the caller multiplies
or compares the answer where it did the inline expression: `peak_through(age, into_its_burst,
beat)` (the intensity, its ramp over the duration and its pulse, the design's five fields as one
question; `current_intensity()` still multiplies by the notice's damping after), `pulses_every()`
(the pulse's period, for the caret's closed-form mean, which stays the live event's), `datum()`
(the shape the field is measured from, none for a vehicle that measures from its centre; the
design's "three times" now one question), `passes_walls()`, `bird_emission_at(at_distance, share,
outer)` (one bird's falloff, asked by the live flock and the row's own flock price),
`holds_still()`, `waits_for_her()`, `runs_its_own_line()`, `warns_quietly()`, `is_ambient()`,
`drives()` and `leaves_behind()` (the successor's id, or ""). The row's existing `telegraphs_for()`,
`detains_for()` and `ends_the_day()` are asked where the fields were read.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `main` at `bf9798e0f`, the commit this branch was made from, and on the code commit
`207380dc6`: what every source charges her tick by tick (`probes/excitement_fingerprint.gd`, its
`XF` lines less `XF_COST`), and every event, crowd agent and baby meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values). The cost table worked out from the
rows is unchanged (`tools/cost-table.sh --check`).

## A member kept public for the suites, open to the player's overturn

`tools/test_only_members.txt` gains one line in its `[kept]` group, where the brief said the list
gains none: `CrowdSources.silent_beyond()`, the crowd's distance past which its sweep skips a body.
The test-only check counted the source's untyped read `_event.def.silent_beyond()` as a reader of
every method of that name; through the typed row it counts the row's alone, and the crowd's has no
game reader outside its own file. Six lines of `tests/test_crowd_contributions.gd` and
`tests/test_excitement_source.gd` hold that no body's field reaches past it, which nothing outward
shows. The builder's choice, which the orchestrator kept; the plainer alternative is the crowd's
distance made internal and the two crowd suites converted, outside this pull request's files.

## Choices the builder made where the design was silent, open to the player's overturn

- **`peak_through()` takes a third, optional argument, `beat`**, so the caret can project a pulsing
  row at its pulse's mean over the horizon; the alternative, the mean moved into the row, would
  leave `pulses_every()` with no caller.
- **`bird_emission_at()`, `runs_its_own_line()`, `warns_quietly()` and `will_strike()`** are names
  the design does not give: the design names the notice's `runs_within()` and `is_quiet()` on
  `NoticeSpec`, which the live event cannot ask without reading the row's `notice` field, and a
  row method `notice()` cannot exist while the field does.
- **The source is handed the row and where she is by one hand-in at setup, not its constructor**:
  it is made with the live event, before the event has a row, and a suite replaces it in `_init()`.
- **The source still asks its event for its map**, which the brief did not name as handed.

## Reads left, and why

- **`_event.age` in the source**: the design's `age()` cannot be a method while the live event's
  `age` variable stays.
- **The prediction key's copies of the row's values**, read through the handed row each frame,
  since a rig may change a row in place and the prediction suite proves the cache notices each one;
  the key holds the field's spec by reference once a built row cannot change (the design's
  section 6).
- **The pursuit's settings in the section "emission"**: not on the brief's list, and the design's
  names for `warns_for` and `stop_excitement` are the fields' own.
- **Outside the section "emission"** the live event still reads `notice`, `duration`, `shape`,
  `vehicle` and the rest; `counts_a_charge()` writes what the row's `runs_its_own_line()` answers
  and could ask it in the pull request that owns that section.
- **Each row field the two files stopped reading stays public**, since the catalogue, the
  spawner, the scheduler, the looks, the debug layers and others still read it.
