# minty-quail — Placement by construction, first step: the streets' locations and the roadblock phase · 2026-11-08

minty-quail's `placement-by-construction.md`, its first pull request, #1248. The design is
`docs/EVENTS.md`'s "The three views and the placement order" (inbox #1185).

**Built.**
- **A street's view is decided in one place,** `Corridor.view_of(segment)` (`PlacementView` in the
  data layer): a route street is on the route on both sidewalks; a street touching a route junction
  is route-adjacent, park and alley cuts included; every other street is off the route.
- **Every street is laid out at dawn** (`DayLocations`, `StreetLocations`, `Location`; the city's
  streets from `CityMap.streets()`): three sections of 3, 2 and 3 tiles, two sidewalk locations in
  each, each location told its view once. Sections on closed or held streets (closures, hard seals,
  the region wall and its doors, the home's streets) are unavailable. A street-spanning event
  (`EventDef.spans_the_street()`, the roadblock) takes a whole section.
- **The roadblock phase replaces day 13's dawn roadblock pass** (`RoadblockPhase`, handed a
  `RoadblockGround`): it draws among route-adjacent sections weighted by the squared distance to the
  nearest roadblock already placed, the first uniform, a section in the draw only where today's rules
  accept a roadblock on the tile nearest its middle, never the main road; taken sections are assigned
  for the day; it stops once every route tile has a roadblock within 1,024px along her paths.
- `tests/probes/placement_view_mix.gd` counts today's events per day by view and row, for the bags'
  weights.

**Readings of the player's words, open to correction** (each in the description and in
`docs/EVENTS.md`): both sidewalks of a route street are on the route (the restaurant example);
`Corridor.is_beside_the_routes()` decides route-adjacent; the roadblock phase is day 13's, with
today's stop.

**Kept for test parity, to go with the fill:** the fill still rolls roadblocks on day 13. Without
them, on seed 90210 the phase left 71 of 1,827 route tiles with no roadblock close by and the chalk
mark with nothing near and nothing the current swap takes; the section swap covers such a mark.
`tests/test_day13_guard.gd` picks her standing ground by the guard's own clear line, since the
roadblock it finds stands where the band and the bodies round it make the map's line differ.
