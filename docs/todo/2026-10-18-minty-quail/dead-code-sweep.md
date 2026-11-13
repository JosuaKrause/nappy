# Code nothing reaches, and code for features the game no longer has, is deleted

**The ask.** "remove dead code or code needed for features that don't exist anymore. it adds to the
cost of maintaining the code base and confuses you. if we want a feature back we can just implement
it fresh which also guarantees that it adheres to the new design principles" (inbox #1180 in gray-dolphin).

**Read as:** code nothing reaches, and code that only serves a feature the game no longer has, is
deleted rather than kept; a feature wanted back is built fresh under the current design. The rule
is designing-classes'. This item is the sweep, across `src/` and `tools/`, one module per pull
request.

*Proposed, not asked for:* the method. Start from `tools/check_test_only_members.py`'s no-reader group
(members nothing under `src/` reads) and the members only their own file uses, then the catalogue
rows and the branches no catalogue row reaches. A name in a comment is not a use: the survey is
run with comments stripped, since a first survey that counted them missed four members
(minty-quail-misty-ferret). Each deletion says in its pull request what reached
the code last, or that nothing ever did.

**Where the rest is** (the survey with `check_test_only_members.py` and a scan for members named
nowhere in `src/`, `tests/`, `tools/` or `scenes/`; no module holds more than a few):
- `src/events/`: `EventsAhead.walk_siting()` (test-only), which hands out the day's walk siting
  (`EventScheduler.WalkSiting`) so its suites can read the work the siting did: it stays until step
  4 of polite-tapir's `placement-by-construction.md`, which replaces the walk's old siting roll, and
  goes with that step (`tests-unseen-reads.md`, `tests-public-seams.md`).
- `src/events/`: `EventScheduler._calm_rect()`, which nothing under `src/` calls; only the probe
  `tests/probes/m97_spoilage.gd` does, and a comment in `src/routes/closure_planner.gd` still cites
  it. It goes with the probe's call, the comment rewritten in the same pull request.
- `src/city/`: the city map's industrial-block count for the power station
  (`CityMap._power_station_industrial_blocks`, the recipe key `power_station_industrial_blocks`), which the generator
  writes and the map's copy, capture and restore and the scene recipe files only carry: nothing reads it. Deleting it
  changes the recipe format, the files under `scene-recipes/` and `RecipeCityContext.validate()` with it.
- `src/city/`: the map's own set of dead-end streets (`CityMap._dead_ends`), which the generator writes and the map's
  copy, capture and restore and the recipe context's saved map (its `dead_ends` set in `RecipeCityContext.SETS`) only
  carry; the game reads a dead end off the streets built over (`TelemetryMap`). A recipe's own `city.dead_ends` pins
  are live, since the generator walls where they say, and stay. Deleting the set changes the saved map's format.
