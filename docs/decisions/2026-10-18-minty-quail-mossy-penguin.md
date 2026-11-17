# minty-quail — The authored-scene builder reads and writes the city map through methods · 2026-11-16

**The ask.** `field-reads.md`'s rule, never read a field directly, always through a method (inbox #1173 in gray-dolphin), for the
authored-scene builder (`RecipeCityBuilder`, the scene recipes' city): its reads and writes of `CityMap`, the
`RoadClosure.segment` read, and `RecipeCityContext`'s read of a block plan's steps (`BlockPlan.Step`). This is the pull request
#1483, stacked on #1480 and merged after it.

## What was built

- **22 lines leave `tools/field_reads.txt`**: the builder's 21 `CityMap` lines and its `RoadClosure.segment` line; no other
  reader's line is touched.
- **Each fact the builder writes has a method on the map**: `show_recipe_window`, `begin_stretch`, `add_stretch_tile`,
  `add_stretch_building`, `add_stretch_prop`, `add_stretch_litter`, `add_stretch_crack`, `set_recipe_trees`,
  `set_recipe_tree_moves`, `add_recipe_closure`, `set_building_lots`, `keep_dawn_ground`, `show_stretch`. Its reads use methods
  the map already had (`street_network()`, `main_road_corridor()`, `precinct_stretches()`, `plans_by_block()`, `city_seed()`,
  `building_lots()`, `layout_of()`, `recipe_road_closures()`, `stretch_building_lots()`, `recipe_tree_tiles()`,
  `tree_move_from()`) and two new ones, `recipe_diagnostics()` and `tree_move_sources()`.
- **12 fields go underscore-private**, the ones only the builder, the map's own file and the tests used: `block_layouts`,
  `building_rects`, `recipe_closures`, `recipe_dawn_tiles`, `recipe_diagnostics`, `recipe_exterior`, `recipe_tree_moves`,
  `recipe_trees`, `stretch_buildings`, `stretch_cracks`, `stretch_litter`, `stretch_props`; the suites go through the methods.
- **Nine fields stay public**, since another reader remains: `block_plans`, `main_road`, `network`, `precinct_spans`,
  `recipe_bounds`, `seed_used`, `stretch`, `stretch_active` and `tiles`; the builder's reads of them go through methods.
- **`RoadClosure.fits_within(window)`** replaces the builder's read of `segment`; `segment` and `kind` stay public, since six
  other classes read them. **`BlockPlan.Step`** gets `becomes()`, `earliest_day()` and `needs()` for `RecipeCityContext`; the
  fields stay public (`city_state.gd`, `city_generator.gd` and the tests read them), so the methods cannot take their names.
- Comment and doc edits where a sentence named a now-private field (`docs/CITY.md`, `city.gd`, `building_shadows.gd`,
  `ground_tiles.gd`, `spawn_siting.gd`, `fire_look.gd`), and the queue sentences both pull requests made untrue.
- **Tests**: `tests/test_scene_recipe.gd::_test_a_closure_must_fit_a_bounded_window` (fails with `fits_within` returning true);
  `tests/test_city_map.gd::_test_what_an_authored_scene_writes_is_what_the_map_answers` (each writing method is what its
  question answers; dropping the assignment in a method fails its check); the existing round trip in
  `tests/test_recipe_city_context.gd` holds the three `Step` methods.

## Measured

`check.sh` clean; thirteen suites passed after the two new tests were fixed; `check_layers.py`, `check_field_reads.py` (1,174
lines still stand, 22 fewer), `check_test_only_members.py` and `lint.sh` clean. The search for the twelve old names with a
leading dot and no parenthesis finds no hit under `src`, `tests` or `tools`; without the dot, four lines outside `city_map.gd`
hit, none a read (the captured facts' keys and the new `map.recipe_diagnostics()`). The reviewer mutated five of the writing
methods to do nothing and each failed a check, and confirmed equality is still covered by `_check_the_same`, whose `_members()`
compares private variables too.

## Rejected, with the reason

- **A reader only a test would use** (`stretch_crack_tiles()`): not added.
- **Narrower commands for `set_building_lots`, `set_recipe_trees` and `set_recipe_tree_moves`**, which the reviewer called close
  to setters in disguise: the builder really does replace those, so the methods are honest; a preference, not taken.
- **The three `Step` methods under the fields' names**: impossible while the fields stay public; named apart, a reading of
  designing-classes' new-name rule that the reviewer would not overturn.

## What stays open

The rest of `field-reads.md`'s areas stay in the entry. (The temporal coupling the reviewer noted, `add_stretch_tile` or
`show_stretch()` before `begin_stretch()`, is handled: the doc comment on `CityMap.begin_stretch()` says the other two follow it,
added before the merge.)
