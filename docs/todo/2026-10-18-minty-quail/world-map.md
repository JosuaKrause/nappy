# One world interface; the building runs on the day's event manager

The building and the city share no map interface. `InteriorScene` duck-types `tile_to_world`,
`world_to_tile`, `is_walkable` and `add_entity` (`interior_scene.gd` near 574-580 and 758) and builds
a fake `CityMap` of sidewalk and building tiles to borrow `wall_between` (`wall_grid()`).
`InteriorEvents` (`src/finale/interior_events.gd`, 547 lines) is a second `EventManager`, "deliberately
not an `EventManager`" (`docs/decisions/2026-09-12-M102-the-finale-built-behind-the-flag.md`): own
spawn, retire, `_tell_them_where_she_is`, `_check_hard_fails`, and none of the manager's
`player_view`, `pram_at`, `she_is_held`, `outranked_by_a_stronger_barrier`, `_struck_by` (so no loss
cause), pending warnings, detentions, encounter watch or frame timing. It gives `EventInstance` no
map, and with `_map` null its navigator lets anything step through walls and `_clear_line_to` is
always true (`event_instance.gd` near 1341, 2173, 2877, 3138, 3229, 4765, 6762, 7272). It scripts in
code what should be data: the fire as an `EventDef` mutated in code (`_indoor_fire`), vents on
`Tuning.FINALE_STEAM_PERIODS` timers, the masked man's respawn timer, the explosion beat at her own
position; `_without_its_aftermath` exists twice (here and `event_scheduler.gd` near 1023).
`EventManager` keeps escape branches (`_walking_the_finale`, `start_finale`, `start_recipe(finale)`).
The baby is handed her world by `main` (`Baby.set_world()`, downy-tapir's fix), and `WorldContext`
still joins a `world` group nothing reads any more; this item makes the world an
injected dependency everywhere. `CityMap.index_posts()` calls `City.bollard_positions()`, the data
layer reaching into the scene; `CrowdAgent` reads `City.OUTSIDE_DEPTH_TILES`; `world_to_tile` is
written four times.

**Build:** a `WorldMap` interface (tile conversions, `passable`, `clear_line`, `wall_between`,
`path`/`step` through the navigator, `add_entity(node, layer)`, `process_player`, `slope_dir_at`),
implemented by the city and the building and injected into `EventManager`, `EventInstance`, the baby,
the stroller and the run log; no null-map branches. The building is hosted by the day's
`EventManager` with authored placements (the player allows the building its own *what and where*,
minty-lemur #785) and a general `EventDef` repeat period for the vents and the masked man; the fire is
a catalogue row. `InteriorEvents` and `EventInstance._walls`/`set_walls` go; `EventManager`'s escape
branches become spec settings (whether a return leg is owed, poster pursuits). Pure geometry moves
into the map; the scene reads it.
