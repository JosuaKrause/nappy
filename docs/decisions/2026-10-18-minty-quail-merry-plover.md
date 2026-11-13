# minty-quail — The recipe context's round-trip checks move to a suite of their own · 2026-11-12

**The ask.** A suite tests the one module it is named for (inbox #1159 in gray-dolphin), and the review of #1419 found
two of the city map suite's new round-trip checks testing the scene recipes' file form of the map
(`RecipeCityContext`) rather than the map.

## What was built

- **`tests/test_recipe_city_context.gd`** holds the two checks word for word: the saved context passes validation, and it
  restores and saves the same. It builds the task-07 scene's real map because `restore()` builds one through
  `CityMap.restored()`, a static constructor with no seam for a fake.
- **The city map suite's authored-scene round-trip case goes.** Its map came from the recipe context; taking it from the
  authored-scene builder instead was tried and rejected, since the builder lays the scene's stretch and dawn ground on
  the map, which a capture does not hold, so a scene whose stretch lists trees fails the round trip. The generated-map
  round trip stays in the city map suite, and the context's own round trip covers the scene's.

## Verified

The two suites, `tools/check.sh` and the field-read, test-only member, layer and typing checks pass; CI is green on the
merged head.
