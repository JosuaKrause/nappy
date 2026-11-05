# minty-quail — The event suites put events into play and take them out through the event manager (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, section 2.1's rows other than the checkpoint suite's and
section 2.2's sites in the same files: no test writes the event manager's live list, and these
files write no `EventWorld` field. Tests only; no `src/` change.

**Built.**
- `test_encounters.gd`, `test_events_chat.gd`, `test_halo.gd`, `test_danger.gd` and
  `test_drawn_view.gd` make their events with `spawn_extra()` on a manager handed
  `setup_world(map, run)`, over open ground drawn in a `WorldContext` the suite holds, and remove them
  with `clear()`, or `retire()` and the streaming's own sweep of finished events.
- `test_day_director.gd`'s two riders come from `spawn_extra()` and `spawn_warned(def, path, true)`,
  with a check that the second is the pelican, where the test set the flag by hand before.
- `test_event_parts.gd` uses the manager's own streaming, spawner and warnings over a world handed in
  through `setup_world()`, `use_player()` and `use_run()`, its post a `Planned` streamed in.
- `test_events_pursuit.gd` builds its manager through `setup()` and `use_run()`, sets `trace` on the
  manager, and makes the arriving cyclist with `spawn_warned()`, as the game's arrival does.
- `test_resistance_arrow.gd` retires its event through the manager.
- `tests/finale_rig.gd`'s lured-off band is an escape roadblock plan streamed into a manager that was
  handed a world, and its charge test makes the masked pursuer with `spawn_extra()` in the booted
  escape.
- Every suite's checks are the same in number and meaning but `test_day_director.gd`'s added one;
  they pass shuffled and repeated, the three finale suites included.

**Open to overturn:** the halo suite's dropped-holder case drops one of its own fake holders rather
than an event, since no game path takes an event out of play without queueing its body and the case
needs a holder that stays alive; the halo and drawn-view suites retire an event and sweep the
streaming's finished events at once, to keep the moment between the physics step and the halo's
pass; `test_events_chat.gd` still hands the baby's world the manager's sources, the hand-in `City`
and `main.gd` make; the suites run on open ground, `test_encounters.gd` keeping its bare `CityMap`.
