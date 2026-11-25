# minty-quail — The gatehouse day's last readers ask the day's spec · 2026-11-08

minty-quail's `re-derived-cases.md`, the gatehouse day's last three readers, in #1251. The fact
(whether the region wall stands today) is the day's spec's since record minty-quail-spotted-elk
(`DaySpec.region_wall_stands()`); three places still compared the day with
`Tuning.REGION_WALL_FIRST_DAY` (day 9).

**Built.**
- **`RegionPlanner.plan_day(map, spec, tree)`** asks the spec; its callers hand it (`DayPlanner`,
  `City._close_streets()`, `ClosurePlanner`'s fallback, `RecipeCityBuilder`, the tests).
  `City.start_recipe_day()` takes the spec as an optional last parameter, `DaySpec.for_day(day)` when
  left out, and `DayDirector.start_authored_day()` hands the walk's.
- **`SceneRecipeRuntime._select_structures()`** asks the walk's spec before allowing a recipe's gates
  and barriers.
- **`EventCatalogue._guardsmen_from_day()` is deleted:** `on_foot_on(spec)` and
  `out_of_the_car(spec, stops)` ask the spec, which `EventsAhead` holds for the walk
  (`EventManager.use_the_spec()` hands it in through `use_the_walk_of()`).

**Measured.** The placement fingerprint is byte-identical to main's (15787 placements).

**Changed on purpose:** the escape's authored city scene, a scene recipe run under the escape city's
spec, plans no region wall and refuses gates and barriers, since that spec answers no where calendar
day 14 said yes; the escape's own walk never plans the wall and has no pursuer on foot.

**Choices where the design was silent, open to overturn:** `start_recipe_day()` keeps its day and
takes the spec beside it (the escape city's spec carries its own day while the calendar's is 14);
`EventsAhead` answers with no wall until a spec is handed in.
