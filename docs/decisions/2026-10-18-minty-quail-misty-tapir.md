# minty-quail — A scene's walk is handed the route tree and locations the scene holds · 2026-11-24

The last case of `re-derived-cases.md` (the facts derived in more than one place, inbox #1156 in
gray-dolphin), closed with this record: a scene's walk worked out its route tree and its locations
again (the record 2026-10-18-minty-quail-mossy-puffin names it). When the walk sited something (day
11's queued mast), `SitingMaker._assemble()` grew the route tree and laid out the locations again,
because `EventsAhead.start_a_given_walk()` never set `_day_tree` and the recipe's walk carried no
locations, though `SceneRecipeRuntime._event_plans()` held both.

**Built.**
- `SceneRecipeRuntime._event_plans()` keeps the route tree the day's streets hold and the locations it
  lays out over that tree's corridor, and hands both to `EventManager.start_recipe()` (two optional
  parameters after the ground). The locations go through the plan to `WalkEvents.locations()`, which
  `SitingMaker._assemble()` already preferred; the tree goes through `DayPlanner.Plan.use_tree()` to
  `EventsAhead.start_a_given_walk(day, tree)`, which now sets `_day_tree` (and resets it, so a
  walk handed none does not keep an earlier walk's). A rig that hands none keeps the fallback.
- A scene with no route tree hands the walk neither: its locations are laid out under a corridor that
  answers none, and the walk's own corridor would be a grown tree's.

**Noted.**
- The handed tree is the one the day's streets grew before `install()` runs, the corridor its rows
  were placed on; a tree grown again as she walks is grown on the map with the scene's edges shown,
  so the two can differ for a scene whose edges change the lattice. The locations handed are the very
  object the rows' placements asked, so the walk's siting reads the places those placements took.
- No scene's siting changes: no scene recipe queues a mast through the walk (an authored mast is
  placed by `_mast_placement()`), every scene recipe passes and all 25 manifests are byte-identical to
  main's (`tools/scene-recipes.sh`, on both).
- The check that holds it: `tests/test_walk_siting_spec.gd` fails when `start_a_given_walk()` drops
  the tree (the maker is asked with null), and `tests/test_event_manager.gd` and
  `tests/test_scene_recipe_install.gd` hold the manager's and the runtime's hand-offs.
