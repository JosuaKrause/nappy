# snowy-lynx — Every world's navigator is built by the scene that builds the world · 2026-11-21

**What was asked.** The entry snowy-lynx, a change Fable wanted in its review of #1570 (the map interface's world half
split off `WorldMap`), a pull request of the fable-only entry polite-tapir that merged on an Opus design while Fable's
quota was out (the record calm-lemur). The building's navigator was built inside `EventManager.setup_world()`, the one
production path where the simulation built its own world-layer service, while the city's was built by its scene and
handed in; and `EventWorld.navigator()` silently replaced a handed navigator whose map differed from the world's. The
player accepted Fable's changes: "yes, fables complaints are valid. get the fix and then let fable review again". Built
by a Sonnet agent as #1614 from Fable's design, then reviewed adversarially and by Fable.

**What was built.** The building's scene (`InteriorScene.build()`) builds its navigator beside its map, and the root
hands it through `SimulationBuilder.in_the_building()` to `EventManager.setup_world()`, as the city's is handed; the
manager's `setup()` keeps no default of its own. `EventWorld.navigator()` returns the navigator it was handed, building
one over its map only where none was handed; the comparison that replaced a handed one goes. A suite holds that a
manager handed a navigator returns that same object, and that the building's navigator walks the building's map.

**Left alone on purpose** (Fable's design): the five rig defaults that build a navigator when handed none,
`Crowd.setup()`, `EventDirector._init()`, `EventSurroundings.navigator()`, `ResistanceDirector.setup()` and
`ResistanceHappenings.setup()`, and `EventManager.setup_world()`'s navigator, which stays optional: each is the one
default of a class a suite stands on its own, and the game hands every one a navigator.

**Nothing a player sees changes:** a navigator holds nothing but its map, and no caller handed one over another map
(the search is in the pull request), so the deleted branch was never taken.
