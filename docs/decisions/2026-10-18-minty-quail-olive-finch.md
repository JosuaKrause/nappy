# minty-quail — Where she is is one object, told once a tick and handed to every live event and its behaviours (minty-quail, the events' interface) · 2026-11-10


**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin); a
fact derived once and handed around (inbox #1156 in gray-dolphin). The step "a live event's
behaviours ask it through one interface" of the events' interface design
(`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as seven pull requests,
a cut the orchestrator's planning agent made and no tracked file holds; this is the one that moves
where she is.

## What was built

- **`WhereSheIs`** (`src/events/where_she_is.gd`), an object with no public field: her position,
  her pram's, the camera's view, whether she runs, whether the baby is awake, whether a district
  door's hold has her. It answers `at()`, `pram_at()`, `view()`, `is_running()`, `baby_is_awake()`
  and `is_held_at_a_door()`, and is told the tick's whole word in one call, `tell(...)`.
- **The event manager tells it once a tick**, in place of six writes into every live event; the
  events' world holds it. The spawner hands it to each live event at `setup()`, and the live event
  hands it to its behaviours, to the barrier's far guard and to its excitement source.
- **The six fields are gone from the live event** (`player_at`, `pram_at`, `player_view`,
  `player_running`, `baby_awake`, `she_is_held`), with every reader and writer: the live event, its
  behaviours, its excitement source, the checkpoint controller's run-log line, the look of the
  waiting robber (one new question of the live event, `sight_line_to_her()`), the officers let out
  of a car (`see_her_at()`), and the tests.
- **The tests**: 53 files. A test hands its event a `WhereSheIs` the way the spawner does and
  tells it where she is. One script, kept in the pull request's description, rewrote the writes it
  could by pattern; the rest was done by hand. No member was added for a test.
- **Typing.** `src/events/event_instance.gd` lost its opt-out line; two calls then failed and go
  through a typed name.
- `tools/field_reads.txt` lost 23 lines and gained none.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `origin/main` and on the commit that changed the code (`96e6ec716`): what every source
charges her tick by tick (`probes/excitement_fingerprint.gd`, its `XF` lines less `XF_COST`), and
every event, crowd agent and baby meter on every tick (`probes/m159_tick_sweep_events_cost.gd`, the
`chain` values). The commits after it change tests and docs only.

## The handle, and why

One shared object knows where she is before each event's own fields did. To keep today's answers,
each live event hears the shared object through a handle of its own:

- an event made after the tick's word knows nothing of her until the next word;
- an officer let out after the word is told her position, and none of the other five facts until
  the next word;
- a notice's point goes to that event's handle, as the officer's does;
- the halo's word once a drawn frame goes to the lit event's handle only;
- with nobody in the world nothing is told, and every handle keeps the last word.

The handle's state (a count of words heard and the point it saw) exists only to keep that timing.
The checkpoint controller reads the world's object where it read the nearest door's copy; the two
always agree, since the huts are streamed in before the word and the doors are checked after it.

## Answers found slightly wrong today, and kept

Each is made correct in a pull request of its own (inbox #1278 in olive-ferret), and the design's
list of such answers holds them:

- a car made after the tick's word puts its body down at once even where she stands, though its
  comment promises it holds the body back round her;
- an officer's first frames know only her position;
- the halo's point reaches only the events it lights.

## Choices the builder made where the design was silent, open to the player's overturn

- **The handle per live event**, above. The design says the manager writes the object once a tick
  and every event is handed it, and nothing of the timings.
- **The halo's point goes to the event's handle, not to the shared object**, which differs from the
  design's sentence that it "goes to the same object": the shared object would tell every event.
- **`tell()` defaults its five facts after her position** to what "nowhere" answers, so a test can
  tell her position alone.
- **The object lives in the events' world** (`EventWorld.where_she_is()`).
- **The excitement source is handed it by `use_where_she_is()`.**
- **The names `see_her_at()` and `sight_line_to_her()`.**
- **The checkpoint controller reads the world's object.**

## Test checks restated or deleted

Three checks only read a field back after writing it. `test_event_parts`' told and untold checks
ask which side of the robber a man gets out on, which turns toward her once he knows where she is;
`test_excitement_source`'s halo check asks the caret measured from the halo's point;
`test_event_views`' check that a rig with no player has no position was deleted, the check after
it holding the waiting posture's own facing. Two distance checks in `test_resistance_steps` that
the script had turned into reads of an untold object ask the point the test set through the halo.
