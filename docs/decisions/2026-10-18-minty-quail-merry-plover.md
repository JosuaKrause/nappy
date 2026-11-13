# minty-quail — The recipe context's round-trip checks move to a suite of their own · 2026-11-12

**The ask.** A suite tests the one module it is named for (inbox #1159 in gray-dolphin), and the review of #1419 found
two of the city map suite's new round-trip checks testing the scene recipes' file form of the map
(`RecipeCityContext`) rather than the map.

## What was built

- **`tests/test_recipe_city_context.gd`** holds the two checks word for word: the saved context passes validation, and it
  restores and saves the same. Its header says it builds the task-07 scene's map because the context is the file form of
  that map's fields.
- **`tests/test_city_map.gd` keeps the check that a map restored from its own capture captures the same facts**, renamed,
  and takes its scene map from the authored-scene builder its neighboring test already uses, so it calls the recipe
  context nowhere.

## Verified

The two suites, `tools/check.sh` and the field-read, test-only member, layer and typing checks pass; CI is green.
