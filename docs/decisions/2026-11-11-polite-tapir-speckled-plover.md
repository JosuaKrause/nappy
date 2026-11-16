# polite-tapir — The events and the resistance report on a bus they are handed · 2026-11-16


**The ask.** A component is handed what it depends on rather than fetching it from an autoload
(minty-lemur #794), and the listed layer breaks are not forgotten (inbox #1268 in olive-ferret).
**Read as:** the refactor does not close while a listed layer break has no decision behind it,
which is how `standing-layer-breaks.md` files it, the orchestrator's reading. The signal-bus group of the standing layer breaks was the
simulation reporting on the global `EventBus` autoload: the baby, the crowd, the poster walls and
the blackout were already handed it, and the events and the resistance still fetched it. The
queue item's text said each remaining emitter copies the baby's shape: a nullable bus typed by the
preloaded script, `use_bus()`, and one guarded teller per signal in each file. **That reading was
the orchestrator's, never the player's, and it is open to the player's overturn** (choice 1).

**Who did what.** A Fable agent designed the pull request and prototyped its `src/` change, and the
coding was handed off (inbox #1432 in minty-rabbit). Opus built it; Fable reviewed it.

## What was built

- **`EventReports`** (`src/events/event_reports.gd`, simulation layer): the one place a day's
  events say what happened. It holds the bus, which may be null, behind `use_bus()`, and has one
  guarded teller per signal the events send (nineteen), each named `tell_` plus the signal's own
  name. `EventWorld` makes one for its whole life and answers it from `reports()`. The manager, the
  spawner, `EventsAhead` and the checkpoint doors' controller ask the world for it; `EncounterWatch`,
  each live event (`EventInstance.new(reports)`, built in `EventSpawner.create()`) and its
  `ChargeRecord` are handed it in their constructors. A live event made by hand gets a silent one.
- **`EventManager.use_bus(bus)`** is the events' one hand-in. It passes the bus to `world.reports()`
  and connects the manager's own listen for `return_phase_started` (the baby falls asleep, so the
  return leg's patrols are owed), which `setup()` used to do. `SimulationBuilder._new_events()`
  calls it for every manager it makes, the city's and the building's; the building's manager hears
  the baby fall asleep and ignores it. `CheckpointController` lost its `bus` constructor parameter,
  and `ChargeRecord` takes an `EventReports` in its place.
- **The resistance copies the baby's shape, along the chain `use_trace()` already follows.** `main`
  calls `_resistance.use_bus(EventBus)`; `ResistanceDirector.use_bus()` hands it to its happenings,
  and `ResistanceHappenings.take_the_park()` hands it to the park cordon. The director has two
  tellers (`_tell_a_contact_is_on_offer()`, `_tell_the_mark_was_seen()`), and the cordon says
  `hard_fail_triggered` only if it was handed a bus. The happenings keep no hand-in for a cordon
  already standing, since `main` hands the director its bus before any cordon exists.
- **The layer map's whole `EventBus` entry is deleted**, and `docs/ARCHITECTURE.md` says who is
  handed the bus.
- **Checks**, each failing with its `src/` line removed, the new ones listening on a recording bus
  of their own and the resistance's hand-ons held by the existing booted check on the autoload: the builder's hand-in for both worlds (`test_simulation_builder`), `event_lit_unmet`
  (`test_event_manager_fire`), `player_detained` (`test_events_chat`), every teller
  (`test_event_reports`, its table checked against the class's own `tell_` methods), the director's
  two tellers (`test_resistance_replacement`), and the three hand-ons of the resistance's chain
  (`test_park_return`, the existing booted check `_test_shut_in_with_the_baby_asleep`, where `main`
  hands the director the autoload; 14 checks fail with any one removed). Existing suites that make an emitter by
  hand hand it the autoload through the fixture `tests/fixtures/told_events.gd` and keep their
  listening lines.

## What was measured

- **`check_layers.py --list`: 67 findings before, 46 after**, 0 unlisted, 25 listed exceptions
  left; no file the change touches has a listed break left. The 21 uses behind the deleted entry
  are 5 in `encounter_watch.gd`, 3 in `event_instance.gd`, 4 in `event_manager.gd`, 4 in
  `event_spawner.gd`, 2 in `events_ahead.gd`, 2 in `resistance_director.gd` and 1 in
  `park_cordon.gd`.
- **Nothing the player sees changed.** The three fingerprint probes print identical lines before
  and after: `director_placement_fingerprint` (2,359 lines), `excitement_fingerprint` (19,512 lines,
  its timing line left out) and `trap_arrival_fingerprint` (1,035 lines).
- **The boots** (`--no-title --walk 4s`, `--start-escape`, `--start-escape city`) ran headless with
  no script error or warning. The full suite ran with 0 failures; one shard hit its timeout on an
  overloaded machine and its cut-off suites were run by name.
- **No signal is lost or duplicated**: 25 emit sites in nine files before and after, 21 distinct
  signals, 22 teller call sites over 19 tellers plus the director's two and the cordon's one.

## Options not taken

- **`use_bus()` on each part, the baby's shape seven times** (the manager, the watch, the spawner,
  `EventsAhead`, the live event, its record and the doors' controller). The manager would forward
  the bus to four parts by hand and the spawner to every instance it makes, each line one whose omission mutes a part
  silently. `CheckpointController` and `ChargeRecord` would lose constructor injection for a setter
  and a guard on every emit, since they are built before a bus can be handed in. A live event made
  before the hand-in would never hear of the bus. And "is there a bus" would be decided in seven
  places, where designing-classes wants a fact derived once.
- **The tellers on `EventWorld` itself.** Three of the seven emitters are not handed the world:
  `EncounterWatch` takes everything in `tick()`, `EventInstance` is handed pieces and never the
  world, and `ChargeRecord` knows only a name. They would need the whole world, which widens what an instance depends on from a point to
  everything the manager has, and puts nineteen tellers on a class every part receives for its map,
  run and player.
- **A teller named exactly as its signal.** `tools/check_field_reads.py` takes `_bus.hard_fail_triggered`
  for a method read without its parentheses once a class declares a method of that name, so the
  prototype failed in 21 places; the `tell_` prefix collides with nothing.
- **The park cordon telling its owner by a signal of its own**, and **sharing one object between
  the director and the cordon**: both add a mechanism to carry three signals across three classes,
  where the baby's shape along the trace's chain adds none.
- **The builder connecting the manager's `return_phase_started` listen** to a public
  `EventManager.owe_the_return()`. That makes the manager a pure sender and puts one more line of
  wiring in every rig that plays a return leg.
- **Converting every listening suite to a recording bus of its own**, the stricter reading of
  writing-tests: it changes every listening line as well as the line that makes the emitter. Only
  the new checks use one.
- **A manager that disconnects a first bus when handed a second**: a branch only a test could reach.
- **Two pull requests, one for the events and one for the resistance.** They share the one layer-map
  entry, the rigs that stand in for `main` and the suites that listen to both.

## Choices open to the player

1. **`EventReports` in front of the bus, rather than the baby's shape on each part.** The removed
   queue text held the orchestrator's reading that each emitter copies the baby's shape. The player
   did not say it, and it is open to their overturn. The manager's own boundary keeps the shape
   (`use_bus()`, the preloaded script as its type, silence with none); its parts cannot, since they
   are built in `EventManager._init()` before a bus can be handed in. **The costs:** each signal the
   events send is written three times (on the bus, as a teller, and as a row of
   `test_event_reports`' table), and the resistance keeps the baby's shape, so two shapes do one
   job, with three guards in two files.
2. **The name `EventReports` and the `tell_` prefix.**
3. **A live event takes its reports in its constructor with a silent default**, rather than through
   a hand-in after `new()` (its charge record is built at construction and needs them then). The
   cost: an `EventInstance.new()` made without `world.reports()` reports to nobody and nothing says
   so, because the layer check finds a fetch and not a missing hand-in. Today `EventSpawner.create()`
   is the one such place, and two checks hold it. A required parameter would find the next one at
   the parse, at the price of every bare `EventInstance.new()` in the suites taking a reports
   object or a fixture.
4. **The manager keeps its own `return_phase_started` listen, connected in `use_bus()`.**
5. **A manager is handed one bus for its life.**
6. **Existing suites hand the autoload and keep their listening lines.**
7. **One pull request for the events and the resistance.**
8. **The resistance copies the baby's shape along the trace's chain** (`main` to the director, the
   director to its happenings, the happenings to the park cordon), rather than sharing one object
   or having the cordon tell its owner by a signal of its own. The alternatives and their reason
   are under "Options not taken".
