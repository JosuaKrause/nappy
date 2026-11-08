# minty-quail — Placement by construction, second step: day 13's swap takes a section · 2026-11-08

minty-quail's `placement-by-construction.md`, its second pull request, #1249. The design is
`docs/EVENTS.md`'s "The three views and the placement order" (inbox #1185).

**Built.**
- **Day 13's task, with no roadblock close by along her paths** (576, 896, then 1,024px from where
  she reads the chalk mark), takes the nearest open route-adjacent section along her paths whose
  roadblock and contents are out of her view, and replaces the section's content with a roadblock,
  the whole section (`ResistanceDirector._section_to_swap()`, `DayLocations.nearest_section_in()`,
  `EventsAhead.swap_in_a_section()`, `EventStreaming.swap_section()`). No distance cap: where the
  close-by paths reach no section, her paths over the whole city are walked. The roadblock stands on
  the section's carriageway tile nearest its middle (`EventScheduler.across_the_section()`), never the
  main road, judged by nothing.
- **The day's locations reach the walk** with the day's plan (`DayEvents.locations()`,
  `DayPlanner.Plan.locations()`, `WalkEvents.locations()`), so the swap reads the sections dawn
  assigned.

**Deleted** with the tile swap: `Planned.may_be_replaced()`, `_has_noticed_her()`,
`EventInstance.has_noticed_her()`, `ResistanceDirector._places_to_swap()`, `WalkSiting.in_place_of()`,
`_tiles_in_place_of()`, `SWAP_SPREAD_TILES`, the three `stands_beside_the_routes()`,
`Corridor.is_beside_the_routes(tile)`, `EventStreaming.swap()`, `EventsAhead.swap_in_a_task_row()`
and `tests/test_walk_siting_in_place_of.gd`; `test_walk_siting_spec`'s check that `in_place_of()`
keeps the walk's home-street rule went with it, no other siting giving it a placement to aim.

**Measured.** On 480 real chalk marks (20 seeds, 24 marks; `tests/probes/minty_quail_day13_real_marks.gd`)
the task finds a roadblock at 440 (median 410px straight-line from the mark) and swaps at 40 (median
924px, farthest 2,113px); none misses, where the tile swap missed 33.

**The fixed parts are never taken** (the player: they "each get phases during either dawn or
beginning of the game", inbox #1185): the region wall's bodies, a door's, a seal (soft seals
included, which stand on streets no hold closes; `Planned.stand_as_a_seal()`), a mast, an ambient
row (`Planned.is_a_fixed_part()`). The burnt shell is a regular event ("your scars are just regular
events", inbox #1185), so its section may be taken. A swap leaves the map's bodies and shut tiles as
they were, minus the section's, plus the roadblock's.

**Readings, open to correction:** the nearest section along her paths, an undrawn one taking the
roadblock like any other (the player: the task searches "closeby" first).

**Not built:** a scene's day 13 never swaps, since a scene's walk has no day's locations; day 13's
scene authors its own roadblock.

**For the end-of-refactor remeasure:** day 13's swaps (how often, how far), the walk to a far-off
swapped roadblock, and the swap's cost on the frame she reads the mark (median 35ms, at most 41ms,
the whole-city walk 33ms of it; a found roadblock 4ms).
