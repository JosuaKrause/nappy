# minty-quail — A scene's walk is handed the route tree and locations the scene holds · 2026-11-24

The last case of `re-derived-cases.md` (the facts derived in more than one place, inbox #1156 in
gray-dolphin), closed with this record: a scene's walk worked out its route tree and its
locations again (the record 2026-10-18-minty-quail-mossy-puffin names it). When the walk sited
something (day 11's queued mast, a rigged route), `SitingMaker._assemble()` grew the route tree
and laid out the locations again, because `EventsAhead.start_a_given_walk()` never set
`_day_tree` and the recipe's walk carried no locations, though
`SceneRecipeRuntime._event_plans()` held both.

**Built.**
- `SceneRecipeRuntime._event_plans()` keeps the route tree the day's streets hold and the
  locations it lays out over that tree's corridor, and hands both to
  `EventManager.start_recipe()` (two optional parameters after the ground). The tree rides as
  the plan's walk (`DayPlanner.Plan.walk()`, which a day's plan already uses for its tree), so
  there is no second owner for it; `EventsAhead.start_a_given_walk(day, tree)` takes it from
  there and sets `_day_tree` (and resets it, so a walk handed none keeps no earlier walk's). The
  locations go through the plan to `WalkEvents.locations()`, which `SitingMaker._assemble()`
  already preferred. A rig that hands none keeps the fallback.
- A scene with no route tree hands neither: its locations are laid out under a corridor that
  answers none, and the walk's own corridor would be a grown tree's.

**Noted.**
- **Reached, same answer.** `task-11-mast` queues day 11's mast through the walk over the handed
  tree, and `task-07-package`, `task-11-mast` and `task-11-two-masts` rig the route at the mark
  over it. Every scene recipe passes and all 25 manifests are byte-identical to main's
  (`tools/scene-recipes.sh`, on both): the handed tree and locations give those scenes the
  answers a regrown one did.
- **The edge state of the handed tree.** It is grown inside `witness_only()`'s bracket
  (`City.start_recipe_day()`), with a bounded scene's outside and a stretch's cut-off ground
  off, as the corridor the rows were placed on is. What is sited as she walks now matches the
  events' corridor, where a tree regrown with the edges shown did not. In a stretch that
  corridor can cross ground she cannot walk.
- **Day 13's task reads the handed locations too.** It lays its roadblock across the nearest
  section when none is close (`ResistanceDirector._place_the_roadblock_near()`), and on a
  recipe's walk it used to be handed none.
- The locations handed are the very object the rows' placements asked, so a siting made as she
  walks reads the places those placements took.
- The checks that hold it: `tests/test_walk_siting_spec.gd` fails when
  `start_a_given_walk()` drops the tree (the maker is asked with null);
  `tests/test_event_manager.gd` holds the manager's hand-off;
  `tests/test_scene_recipe_install.gd` holds the runtime's, with a tree and with none (a scene
  with no route tree hands neither).
