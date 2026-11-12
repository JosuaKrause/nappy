# minty-quail — The city map captures and restores itself · 2026-11-12

**The ask.** One object reaches another only through its methods (designing-classes, "Fields are not API"; inbox #1173
in gray-dolphin), and the scene recipes' map capture and restore read and wrote the map's and each block layout's
fields by name, so `field-reads.md` asked for a design of the map capturing and restoring itself.

## What was built

- **`CityMap.capture()` and `CityMap.restored(facts)`**: the map says what generation fixed, as a dictionary of typed
  values under the recipe's key names, and builds the same map back from it. **`BlockLayout.capture()` and
  `BlockLayout.restored(carves)`** do the same for a block's carves.
- **`RecipeCityContext` keeps only the recipe file's side**: boxing into JSON-safe arrays, the file's shape and key
  order, and validation. No read or write by name is left, and the file loses its opt-out line. Its three callers keep
  their calls.
- **Fields gone private**: the map's `absent_segments`, `power_station_door`, `zone_anchor`, `power_station_door_key`,
  `power_station_industrial_blocks` and `built_over`; the layout's `open_rect`, `square`, `alley` and `passage`; the
  block plan's `forced_open_on` and `steps`. Several had test readers once the old context's reads stopped counting as
  game readers, and the test-only check fails such a field, so those tests read through methods the game calls
  (`anchor_of()`, `force_open_on()`, `streets_built_over()`, `step_at()`) or build a block's arc as the generator does.
  A printed tally of the station's industrial blocks, which checked nothing, is gone.
- **`tests/test_city_map.gd` checks the round trip**: a generated map, its copy and a saved scene's context capture the
  same facts after a restore.
- **Rejected options**: the context asking the map's getters and setters one fact at a time, which keeps the list of
  the map's facts outside the map; the map writing the recipe's JSON itself, which puts the file's encoding in the model;
  a typed record mirroring the fields, a third copy of the field list; and reading by name, the problem this pass fixes.
  The facts' keys are mostly the recipe file's own (`block_plans` and `block_layouts` are the map's, the file keeps
  `blocks`), so a key name is shared between the model and the format, the choice the description leaves open to
  overturn.
- **The city skill's "The lattice is not a full grid" names `CityMap.has_street()`**, since it named the field that
  went private; `docs/CITY.md` and `docs/GRAPHICS.md` likewise.
- **The queue item's first group names what is left**: the authored-scene builder's reads of the map, and the recipe
  side's reads of a block plan's steps; `dead-code-sweep.md` lists the industrial-block count, which nothing reads,
  and breezy-hawk's README names the station door's method.

## Verified

`tools/scene-recipes.sh` builds all the scene recipes on main and on the branch with the same manifests apart from
timing and paths; a throwaway probe restored and recaptured every recipe's context with matching hashes;
`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the scene recipe, city map
and save suites pass; CI is green.
