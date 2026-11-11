# minty-quail — The atlas's and the scenery's suites are typed, and the residency suite builds no city · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin).
The atlas's and the scenery's pass of `typed-everywhere.md`'s "What is untyped in a test goes as
its suite is converted", and the atlas and scenery entry of `tests-one-module.md`, after the ground
pictures were typed (#1329) and the city's own parts were handed what they read
(minty-quail-quiet-ibis).

## What was built

- **The atlas's suites (`test_atlas_boot`, `_decoration`, `_ground`, `_leaf_consumers`,
  `_loading`, `_packer`), `test_building_shadows`, `test_ground_floor`, `test_scenery_residency`
  and the rigs `ground_floor_checks.gd`, `recording_atlas.gd` and `front_reads.gd` are typed and
  lose their opt-out line.** `test_scenery_animation` is typed too, though it is the events'
  scenery's suite, since it needed four small fixes once its line came off. No line under `src/`
  changed.
- **`test_scenery_residency` builds no city.** A helper hands `SceneryResidency` and
  `SceneryGround` their parts the way `City.build()` does: the cached map, a ground configured from
  a source, idle fakes of the building shadows and the decals, and a real `Building` on every lot.
  The suite's reads of `City.scenery_ground` and `City.scenery_ground_source` end, and the two kept
  lines for them in `tools/test_only_members.txt` are rewritten to the readers left.
- **The dawn half of the check that dawn and relocation do not replace a building's lasting
  collision moved to `test_city_buildings`**, which builds a real city: after `City.start_day()`
  the city holds the same buildings, each the same node with the same collision shape. It was seen
  to fail with a temporary `start_day()` that swapped one building's shape. The relocation half stays in the
  residency suite.
- **The suites ask the game's methods where it has one**: the shadows' drawer is handed through
  `draw_through()`, a building's posters through `hand_over_posters()`, the ground floor's home
  building through `stand_on_home_block()` and `is_on_home_block()` and its look through
  `look_variant()`, and the residency suite reads the map's `size_in_tiles()` and `city_seed()` and
  holds the roof layer it hands in rather than reading it back.
- **Typing `FrontReads.look()`** made two other suites' opt-out names stale (`test_home_block`,
  `test_resistance_placement_kinds`), and each line was shortened to what it trips.

## Left, each with its reason

- **Past the map, the residency suite's ground is plain water or grass** rather than the city's
  border bands, which `test_city_ground_water` and `test_main` hold.
- **Fields the suites still read, with no method the game calls**: `SceneryGround`'s `atlas`,
  `chunks`, `pending`, `elapsed`, `tile_set` and `mode`; `SceneryResidency`'s `view`, `budget_usec`
  and `timing`; `BuildingShadows`' `falls_on` and `streamed`; `AtlasLibrary.trace_note`; and
  `Building`'s `scenery_resident`, `day`, `condition`, `powered`, `neighbor_window_col` and
  `posters`, read once to see that a poster pasted while unloaded survives the rebuild (a building
  is handed its posters by `hand_over_posters()`, and nothing answers them). No method was added
  for a test.
- **`test_ground_floor` builds its fixture through `stand_on()`**, as `City._spawn_buildings()`
  does, for its district, footprint and height. Writes that stay: a building's `variant` in the
  sweep over every variant; `roof_extension_rows`, `roof_extension_seamless` and
  `seamless_cover_cols`, which the city writes as fields itself; and `position`,
  `covered_ground_cols`, `door_world_x_range` and `power_station`, which no method sets.
- **Reads of `Building.shape` and `district`** (`test_scenery_residency`, `ground_floor_checks.gd`)
  stay: no method answers them.
- **Other modules' fields** were not searched and stay for their passes.

## Verified

The suites taken and those that touch the changed rigs pass, `tools/typing_census.py --check`
holds, and no game file changed, so the identity probes do not apply. The pull request gives each
suite's CI time before and after.
