# minty-quail — The event manager is handed the day's streets, the lights, the run and the poster walls · 2026-11-11

**The ask.** The city scene is no longer handed whole to whoever reads a few of its parts: each
consumer is handed what it reads (`city-hand-ins.md`, on the design in #1166's description,
inbox #1173 in gray-dolphin), and the third step is cut into several pull requests (inbox #1381, the
player's yes on the board's hand-ins-third-cut). This one is the event manager's own city and the
day planner's fallback that grows a route tree when dawn grew none.

## What was built

- **`EventManager.setup()` takes the map, the day's streets (`DayStreets`), the lights
  (`TrafficSignals`), the run, the navigator, the spawn siting and the poster walls**; `City.build()`
  hands them in its one call. `EventWorld.city` is gone: the streets and the poster walls are
  underscore fields of the world behind `streets()` and `poster_walls()`. No `City` is named in
  `event_manager.gd`, `event_world.gd`, `day_planner.gd` or `events_ahead.gd`.
- **The day planner plans against the streets it is handed**, and its two fallbacks (a grown route
  tree, a grown region plan) are deleted: no game path reached them. The poster walls' fronts are
  asked when a siting is made, never copied at setup. The map's world is the caller's to set before
  setup.
- **Every rig that started the manager's day with no city dawn begins a `DayStreets` with what the
  fallback grew**, through one helper (`tests/fixtures/rig_streets.gd`): the event manager rig, the
  fire, masts, pursuer-on-foot, encounters, resistance placement, run config and street-events suites,
  the escape city's rig, and three probes. They were found by reading and confirmed by a temporary
  error on a null tree over the 78 suites that start a manager's day (none fired; removing one rig's
  streets made it fire). The escape city rig's three repeated `setup()` calls, which only swapped in
  equal parts, are deleted.
- **The event manager's suite holds** that a day started through the manager is planned on the tree,
  the closures and the region plan its streets hold: the dawn's own wall and door bodies are among
  the day's plans, which a region plan grown again from the same tree fails ("0 of 98").
- **`setup()` connects to the return phase plainly**: no caller sets one manager up twice, so its
  connect-once guard is gone, and `tools/layer_map.py` counts four `EventBus` uses in
  `event_manager.gd`, one fewer.
- **`tools/field_reads.txt` loses six lines** (`[EventWorld]` `city` three times, `[City]` `run` and
  `signals` for the manager, `[WorldMap]` `world` for the manager) and gains none.

## Choices open to overturn

- **The scheduler's own fallback stays** (`build_day()` growing a route when handed none): 37 calls
  in 16 test files reach it, so it goes with `DawnContext`'s shared test helper, which departs from the
  item's sentence that it goes with the day planner's (the planner's); `scheduler-breakup.md` now says
  so.
- **`setup_world()`, the building's entry, keeps its signature** (the planner's), and `use_run()`
  stays for the two suites that call it without `setup()`.
- **Only the streets and the poster walls go behind methods**; the lights and the run stay the fields
  they were, read about a hundred times in files outside this cut (the builder's).

## Left, each with its reason

- **A third grown tree** in the events ahead (`rig_her_route()` growing a tree when the manager has
  planned no day) stays: no game path reaches it, only a scene recipe's walk on a fresh manager or a
  rig. No item names it.

## Verified

At parity: the placement fingerprint over every placement a walk starts with hashes the same on the
base and the head; the run log matches its recording; the suites that load a changed rig pass, and
the shared checks.
