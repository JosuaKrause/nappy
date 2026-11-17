# minty-quail — The city map no longer keeps two facts nothing reads · 2026-11-16

**The ask.** `dead-code-sweep.md`, part (a), the two `src/city/` bullets: the city map's industrial-block count for the power
station and the map's own set of dead-end streets, both written by the generator and read by no code. This is the pull request
#1480; parts (b), `EventScheduler._calm_rect()`, and (c), `EventsAhead.walk_siting()`, collide with live placement work and are
not built here.

## What was built

- **Deleted**: `CityMap._power_station_industrial_blocks` (the recipe key `power_station_industrial_blocks`) and
  `CityMap._dead_ends` (the `dead_ends` set in `RecipeCityContext.SETS`), `mark_dead_end()`, the fourth argument of
  `record_power_station()`, and their lines in `copy()`, `capture()` and `restored()`. The generator no longer hands the map an
  industrial count nor calls `mark_dead_end()`; its own `_industrial_count` stays, since `power_station_rank` reads it.
- `RecipeCityContext`: both keys leave `capture()`, `restore()`, `validate()` and `SETS`, so the scene-recipe context format
  changes: the 11 `scene-recipes/*.json` files that carry a saved context lose the two keys and nothing else
  (`power-station-hall.json` and `-yard.json` carry only pins).
- **A recipe's own `city.dead_ends` pins stay**: they are live input (the generator walls where they say, `RecipeCityBuilder`
  counts them against `MAX_CUL_DE_SACS`, `SceneRecipe` validates them). The game reads a dead end off the streets built over
  (`CityMap.streets_built_over()`, `TelemetryMap`).
- `docs/CITY.md`: two sentences named the deleted fields; they name `streets_built_over()` and drop the station count.
  `tests/test_blackout.gd` loses the call's fourth argument.
- **Test**: `tests/test_recipe_city_context.gd::_test_a_context_carries_no_fact_nothing_reads`: a saved context still holding
  either key is refused as an unknown field; with `"dead_ends"` back in `SETS` it fails, and so does the existing round trip.

## Measured

The suites `recipe_city_context city_map generator blackout scene_recipe` ran 90,896 checks with 0 failures; `check.sh`,
`check_layers.py`, `check_field_reads.py`, `check_test_only_members.py` and `lint.sh` were clean. The reviewer found no read of
either fact left in `src`, `tests`, `tools`, `docs/*.md` or `scene-recipes`, and ran the round trip on the head. A dead end is
told apart today by `streets_built_over()` (`tests/test_generator.gd::_dead_ends_of` does it by the rect), so nothing lost an
answer.

## Rejected, with the reason

- **Deleting the recipe files' `city.dead_ends` pins with the captured set**: they are a recipe input, not the map's copy.
- A preference, not taken: the test's ternary as a two-entry dictionary of field to value.

## What stays open

Parts (b) and (c) of `dead-code-sweep.md`, which wait for the placement work.
