# minty-quail — One world interface; the building runs on the day's event manager · 2026-10-24


minty-quail's `world-map.md`, the refactor's seventh PR (PR #835). The building and the city shared
no map interface: `InteriorScene` duck-typed the city's tile calls and built a fake `CityMap` of
sidewalk and building tiles to borrow its wall check; `InteriorEvents` (`src/finale/interior_events.gd`)
was a second event manager with its own spawn, retire and hard fails and none of the day's view, loss
cause, warnings or encounter watch; it gave `EventInstance` no map, so with `_map` null anything
stepped through walls and every line was clear; the fire, the vents' timers, the masked man's respawn
and the explosion beat were scripted in code; `EventManager` kept escape branches; `CityMap` called
up into `City` for its posts.

**Built** (`src/world/world_map.gd`). `WorldMap` is the one map interface, implemented by the city's
`CityMap` and the building's `InteriorMapPlan`: tile conversions written once, passability, line of
sight and wall depth (the line and wall code moved verbatim from `CityMap`), the blocked record, the
navigator's `path()`/`step()`, `add_entity()` and `process_player()` through the world node that
draws the map (its `world` field), `slope_dir_at()`, and street questions that answer "no street
here" on a map without streets. Open ground is `WorldMap.open_ground()`, so no null-map branch is
left in `EventInstance`, `Navigator` or `EventManager`. The map is injected: `EventManager.setup()`
for the city and `setup_world()` for the building, `EventInstance.setup(..., map)`,
`Stroller.set_map()` in place of the slope callable, the baby through `Baby.set_world(map.world)`,
and the run log through `watch_building(map, …)`; `main` asks the current world's map
`process_player()` every walking frame. `InteriorEvents`, `EventInstance._walls`/`set_walls`, the
scene's fake wall grid and the `world` group are gone; the building's pure geometry (flight bands,
walks, waypoints, vent sites, door transitions) lives in `InteriorMapPlan` and the scene reads it;
the post positions, `BOLLARD_SPACING` and `OUTSIDE_DEPTH_TILES` live on `CityMap`.

The building runs on the day's own `EventManager`. Its placements are `BuildingPlan.plan(map, seed)`,
so it keeps its own what and where (minty-lemur #785). Two general row fields repeat a row:
`EventDef.repeat_every`, start to start, and `repeat_after`, from done to the next; each plan carries
its own copy, so each vent sets its own period. A plan can be sited where she stands (`at_her`),
which is how the explosion outside is placed. The fire and the explosion are catalogue rows
(`EventCatalogue.building_fire()`, `explosion_outside()`), their ids unchanged;
`EventDef.from_outside` means no wall stops the field and the world shows the bang
(`WorldContext.bang_outside()`, the window flash). `without_its_aftermath()` exists once, in the
catalogue. The escape's flags are spec settings (`DaySpec.owes_a_return`, `DaySpec.poster_pursuits`)
the run flow hands in: `main` hands each day's spec to `EventManager.use_the_spec()` before
`start_day()`, a recipe's runtime hands its spec to `start_recipe(plans, spec, day, focus)`, and
`start_finale()` is `start_planned(spec, plans, focus)`. The distant window flashes are the
scene's own night, and the grates are laid once per boot.

**Two content losses the plain map caused, fixed rather than accepted.** On the building's tile map
the masked man slid at every flight corner and left his route halfway up the shaft, so walkers got
through on lines where a walker must be caught (inbox #764 in minty-lemur); steps beside a flight are
now checked against the same band-cut blockers her body collides with
(`InteriorMapPlan._ground_stops`), and his run matches open ground frame for frame, only his exit
after it changing to walkable ground. The basement mouse's dash was trimmed to nothing; the
building's one-tile passages now answer the alley question (`InteriorMapPlan.alley_at`), so it darts
across its passage wall to wall.

**Verified at test parity** (inbox #813 in curly-moose): `check.sh`, `lint.sh`,
`ci_telemetry_kinds.py` and about 45 suites with 0 failures, the full suite on CI. Tests changed only
as far as the code moved: the building's events are built through `tests/building_events.gd` and a
vent is its plan; a restart leaves the grates lying; the far flashes are asserted on the scene; static
helpers that took a null map take open ground; `start_planned`, `test_pursuer_on_foot` and
`test_scene_recipe_task` are handed the spec. `test_wall_shield`'s indoor wall check is dropped: on
the building's own map the wall answer is its walkability by definition, and nothing independent of
it is left to compare with. New tests: a catch in the building ends the section through the day's hard fail and
`what_struck_her()` names the masked man; he never stands off the building's floor; the mouse dashes
across its passage; a chatting mother streamed out while leaving does not come back, which answers
`likely-bugs.md`'s suspicion that she would (her chat ends with her leaving, and that plan is spent);
on the same day a day's spec is owed its return rows and a spec that owes none is owed none; the
debug fields layer cuts a row from outside at no wall; a bang from outside that comes once lights the
windows.

**Choices made where the design was silent, open to overturn:** each map reaches the node that draws
it through a `world` field that node hands over; `has_ground()` is the one question the navigator and
the line walk ask about open ground; the repeat is two fields because the vents and the masked man
repeat differently, and `basement_steam` carries no period of its own; `from_outside` is one field
for both "no wall stops it" and "the world shows it"; a manager with no city has no director, so
nothing is sited ahead of her in the building, and `_city_map` is kept apart from `_map`; the
building keeps its whole plan live (`stream_radius = INF`); the baby still takes a `WorldContext`,
since those are the questions it asks; the run log keeps its city-only watchers and asks the world
map for tiles.

**Left for later items:** `CityMap`, a layer-2 map, implements the layer-3 interface and holds its
world node, so it calls up into `City` through `world` (one upward call removed, this one added),
where a separate city facade is the alternative; `EventManager` still holds the city's
planning half (director, warnings, masts) beside the hosting half, `events-composed.md`'s split;
`_find_player()` still fetches her from the `player` group, `InteriorScene` like `City` sums its
events for the baby, and `BuildingPlan.lay_the_grates()` reads `EventInstance.steam_grate()`;
`comments.md` is applied to the code this PR wrote only; the `_drive`/`_timed` replay bug stays with
`events-composed.md`.

**For the remeasuring step:** the masked man leaves round the walls rather than through them; the
mouse's dash is 27px wall to wall (64px through both walls before); the fire's body and a blowing
vent's body go on the building's blocked record; the building now has the mark over her head near
the masked man, the encounter watch (GoatCounter counts the building's encounters under day 15, the event
names unchanged, so each explosion outside, about eight a section, counts as an encounter, sent as
`nappy-day-15-influenced-unseen-finale-explosion` when it reaches her unseen; the old building
sent no encounter events, and the escape's city section counts its own explosions under day 16,
`DaySpec.CITY_DAY`), `FrameRecord.EVENTS` timing, and the screen-edge badge read from the manager's view; the
explosions keep an exact 22s period, where they slipped up to a frame per bang; the grates persist
through a retry. No city behaviour is meant to change. Pictures of the masked man leaving the top of
the shaft, the mouse's dash, and the mark in the stairwell.
