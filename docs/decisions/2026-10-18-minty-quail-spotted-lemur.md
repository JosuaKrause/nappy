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
- **Fields gone private**: the map's `absent_segments`, `power_station_door`, `zone_anchor`, `power_station_door_key`
  and `power_station_industrial_blocks`; the layout's `open_rect`, `square`, `alley` and `passage`; the block plan's
  `forced_open_on`. Four of them still had test readers once the old context's dictionary reads stopped counting as
  game readers, and the test-only check fails such a field, so those tests read through methods the game calls.
- **Rejected options**, argued in the description: the map's capture uses the recipe's own key names, so the model and
  the file share them.
- **The city skill's "The lattice is not a full grid" names `CityMap.has_street()`**, since it named the field that
  went private; `docs/CITY.md` and `docs/GRAPHICS.md` likewise.
- **The queue item's first group names what is left**: the authored-scene builder's reads of the map, and the recipe
  side's reads of a block plan's steps.

## Verified

`tools/scene-recipes.sh` builds all the scene recipes on main and on the branch with the same manifests apart from
timing and paths; a throwaway probe restored and recaptured every recipe's context with matching hashes;
`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the scene recipe, city map
and save suites pass; CI is green.
