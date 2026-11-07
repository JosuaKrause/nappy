# minty-quail — The classes that took a whole City take only what they read: DayStreets, CityFronts and the hand-ins · 2026-11-07


minty-quail's `city-hand-ins.md`: the first two of its three pull requests, DayStreets (#1166) and
the hand-ins (#1187), on the design the player approved in #1166's description (inbox #1172 in
gray-dolphin, inbox #1173 in gray-dolphin). Behaviour is unchanged by both.

**Built.**
- **`DayStreets`** (`src/city/day_streets.gd`, #1166): today's route tree, region plan, closures and
  siting region, as dawn left them, move off `City` into an object the city writes at dawn
  (`begin_day()`, `replace_region_plan()`) and hands out through `City.streets()`. Every caller
  reads `city.streets().<question>()`. The run log's observer reads the day's tree from it and
  grows none of its own: the two trees were the same on 70 of 70 days checked.
- **`CityFronts`** (`src/city/city_fronts.gd`, #1187): the fronts the story changes (the burnt
  frontage, the way in behind, the present block, the neighbor's boarded window, the sealed home
  door) move off `City`. It is built by `CityFronts.over(...)` from the buildings, the home door,
  the door's x-span, the map, the run and the trace.
- **The hand-ins** (#1187): the resistance director, its happenings, day 12's park cordon, the
  crowd and the run log's observer are each handed the parts they read (the map, `DayStreets`,
  `CityFronts`, the event manager as itself, the navigator, the siting) instead of a `City`.
  `is_calm_zone()` moves onto `CityMap`. The generator's street pass moves into `StreetLayout`.
  `tests/fixtures/street_map.gd` writes small test maps, first used by
  `tests/test_navigator_fallbacks.gd`. The raid's sealed door is tested on `FakeEventManager` and
  `FakeCityFronts` in `tests/test_resistance_happenings.gd`.
- **Measured** (#1187's "How it was verified"): the four placement fingerprint probes are identical
  before and after; the run logs of 15 route-rig boots (seeds 1, 7, 42, 1234 and 99991, days 3,
  10 and 12) match main line for line, apart from the frame-timing noise main shows against itself.

**Rejected.**
- **A narrow base class above `EventManager`** (`DayEventsFace`, 19 members with doing-nothing
  defaults): every new public member would be declared twice, and its consumers each read a
  different part. The event manager is handed as itself (inbox #1173 in gray-dolphin).
- **An inner class `City.Fronts`** forwarding five calls back into `City`: a smaller diff, but a
  layer of forwarders (inbox #1173 in gray-dolphin).
- **Callables instead of `DayStreets`** (`city.region_plan` handed as a function): no object to
  name, and untyped hand-ins (inbox #1173 in gray-dolphin).
- **Fakes written ahead of their first consumer:** a fake with no reader is dead weight, so only
  the two the raid's test uses are built, each holding only what that check reads (inbox #1172 in
  gray-dolphin).

**Open to overturn** (the builders' choices where the design was silent):
- the director's atlas comes through `use_atlas()`, which `main` calls and the suites do not;
- `RunSession.watch_day()` keeps taking the `City`, for the city's three summary lines;
- `StreetMap.within(blocks)` is not built until something reads it;
- the moved happenings case lives in a new suite named for its module;
- each guard asks after the part its code reads, not "is there a city";
- the two fallbacks that grew a route tree with none handed in are #1187's to keep or delete, as
  its description says.
