# Design: polite-tapir's standing layer break — the map interface's world half

Written by Opus in Fable's place (grassy-bison #1560), for Fable's review (the entry grassy-ibis,
Fable reviews the held pull requests). One group of polite-tapir's `standing-layer-breaks.md`:
"The map interface's world half (5 uses in `world_map.gd`): it hands out the navigator and adds
nodes on a draw layer, which follows from the map interface being the model's (inbox #904 in
freckled-moose)", settled as the item says: "split off or declared a permanent exception in
designing-classes".

**Stopped at the design.** The split's readers stand in `src/events/` and `src/resistance/`, which
open pull request #1548 (the beats become rigged marbles, placement step 4's last pull request)
holds, and three of them (`event_manager.gd`, `event_director.gd`, `resistance_director.gd`) are
files #1548 itself changes. The event manager's parts and the hand-off from the spawner to a live
event are row 3b of minty-quail's `event-interface.md`, which waits for #1548. See "The fork" at the
end.

## The break

`uv run python tools/check_layers.py --list`, on `main` at the brief's base:

    listed src/world/world_map.gd:55 [model]: names WorldContext (model names world)
    listed src/world/world_map.gd:431 [model]: names Navigator (model names world)
    listed src/world/world_map.gd:432 [model]: names Navigator (model names world)
    listed src/world/world_map.gd:434 [model]: names Navigator (model names world)
    listed src/world/world_map.gd:497 [model]: names DrawLayer (model names world)

`WorldMap` (`src/world/world_map.gd`) is in the **model** by its own line in `tools/layer_map.py`'s
`FILES`, which is the player's decision (inbox #904 in freckled-moose: of part B, keeping the map
lookup with the city maps in the domain model, "for B let's use the improved variant"). The three
names it uses are the **world**'s: `Navigator` (`src/world/navigator.gd`), `WorldContext`
(`src/world/world_context.gd`, a `Node2D`, the world scene that draws a map) and `DrawLayer`
(`src/world/draw_layer.gd`). The three `Exception_` entries in `tools/layer_map.py` that list them
(`"DrawLayer"`, `"Navigator"`, `"WorldContext"`) list `world_map.gd` alone.

## What the world half is

Every member of `WorldMap` that names, holds or hands out a world-layer thing. Read whole: the rest
of the class (the tile conversions, the ground, the blocked record, the lines, the walls, the street
questions, `slope_dir_at()`, `moves`, `separation`, `day_record_version`) names only the model
and data (`BlockedLayer`, `ProposedMoves`, `SeparationPass`, `Mover`, `Tuning`, `GameEnums`).

| Member | What it is | Names |
|---|---|---|
| `var world: WorldContext` (:55) | the world scene that draws this map, written by that scene as it takes the map (`City.build()`, `InteriorScene.build()`), null for a map no world draws | `WorldContext` |
| `has_world()` (:501) | whether `world` is set and not freed | through `world` |
| `add_entity(node, layer = DrawLayer.Layer.ENTITIES)` (:497) | `world.add_entity(node, layer)`, with no null check | `DrawLayer` |
| `process_player(player, delta)` (:507) | `world.process_player()` when `has_world()`: the building's doors and light | through `world` |
| `var _navigator: WeakRef` (:60) and `navigator()` (:431) | one `Navigator` per map while anything holds it, kept by a weak reference because a navigator holds its map | `Navigator` |
| `step(from, delta, mover)` (:439) | `navigator().step(...)` | through `navigator()` |

Two facts decide the design:

- **A navigator holds nothing but its map.** `src/world/navigator.gd` declares one `var`, `_map`,
  and its constants; every answer is worked out from the map on the ask. So "one navigator per map"
  is sharing, not correctness: two navigators over one map answer every question alike, and the
  weak-reference registry exists only so that a rig's fallback finds the same object.
- **`WorldMap.step()` is unreached.** `rg` finds no caller in `src/`, `tests/` or `tools/` (every
  `.step(` with three arguments is a `Navigator`'s). It goes under "Code nothing reaches is deleted".

## Who reads it

Production readers (`src/`), with the layer of each file and who holds it now:

| Reader | What it asks | Layer | Fence |
|---|---|---|---|
| `src/city/city.gd:302-303` (`build()`) | writes `map.world = self`; `navigator = map.navigator()` | world | free (#1564 and #1568 edit other lines of the file) |
| `src/interior/interior_scene.gd:215` (`build()`) | writes `_map.world = self` | world | free |
| `src/simulation_builder.gd:102` (`in_the_city()`) | `map.navigator()`, handed to the events and the crowd | root | free |
| `src/main.gd:986` (`_put_her_in()`) | `_baby.set_world(map.world)` | root | free (#1564, #1567 edit other lines) |
| `src/main.gd:2304-2306` | `_world_map().process_player(_player, delta)` | root | free |
| `src/main.gd:1050` | `SteamGrates.lay(..., _interior.map(), ...)`, which adds through the map | root | free |
| `src/crowd/crowd.gd:277` (`setup()`) | `map.navigator()` when handed none | simulation | free |
| `src/events/event_manager.gd:197, 226` | `map.navigator()` in `setup()` (when handed none) and `setup_world()` | simulation | **#1548** (changes the file); row 3b |
| `src/events/event_world.gd:146-149` (`navigator()`) | `map.navigator()` when none was handed or the map changed | simulation | #1548's fence; row 3b |
| `src/events/event_director.gd:191` (`_init()`) | `map.navigator()` when handed none | simulation | **#1548** (changes the file); row 3b |
| `src/events/event_spawner.gd:248` (`create()`) | `world.map.add_entity(instance)` | simulation | #1548's fence; row 3b |
| `src/events/event_spawner.gd:455-456` (`show_the_bang()`) | `world.map.has_world()`, `world.map.world.bang_outside()` | simulation | #1548's fence; row 3b |
| `src/events/event_instance.gd:313` (`setup()`) | `_map.navigator()` when handed none | simulation | #1548's fence; row 2a (built) and 3b's one setup call |
| `src/events/event_instance.gd:1851-1852` (`add_beside_it()`) | `_map.has_world()`, `_map.add_entity(node)` | simulation | #1548's fence |
| `src/events/views/spread_look.gd:305-306` | `event.world_map().has_world()`, `DrawLayer.add_slices(event.world_map().world, ...)` | simulation | #1548's fence; row 2b lists it ("`WorldMap.world`" under "Left listed") |
| `src/events/views/steam_grates.gd:24` (`lay()`) | `map.add_entity(grate, DrawLayer.Layer.GROUND)` | simulation | #1548's fence |
| `src/resistance/resistance_director.gd:323` (`setup()`) | `map.navigator()` when handed none | simulation | **#1548** (changes the file) |
| `src/resistance/happenings.gd:146` (`setup()`) | `map.navigator()` when handed none | simulation | #1548's fence |

`tools/field_reads.txt` lists five readers of `WorldMap`'s field `world`: `city.gd`,
`event_spawner.gd`, `spread_look.gd`, `interior_scene.gd`, `main.gd`.

Tests and probes: 18 suites and rigs write `map.world = holder` before standing an event manager or
an event on the map (`tests/fixtures/street_events.gd`, `escape_roadblock_rig.gd`, `finale_rig.gd`,
`test_halo.gd`, `test_events_pursuit.gd`, `test_event_behaviours.gd`, `test_events_chat.gd`,
`test_day_director.gd`, `test_event_parts.gd` (twice), `test_encounters.gd`, `test_danger.gd`,
`test_checkpoints.gd`, `test_crowd_yields.gd`, `test_simulation_builder.gd` (three),
`test_drawn_view.gd`, `test_draw_layers.gd` (two)); `escape_roadblock_rig.gd:172, 215` saves and
restores the map's world round its own, because the map is shared; five call `map.navigator()`
(`test_world_passability.gd:50`, `test_police_car.gd:585`, `test_way_on.gd:37`,
`test_scene_recipe_runtime.gd:225-226`, `probes/m213_far_end.gd:172`); `test_navigator_fallbacks.gd`
names `WorldMap.navigator()` in its doc; `test_interior.gd:1758` calls `SteamGrates.lay()` with the
building's map.

Docs: `docs/ARCHITECTURE.md`'s "WorldMap" section lists `navigator()`, `add_entity()` and
`process_player()` among the map's questions; the doc comments of `WorldMap`, `Navigator`,
`City.navigator`, `Crowd.setup()`, `EventManager` (:41, :177, :184), `EventWorld` (:13, :74),
`EventInstance` (:251, :1848), `SteamGrates`, `ResistanceDirector.setup()` and
`ResistanceHappenings.setup()` name the map's navigator or its world. No skill names any of it.

## The options

1. **Split it off.** The world half leaves `WorldMap`; whoever builds a world hands its world-layer
   things to whoever needs them, as the crowd, the resistance and the baby are already handed the
   `WorldContext` directly (`Crowd.setup(world, ...)`, `ResistanceDirector.setup(..., world, ...)`,
   `Baby.set_world()`).
2. **Declare it a permanent exception** in designing-classes, with its reason.
3. **Move `Navigator` (and with it the world half's other names) into the model**, a map correction.
4. **Move `WorldMap` into the world.**

## The pick: split it off, handing the two world pieces that already exist

**No new class.** The world half is two things a caller wants, and each already is a world-layer
object of its own: the navigator (`Navigator`) and the world that draws the map (`WorldContext`).
The map stops holding either; the composition root and the world scenes, which already hold both,
hand them on.

### The navigator

- **`WorldMap` loses `navigator()`, `_navigator` and `step()`.** Its class doc stops listing "how to
  get somewhere (through its `navigator()`)".
- **The city keeps building its one** and holding it (`City.navigator`, read by `main` for the
  resistance and by the park-cordon suites): `City.build()` sets `navigator = Navigator.new(map)`.
- **`SimulationBuilder.in_the_city()` is handed it** (a `navigator: Navigator` parameter after
  `map`), and `main.gd:845` passes `_city.navigator`, so the city, its events, its crowd and its
  resistance still move by one object, as `main.gd:481` already hands it to the resistance.
- **The building's**: `EventManager.setup_world()` builds `Navigator.new(map)` where it now asks
  `map.navigator()`. The building's events are the only things that move there.
- **Every rig fallback** (`navigator if navigator else map.navigator()`) becomes
  `navigator if navigator else Navigator.new(map)`: `Crowd.setup()`, `EventManager.setup()`,
  `EventDirector._init()`, `EventInstance.setup()`, `ResistanceDirector.setup()`,
  `ResistanceHappenings.setup()` (`Navigator.new(map) if map else null`), and
  `EventWorld.navigator()`'s re-derivation when its map changed. Since a navigator holds nothing but
  its map, a rig that hands none moves exactly as it does now; what it loses is only that two
  fallbacks over one map are one object, which no code asks.
- `Navigator`'s class doc: "each map builds one (`WorldMap.navigator()`)" becomes "whoever builds a
  world builds one over its map (`City.build()`, `EventManager.setup_world()`)", with the sentence
  that a navigator holds nothing but its map, so two over one map answer alike.

### The world that draws the map

- **`WorldMap` loses `world`, `has_world()`, `add_entity()` and `process_player()`.** Its class doc
  stops listing "how to add something to the world on a draw layer" and `process_player()`;
  `slope_dir_at()` stays (a ground question: the flights).
- **`City.build()` and `InteriorScene.build()` stop writing `map.world = self`.** Each already *is*
  the `WorldContext` (`City extends CityDressing extends WorldContext`, `InteriorScene extends
  WorldContext`), and `SimulationBuilder.in_the_city(world, ...)` and `in_the_building(world, ...)`
  are already handed it.
- **The events are handed the world they are drawn in:**
  - `EventManager.draw_in(world: WorldContext)`, a setter beside `use_player()` and `use_bus()`, which
    hands it to `EventWorld` (`use_drawing(world)`; asked as `drawn_in()`, answering null for none or
    a freed one, which is what `has_world()` answered). `SimulationBuilder` calls it in both
    `in_the_city()` and `in_the_building()` before `setup()`/`setup_world()`. A setter rather than
    a parameter of `setup()`/`setup_world()`, so each test's `map.world = holder` becomes
    `manager.draw_in(holder)` one for one and neither signature moves under #1548 or row 3b.
  - `EventSpawner.create()`: `world.drawn_in().add_entity(instance)` and hands `world.drawn_in()` to
    `EventInstance.setup()` (a last parameter, `drawn_in: WorldContext = null`, after `where`).
    `show_the_bang()`: `var drawn := world.drawn_in()`, then `drawn.bang_outside()` when it is there.
  - `EventInstance` holds it (`_drawn_in`); `add_beside_it()` asks it where it asked
    `_map.has_world()`/`_map.add_entity()`. A new `add_slices_beside_it(slices, feet)` holds the branch
    `SpreadLook._attach_the_slices()` now writes (`DrawLayer.add_slices(world, ..., ENTITIES, self)`
    in a world, `DrawLayer.add_slices_beside(self, ...)` in none), so the look stops reading the map's
    field and asks the event, as row 2b's looks ask for everything else.
  - `SteamGrates.lay(at, world: WorldContext, atlas)`: `world.add_entity(grate, GROUND)`;
    `main.gd:1050` and `test_interior.gd:1758` pass the building (`_interior`, `scene`).
- **`main`**: `_put_her_in(map, world: WorldContext)` hands the baby `world` (callers `main.gd:461`,
  `:1082` pass `_city`, `:1042` passes `_interior`); the walking frame asks
  `_world_drawn().process_player(_player, delta)`, a new `_world_drawn() -> WorldContext` that
  answers as `_world_map()` does (the building on a building day, else the city). The city's
  `process_player()` is the base's no-op, as the map's call reached today.

### What the break list and the field-read list lose

- `tools/layer_map.py`: the three `Exception_` entries `"DrawLayer"`, `"Navigator"` and
  `"WorldContext"` are deleted whole (each lists `world_map.gd` alone): five uses, three exceptions.
  No line is added: `Navigator.new()` in the simulation names the world from above, and
  `WorldContext` in the simulation and the root likewise.
- `tools/field_reads.txt`, under `[WorldMap]`: the five `world` lines go (`city.gd`,
  `event_spawner.gd`, `spread_look.gd`, `interior_scene.gd`, `main.gd`). `main.gd:845`'s new read of
  `_city.navigator` is a further read of a field `main.gd` already reads (`:481`), so no line is
  added; designing-classes' "New code reads no field across objects" makes it `City.navigator()` if
  the reviewer asks, a method the park-cordon suites would take too.
- The pull request shows `rg -P '\.world\b(?!\()' src tests tools` and
  `rg -P '\.navigator\(\)' src tests tools` with every remaining hit and its reason (designing-classes,
  "Every conversion of a field to a method ... shows one search"): `DaySpec.world`, the street
  piece's `world` in `route_line_rule.gd`, `test_invincible.gd`'s rig, `test_scene_recipe_runtime.gd`'s
  named world, and `EventWorld.navigator()` are other classes' members.

### Tests

- Each `map.world = holder` before a manager becomes `manager.draw_in(holder)`; before a bare
  `EventInstance.setup()` (`test_draw_layers.gd`'s `_open_ground_in()`/`_ground_in()`), the holder is
  handed to `setup()` as `drawn_in`. `escape_roadblock_rig.gd` loses its save-and-restore of the
  map's world (`_was_world`), since nothing on the map is left to restore.
- `map.navigator()` in the five suites becomes `Navigator.new(map)` or `city.navigator`.
- `test_world_passability.gd`'s "One navigator per map" case becomes "the city's events move by the
  navigator the city built" (`RunCity.events(city).world.navigator() == city.navigator`), dropping
  `city.map.navigator()`; its doc says a rig's fallback builds an equal one.
- `test_navigator_fallbacks.gd`'s doc: "moves by one over its map (`Navigator.new(map)`)".
- The touched suites by name: `world_passability navigator_fallbacks draw_layers simulation_builder
  events_pursuit event_parts interior escape` and the others above; not a local full run.

### No visible change

The navigator is a pure function of its map, the same `WorldContext` object receives every node in
the same order, and the building's doors are asked by the same object on the same frames. Nothing a
player sees or a run log records changes; no capture.

## Why the split, and not the others

- **The model holds a scene.** The model is "pure state and plans with no scene of their own"
  (designing-classes, the layers); `WorldMap.world` is a `Node2D` held by a model object, and the
  map is how everything that stands in a world reaches that node. That is a fetch through the map,
  where designing-classes asks that "a component is handed what it depends on".
- **The map is a shared mutable slot.** `escape_roadblock_rig.gd` has to save the map's world and
  put it back, because a rig's world written on the map is every reader's world. Handing the world to
  each reader removes the slot.
- **Fields are not API.** `WorldMap.world` is read across objects by five files; an exception would
  still owe their conversion to methods. The split converts them by removing the field.
- **Nothing is invented.** Both pieces exist and three readers (the crowd, the resistance, the baby)
  are already handed the `WorldContext` by their builders. The navigator's registry was serving only
  rig fallbacks, since every production navigator is already handed in.

## Rejected alternatives

1. **A permanent exception in designing-classes.** Its reason would be that the map interface is the
   model's, which explains why the names are upward and not why they must be: every reader can be
   handed the two pieces, as the crowd and the resistance are. It would also keep a model object
   holding a scene node, and the five field reads of `world` would still need methods.
2. **A world-layer bundle** (one object holding the map, its navigator and its world, handed to
   everything that stands in a world in place of `WorldMap`). It keeps "one object handed", which is
   `WorldMap`'s own doc's design, but every reader that needs only the ground (the planners in the
   model, the looks, the field) would carry a world it never asks, and some 30 signatures would change
   from `WorldMap` to the bundle; designing-classes' "would any caller miss" fails for most of them.
3. **Move `Navigator` into the model.** It names `ChaseWay` (`way_to()`, world), so the move
   cascades; and designing-classes' layer list names "the navigator" as the world's. It also leaves
   `WorldContext` and `DrawLayer`.
4. **Move `WorldMap` into the world.** Overturns the player's choice for part B (inbox #904 in
   freckled-moose), and six model files that name the map would break instead.
5. **Hand the events callables** ("add this node on this layer", "show a bang") instead of the
   `WorldContext`. Narrower, but the spawner needs two, the instance and the look a third, and the
   crowd and the resistance are already handed the `WorldContext` for the same service; two styles
   for one service is the divergence designing-classes' "a mode is a configuration" warns of.
6. **Build the part outside #1548's fence now** (the city, the building, the builder, `main`, the
   crowd) and leave the members for the events. None of the five uses leaves until the last reader
   does, and the map would hand out the world two ways meanwhile.

## How it meets the other entries

- **minty-quail `README.md`** ("among them the building's write of `WorldMap.world`, which goes with
  the map interface's world half"): `InteriorScene.build()`'s `_map.world = self` is deleted.
- **polite-tapir `README.md`** ("the building's pass ... takes its one read of `WorldMap.world` with the
  map interface's world half"): the same line; the building's pass inherits nothing of the world
  half.
- **`field-reads.md`, the world map's residue** (`separation`, `moves`, `obstructed_tiles`,
  `day_record_version`, `obstruction_version`, `size`, converted "with whatever pass gives the
  blocked tiles an owner of their own"): untouched. None is in the world half, and the split moves
  nothing of the blocked record, so it neither waits for that pass nor shapes it.
- **`event-interface.md`**: row 2b's "Left listed ... `WorldMap.world`" (the spread look's read) is
  converted (`EventInstance.add_slices_beside_it()`). Section 2.3's "the map's record of blocked tiles"
  is untouched. **Row 3b** owns `event_manager.gd`, `event_world.gd`, `event_spawner.gd` and
  `event_director.gd` and "the spawner hands a live event everything in one setup call": the split
  adds the world the event is drawn in to that call (`drawn_in`) and `EventManager.draw_in()` to the
  manager's hand-ins. It agrees with 3b's direction (one call, everything handed), but the call's shape
  is 3b's to decide.
- **#1548** changes `event_manager.gd`, `event_director.gd` and `resistance_director.gd`, three of the
  readers, and its fence holds the rest of `src/events/` and `src/resistance/`.

## The fork

The design is complete and depends on no open question of its own; what it waits for is the files.
Three ways on, for the orchestrator:

- **(a) Build it as its own pull request once #1548 merges, ahead of row 3b** (my pick). 3b's one setup
  call then takes `drawn_in` as it finds it, and 3b's agent reads this design. Cost: `EventInstance.setup()`
  gains a parameter that 3b may fold into its call shortly after.
- **(b) Fold it into row 3b's pull request.** One rewrite of the hand-offs instead of two; cost: 3b grows
  by the city, the building, `main`, the crowd, the resistance and some 25 test files, and the five
  uses wait for 3b's design too.
- **(c) Stack it on #1548's branch now.** Cost: any change Fable asks of #1548 is reworked here as well,
  the stacking grassy-ibis' item warns of.

Settled when built: "The map interface's world half (5 uses in `world_map.gd`) ..." and "The map
interface's world half is split off or declared a permanent exception in designing-classes" in
`standing-layer-breaks.md`; polite-tapir README's sentence on the building's read; minty-quail
README's "the building's write of `WorldMap.world`"; and `WorldMap.world` in row 2b's "Left listed".

## Architecture questions (for the build)

1. **Layers.** `WorldMap` stays in the model and stops naming the world. `Navigator`, `WorldContext`
   and `DrawLayer` stay in the world. `EventManager.draw_in()`, `EventWorld.drawn_in()`,
   `EventInstance.add_slices_beside_it()` are the simulation's; `main`'s `_world_drawn()` and the
   builder's new parameter are the root's. No file changes layer.
2. **Dependencies.** `tools/layer_map.py` loses the `DrawLayer`, `Navigator` and `WorldContext`
   exceptions (`world_map.gd`, five uses); nothing is added. The simulation and the root name the
   world from above. Other listed breaks in touched files (`event_def.gd`'s `SpawnSiting` is not
   touched; `interior_scene.gd`'s `Stroller` stays) are unchanged.
3. **Handed and fetched.** Every reader is handed the navigator and the world by its builder (the
   root, `City.build()`, `EventManager`, `EventSpawner`); nothing is fetched through the map any more.
   No group, autoload or static is added.
4. **Existing equivalents.** Reuses `Navigator` and `WorldContext` as they are; no new class.
5. **Where the fix lands.** In the shared hand-offs (the builder, the manager, the spawner), not per row.
6. **Testing in isolation.** A test hands the manager or the instance a bare `WorldContext` (as today,
   but to the reader instead of the map) and a `Navigator.new(map)` or none; no scene tree is needed
   beyond the holder node a drawn event is added to.
7. **Docs.** `docs/ARCHITECTURE.md`'s "WorldMap" section drops `navigator()`, `add_entity()` and
   `process_player()` and says the navigator and the world are handed by whoever builds the world; its
   "WorldContext" section gains the draw layers, `bang_outside()` and `process_player()` as the world's
   own service. The doc comments listed under "Who reads it" change with their lines.
