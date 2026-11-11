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
- **Typing `FrontReads.look()`** made two other suites' opt-out names stale (`test_home_block`,
  `test_resistance_placement_kinds`), and each line was shortened to what it trips.

## Left, each with its reason

- **The dawn half of the check that dawn and relocation do not replace a building's lasting
  collision** called `City.start_day()`, so it left the residency suite; the relocation half stays,
  and `tests-one-module.md` gives the dawn half to the city scene's suite. Past the map, the
  suite's ground is plain water or grass rather than the city's border bands.
- **Fields the suites still read, with no method the game calls**: `SceneryGround`'s `chunks`,
  `pending`, `elapsed`, `tile_set` and `mode`; `SceneryResidency`'s `view`, `budget_usec` and
  `timing`; `BuildingShadows`' `drawer`, `falls_on` and `streamed`; `AtlasLibrary.trace_note`; and
  `Building`'s `scenery_resident`, `roof_object_parent`, `day`, `condition`, `powered`,
  `neighbor_window_col` and `posters`. No method was added for a test.

## Verified

The suites taken and those that touch the changed rigs pass, `tools/typing_census.py --check`
holds, and no game file changed, so the identity probes do not apply.
