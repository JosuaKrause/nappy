# The classes that demand a whole City take only what they read

**The ask.** "the city should never be built for tests that don't test the actual city"
(inbox #1156 in gray-dolphin), "no test should build a real object that it doesn't test (it should mock it)" (inbox #1159 in gray-dolphin),
and, on the board's test-isolation-plan, "yes" to its third step: hand-ins for the classes that
demand a whole city, a way to hand `main` its map, and one shared writer for small test maps
(inbox #1159 in gray-dolphin). On the design in PR #1166: "yes three prs is fine" (inbox #1173 in gray-dolphin).

**Read as:** no class takes a whole `City` when it reads only parts of it, so no test of it has to
build a city. `DayStreets`, `CityFronts` and the hand-ins for the resistance director, its
happenings, day 12's park cordon, the crowd and the run log's observer are built; the design is in
#1166's description, under "The step's design".

**What is left is the readers below.** The third pull request is cut into several small pull
requests, each reviewed and merged on its own, the player's answer to the cut
(inbox #1381 in gray-moose); the earlier answer was three pull requests ("yes three prs is fine",
inbox #1173 in gray-dolphin). The smaller cases of 3c's row in #1166's "Files it touches" take what
they read: the event manager and its day planner since the record
2026-10-18-minty-quail-crisp-otter, the scenery's residency and ground, the blackout and the poster
walls since the record 2026-10-18-minty-quail-quiet-ibis, the still watch, the debug readout, the
frame recorder and the frame trace since the record 2026-10-18-minty-quail-calm-wombat, the
developer's rig, the route rig and its planner since the record
2026-10-18-minty-quail-plush-chipmunk, and the day director and the run log's session since #1482,
through the world the director stands (`DayWorld`) and the city scene's dressing for a walk
(`CityDressing`). The city scene builds no event manager, crowd, poster walls or blackout: one
builder stands them in the city and in the escape's building (`SimulationBuilder`, the record
2026-11-11-polite-tapir-snowy-toad), and `main` hands it the developer settings for those parts. `main.gd` reads the city only to build it and hand its parts on; the eight
settings it still writes into the city's fields (`trace`, `run`, `ground_recipe`, `atlas`,
`ground_mode`, `scenery_frame_locked`, `skip_shadows`, `frame_timing`) are the city's own, for its
ground and scenery, and stay fields until the city scene's own pass (minty-quail's README, "The
modules that do not wait for the events"), not this item.

**Other readers of a whole `City` under `src/`**, which #1166's row does not list:

- `src/day/day_world.gd` holds the city whole only for an authored scene to install itself into
  (`DayWorld.scene_city()`): the main scene hands it only when a scene is played, and the day
  director passes it to `AuthoredScene.install()`, which waits with the scene recipes below.
- The scene recipes take the city whole: `SceneRecipeRuntime.install()` (and the `AuthoredScene`
  it extends, `src/run/authored_scene.gd`), and `SceneRecipeDraft.record()` and `compose()`
  (`src/dev/scene_recipe_draft.gd`). `tests-one-module.md`'s entry 3 waits for `install()` to take a
  narrow interface instead.
- The debug layers (`src/dev/debug_layers.gd`) ask the world they are handed whether it is a `City`
  and read its props through `City.props()`.

**Which map a test uses** is writing-tests' rule (inbox #1172 in gray-dolphin): the shared writer's map is for a test
of one interaction or edge case, never for a booted day or a measurement.

**Fields are not API** (designing-classes, inbox #1173 in gray-dolphin): new state is kept in underscore fields
behind methods, and a read this work rewrites goes through a method.
