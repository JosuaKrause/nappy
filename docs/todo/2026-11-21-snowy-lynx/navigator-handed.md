# Every world's navigator is built by the scene that builds the world, and the events keep the navigator they are handed

### What is wrong

**The building's navigator is built by the simulation, in production.**
`EventManager.setup_world(map, run)` (the event manager's setup for a world that is not the city,
the escape's building) runs `world.use_navigator(Navigator.new(map))`. It is the one production
path where a simulation class builds the world-layer service it depends on. The city's is built by
the city scene (`City.build()`), held behind `City.navigator()`, and handed in through
`SimulationBuilder.in_the_city(world, map, navigator, ...)`. So the two kinds of world, which the
builder exists to stand "the same way", get their navigator two ways, and `Navigator`'s own class
comment has to name the event manager as something that "builds a world", which it does not.
designing-classes: a component is handed what it depends on; a mode is a configuration of the
shared code, never a copy.

**The events' world replaces a navigator it was handed.** `EventWorld.navigator()` (the events'
shared state, asked for the navigator by the spawner, the director and `EventsAhead`) reads:

```gdscript
if _navigator == null or _navigator.map() != _map:
    _navigator = Navigator.new(_map)
```

The second half throws away a handed navigator whose `map()` is not the world's map and builds a
real one in its place, silently. Nothing reaches it today: `rg -n "use_navigator\(|\.use_map\(" src
tests tools` shows the navigator handed only by the two setups, over the same map they hand, and
`use_map()` called once per world (the two setups and the probe `tests/probes/walk_rows.gd`, on a
fresh `EventWorld`). So it is unreached code, which is deleted; and it is a trap for the first
suite that hands a manager a fake navigator, since a fake that does not carry the manager's own
map is swapped for the real thing without a word. Row 5 of `event-interface.md` (the events' and
the resistance's suites test one module each) is where fakes of this kind arrive.

**The same default is resolved three times down one chain.** `EventManager.setup()` writes
`navigator if navigator else Navigator.new(map)`, then `EventWorld.navigator()` holds the same
default again, and `setup_world()` a third copy. One place is enough.

### What changes

Layers: the world (`InteriorScene`), the root (`SimulationBuilder`, `main`), the simulation
(`EventManager`, `EventWorld`). No file changes layer; no line is added to or taken from
`tools/layer_map.py` or `tools/field_reads.txt`.

1. **`src/interior/interior_scene.gd`** (the building's scene, world layer). `build()` makes
   `_navigator = Navigator.new(_map)` on the line after `_map = InteriorMap.build()`; a new
   `navigator() -> Navigator` beside `map()` answers it. An underscore field behind a method, as
   `City`'s is. Its comment says what `City`'s says: how everything that moves over the building's
   map moves, built with the map and handed on by `main`.
2. **`src/simulation_builder.gd`** (root). `in_the_building(world, map, navigator, run)`: a
   `navigator: Navigator` parameter after `map`, in `in_the_city()`'s order, handed to
   `events.setup_world(map, run, navigator)`. Its comment gains the sentence `in_the_city()`'s has
   ("`navigator` is the building's own, `InteriorScene.navigator()`").
3. **`src/main.gd`** (root). The one call becomes
   `in_the_building(_interior, _interior.map(), _interior.navigator(), _run)`.
4. **`src/events/event_manager.gd`** (simulation).
   `setup_world(map: WorldMap, run: RunState, navigator: Navigator = null)` and
   `world.use_navigator(navigator)`. In `setup()`, `world.use_navigator(navigator)` with no
   ternary. Both comments say: the navigator its figures move by, or none for a rig, whose events'
   world then moves by one over the map. The class comment's "Handed what it depends on" sentence
   lists the navigator for `setup_world()` too. The optional parameter stays optional: fourteen
   other call sites in the suites' rigs hand `setup_world(map, run)` and none of them is about the
   navigator.
5. **`src/events/event_world.gd`** (simulation). `navigator()` answers the one it was handed, and
   where none was handed builds one over its map on the first ask and keeps it:

   ```gdscript
   func navigator() -> Navigator:
       if _navigator == null:
           _navigator = Navigator.new(_map)
       return _navigator
   ```

   The comparison with `_map` goes. `use_navigator()` gains its comment line (it has none), saying
   null is "none handed". The field's comment loses "a rig that sets the map itself".
6. **`src/world/navigator.gd`**, comment only: "whoever builds a world builds one over its map
   (`City.build()`, `InteriorScene.build()`)", and "the event manager to every figure it makes"
   stays.
7. **`docs/ARCHITECTURE.md`**, the "WorldMap" section: "the building's events build theirs"
   becomes the building holding its own (`InteriorScene.navigator()`), handed by the builder as the
   city's is. The `world/` listing's line for `world_map.gd` ("the world, which hands out the
   navigator and the draw layers") then reads true for both worlds and stays.

**Not asked for: the other rig defaults.** `Crowd.setup()`, `EventDirector._init()`,
`EventSurroundings.navigator()`, `ResistanceDirector.setup()` and `ResistanceHappenings.setup()`
each build `Navigator.new(map)` when handed none. Each is the one default of a class a suite
stands on its own, which is this codebase's way with a rig (the silent trace, the null timing
sink, an atlas library of its own); some sixty test and probe call sites lean on them, about forty
of them the resistance's `setup(..., city, null, ...)`. They stay.

### Tests

- `tests/test_simulation_builder.gd`: its two `in_the_building(world, map, run)` calls hand
  `Navigator.new(map)`, and the building's case gains the check the city has in
  `test_world_passability.gd`: the building's events move by the navigator the builder was handed
  (`simulation.events().world.navigator()` is that object).
- `tests/building_events.gd` (the building's event rig): `events.setup_world(scene.map(), run,
  scene.navigator())`, so the building's suites move by the building's own navigator as the game
  does.
- `tests/test_event_manager.gd`: one new check that holds the deleted branch out: a manager set up
  on a street map and handed a navigator over open ground (`Navigator.new()`) answers that same
  object from `world.navigator()`.
- `tests/test_interior.gd`: `scene.navigator().map() == scene.map()` after `build()`.
- No other suite changes. Run by name: `simulation_builder event_manager interior
  interior_masked_man wall_shield escape_invisible_wall finale_a finale_b finale_c day_world
  world_passability navigator_fallbacks`, and `./tools/check.sh`.

### Order

One pull request. Inside it: the scene's navigator first (1), then the hand-off (2, 3, 4), then
`EventWorld.navigator()` (5), then the comments and the doc (6, 7), then the tests. Each step
leaves the suites passing.

### What holds parity

Nothing a player sees or a run log records changes, and no capture is owed. A navigator declares
one member, its map (`var _map` is the only `var` in `navigator.gd`), so every answer is a
function of the map and the mover asked about; the building's events move by a navigator over the
same map as today, built one call earlier by another object. The deleted comparison is unreached
(the search above, shown in the pull request with every hit and its reason). The parity check is
the suites above passing unchanged apart from the lines named.

### What it costs

Small: five source files and two that change by a comment, four test files, one new check in
each of three. A Sonnet builder in one sitting, well under 100k of context; an Opus review. It
answers the architecture questions under its own heading as any code change does: layers as
above; `Navigator` named from the world, the root and the simulation, all from at or above its
layer; the events are handed the navigator in both worlds and fetch nothing; it reuses
`Navigator`, `City`'s shape and `in_the_city()`'s parameter order; the fix lands in the shared
hand-off, not in a branch for the building; a test hands a manager any navigator and gets it back.

### What it collides with in the queue

- **minty-quail's `event-interface.md`, row 4b** (a row is written as its parts; a chain of ten
  pull requests, the third running now in the worktree `mq-4b3`). Its steps rewrite reads of the
  catalogue row's settings across `src/events/`. The lines this change touches
  (`EventManager.setup()`'s and `setup_world()`'s navigator line and signature,
  `EventWorld.navigator()`) read no setting of a row, so it **does not have to wait for 4b** and can
  run beside the chain, merging `main` before its review as usual. If the orchestrator keeps one
  writer in `src/events/` at a time, it fits between any two of 4b's pull requests.
- **Row 5 of the same file** (the events' and the resistance's suites test one module each, after
  4b): this change should merge **before row 5 starts**, since row 5 is where a suite first hands
  a manager a fake navigator.
- **sunny-osprey** (the crowd's lanes move onto the navigator, if it pays; band `next`, after the
  refactor): no shared line. See the nit on its title.
- **polite-tapir's `standing-layer-breaks.md`**: untouched; this fixes no listed break and adds
  none.
- **Band.** With the refactor (`now`, beside minty-quail and polite-tapir), since it finishes a
  group the refactor's design review owns; no `fable-only` build is needed beyond this design.
