# minty-quail — The telemetry observer's suite builds no city · 2026-11-07

minty-quail's `tests-one-module.md`, its first module, in #1198: each suite tests its one module
with everything else mocked, and the city is never built for a test that does not test the city
(inbox #1159 and #1156 in gray-dolphin).

**Built.**
- **`tests/test_telemetry_observer.gd` builds no `City`** and never generates one but in one case.
  The observer is handed a `RunState`, a map, a suite-local `StandInEvents` (a `FakeEventManager`
  whose `plans()` answers the plans a case places, each live where placed), `DayStreets.new()`
  (no tree, no closures) and the base `ExcitementSources` (nothing).
- **Maps:** the escape, lost-day trail and met-events cases use `StreetMap.full()`, the first
  sidewalk tile standing in for the doorstep. The case that plans day 4 beside the observer keeps a
  generated map from `CityMapCache.of(4242)`, with no `City` node, and stays combined: only the
  planner's input shows the watchers left the map unchanged; its header says so.
- **Moved or dropped:** the `plan.was_live` check is the event manager's answer and
  `test_event_manager_fire` holds it, so it went; the three "day 3 places something sited" guards
  went, since a stand-in always places a plan (36 checks to 32).
- **Measured:** the suite ran 12301 ms before and 11161 ms after, locally, one run each; what is
  left is the real physics frames its held-key and no-touch cases are about.

**Choices where the design was silent, open to overturn:** `StandInEvents` stays in the suite
rather than in `tests/fake_event_manager.gd`, since only this suite answers `plans()`; the no-touch
case keeps a real generated map rather than a fake.

**The survey** of the suites that build a city, plan a day or boot `main`, by module, is in #1198's
description; the item's file holds the order it gives the remaining modules.
