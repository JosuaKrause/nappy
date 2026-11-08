# minty-quail — Placement by construction, first step: the streets' locations and the roadblock phase · 2026-11-08

minty-quail's `placement-by-construction.md`, its first pull request, #1248. The design is
`docs/EVENTS.md`'s "The three views and the placement order" (inbox #1185).

**Built.**
- **A street's view is decided in one place,** `Corridor.view_of(segment)` (`PlacementView` in the
  data layer): a route street is on the route on both sidewalks; a street touching a route junction
  is route-adjacent, park and alley cuts included; every other street is off the route.
- **Every street is laid out at dawn on day 13, in this step** (`DayLocations`, `StreetLocations`, `Location`; the city's
  streets from `CityMap.street_segments()`): three sections of 3, 2 and 3 tiles, two sidewalk locations in
  each, each location told its view once. Sections on closed or held streets (closures, hard seals,
  the region wall and its doors, the home's streets) are unavailable. A street-spanning event
  (`EventDef.spans_the_street()`, the roadblock) takes a whole section.
- **The roadblock phase replaces day 13's dawn roadblock pass** (`RoadblockPhase`, handed a
  `RoadblockGround`): it draws among every route-adjacent section offered a valid roadblock,
  weighted by the squared distance to the nearest roadblock already placed (the first uniform; the
  exponent is proposed, not asked for), never the main road; taken sections are assigned for the day.
  Once a roadblock stands, no section within 256px of it is offered one (`EVENT_SPACING_SAME`, today's
  spacing as what makes a location invalid). It stops at full coverage (every route tile within
  1,024px along her paths), when no offered section would cover a route tile left uncovered, or at 25.
  On the six probe seeds it placed 17 to 25, at least 258px apart; three reached full coverage, two
  stopped with no section able to cover the tiles left, and one stopped at 25 with 54 of 1,738 route
  tiles uncovered.
- `tests/probes/placement_view_mix.gd` counts today's events per day by view and row, for the bags'
  weights.

**Readings of the player's words, open to correction** (each in the description and in
`docs/EVENTS.md`): both sidewalks of a route street are on the route (the restaurant example);
`Corridor.is_beside_the_routes()` decides route-adjacent; the roadblock phase is day 13's; its three
stops; the spacing rule as an invalidation; the cap of 25 (the top of the 15 to 25 the player called
good), asked on the board.

**Kept for test parity, to go with the fill:** the fill still rolls roadblocks on day 13. Without
them, on seed 90210 the phase left 71 of 1,827 route tiles with no roadblock close by and the chalk
mark with nothing near and nothing the current swap takes; the section swap covers such a mark.
`tests/test_day13_guard.gd` picks her standing ground by the guard's own clear line, and its two
scenarios that need another roadblock choose one meeting their premise, since the roadblocks now
stand elsewhere; every assertion is unchanged. The layout is built on day 13 only in this step.

**For the end-of-refactor remeasure:** day 13's roadblocks (how many, where, their spread, how many
route tiles are left with none close by); the task's close-by hits and swaps on the 480 real chalk
marks (`tests/probes/minty_quail_day13_real_marks.gd`); the dawn phase no longer preferring the
roomiest tile; route costs and winnability, expected unchanged, since every roadblock the phase
places is route-adjacent.
