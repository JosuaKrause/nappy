# minty-quail — Authored scenes place seals and doors through the planners' own entries (tests through public seams) · 2026-11-02

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: what the item said
`SceneRecipeRuntime` did wrong, and the three scene recipe suites it touches. The route rig suite and
fourteen more the brief named are not started; the item lists them.

**Built.**
- Authored scenes place seals and checkpoint doors through the planners' own entries, which the
  day's planning calls too: `SealPlanner.may_seal()`, `offers()` and `seal_street()` (returning a
  `SitedSeal` with `shut_the_sidewalk()`), called by `plan_day()`, its thinning pass and
  `_pick_candidate()` as well as `SceneRecipeRuntime._authored_seals()`; `RegionPlanner.stand_door()`,
  called by `plan_day()` and `SceneRecipeRuntime._select_structures()`. Before, the runtime rebuilt
  placement from the planners' private functions, so authored scenes could drift from the game.
- A held event walks through `EventInstance.walk_on_by_hand()`, which the runtime calls, in place
  of the instance's private gait step; `SceneRecipeRuntime.walk_spec` is private.
- `test_scene_recipe_runtime.gd` (private reads 40 to 9, hand-called frames 4 to 1),
  `test_scene_recipe_task.gd` (26 to 3) and `test_recipe_structures.gd` (9 to 0) install, begin and
  step scenes as `main` does, and build each day in a run of its own with a fresh `RunState`
  (`GameState` lines 52 to 0).
- New tests: an authored door and soft seal stand where the day's own would; a crowd handed no
  navigator still pushes a walker clear of her (`test_navigator_fallbacks.gd`); a booted day recipe
  and escape recipe run their events under the spec their clock runs on (`test_scene_recipe_boot.gd`,
  which hands `main` a scratch-path save). Every check kept; fifteen mutation runs each fail one.

**Open to overturn:** the order. The brief put `test_route_rig.gd` first; converting it means
moving the rig's planning, clearance and target resolution into a class `RouteRig` calls, a pull
request's worth of moved code on its own, so this one did the runtime's fixes first.

**Not done:** a test of `ResistanceDirector`'s fallback to the map's navigator, since its happenings
fall back to the same navigator and nothing observable depends on the director's.
