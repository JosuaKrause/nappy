# The task-scene stretch tests test what they claim

**Medium · from the re-review of PR #592 (azure-beaver, the task scenes are a handcrafted stretch
with a rigged marble bag).**

- **A stretch test still compares a saved scene with a generated city.**
  `tests/test_scene_recipe_stretch.gd` builds `witness` by generating the whole city for the day-7
  scene's seed, and `_test_the_stretch_is_the_only_ground` requires every saved stretch tile to
  equal it. That contradicts the player's mossy-marmot choice, "Finish fully handcrafted layouts
  now", and the record's "never compare their layout with a generated witness": hand-editing one
  tile of `scene-recipes/task-07-package.json`, or a generator change, fails the suite though the
  scene plays unchanged. Compare with the recipe's own `stretch.tiles` and `context.tiles`, and keep
  generation only in `_test_the_draft_takes_whole_streets`.
- **The forced crowd-entry check cannot fail.** `tests/test_scene_recipe_stretch_crowd.gd` moves the
  camera to (-10000, -10000) before forcing recycles, so every entry counts as out of view; deleting
  the view filter in `CrowdAgent._enter_at_a_stretch_end()` still passes. Centre the camera on each
  stretch end, force recycles, and assert no accepted entry falls inside either view.
- **Low:** the draft tool's "no car in her view at the start" uses the landscape half-extent only
  (`src/dev/scene_recipe_draft.gd`, `Tuning.VIEW_HALF_EXTENT`); test both views, as
  `CrowdAgent._beyond_every_view` does.
- **Low, `docs/SCENE_RECIPES.md`:** "Every other tile is void: … no building" leaves out the lots of
  the buildings the stretch lists; and the stretch is said to be presented "over the same complete
  construction", though a stretch runs no construction and restores its saved context. Make both
  say what is true.

Show each fixed test failing on the defect it now catches (by reading or one run) in the PR.
