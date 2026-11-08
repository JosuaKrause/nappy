# The other facts derived in more than one place

**The ask.** "try finding more such cases -- that's a code smell" (inbox #1156 in gray-dolphin). On the board's
re-derived-state-cases, "yes" to the order picked: what blocks the way and the door flag in the live
form after dawn; two cases with the dawn plan object; three cases one small pull request each; one
case once the plan object exists (inbox #1156 in gray-dolphin).

**Read as:** one fact derived from raw data in more than one place, or a private method re-deriving
what another place already worked out, is moved into one object that derives it once and is handed
to whoever asks (designing-classes). The dawn cases were built with `DayEvents`, `CalmAreas` and
`DayRepairs` (#1158); the after-dawn cases are `walk-placed-blockers.md`.

**What is left: three cases, as the orchestrator's notes name them, and the gatehouse day's last
readers.** The survey that described the cases is gone, and the board's numbering of them (3, 4, 6
and 7 among them) was not kept with the names, so which number each is cannot be told from what is
on disk. Each case is found again, with its places in the code, before it is designed. Where to look
first:

- **The stand point of a moved body:** where a body moved after dawn (`EventManager.move_extra()`)
  stands, which the move works out and the park cordon's own standing search
  (`ParkCordon._standing_point()`) works out again.
- **The held streets' reasons:** which street segments are held and why, which `CityMap.is_held()`
  and `is_held_at()` answer and `CrowdPockets._shut_the_held_segments()` and
  `ResistanceSteps.stands_on_held_ground()` read again for themselves.
- **The gatehouse day's last readers:** the day's spec answers whether the region wall stands
  today (`DaySpec.region_wall_stands()`), and three places still compare the day with
  `Tuning.REGION_WALL_FIRST_DAY` (day 9) instead of asking it, each in a file the day's events after
  dawn (#1169) holds:
  - `RegionPlanner.plan_day(map, day, tree)`, which plans no wall and no doors before day 9,
    becomes `plan_day(map, spec, tree)`. Each caller hands the spec: `DayPlanner`,
    `City._close_streets()`, `RecipeCityBuilder`'s region plan, `ClosurePlanner.plan_day()`'s
    fallback when no region plan is handed in, and the tests; `City.start_recipe_day()` has no spec
    and is given one.
  - `SceneRecipeRuntime._select_structures()`, which refuses a recipe's gates and barriers before
    day 9.
  - `EventCatalogue._guardsmen_from_day()`, the day the pursuer on foot becomes a guardsman, which
    whoever picks the pursuer asks the spec for instead. The escape's spec answers no while its
    events run on calendar day 14, where the comparison says yes, so the change confirms the
    escape's pursuer on foot stays what it is (no escape row has one today).
- **The ground cache:** which tiles each row may stand on (`EventScheduler.open_ground_for()`), a
  per-day cache `build_day()` builds at dawn and each `WalkSiting` builds again for itself.
