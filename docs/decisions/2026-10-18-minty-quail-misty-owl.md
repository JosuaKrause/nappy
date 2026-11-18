# minty-quail — The city map's fields read through its methods outside the events · 2026-11-18

**What it is.** Part of minty-quail's `field-reads.md` bullet "The city's own classes": the city
map's (`CityMap`) fields read from outside its file by the routes (the region and seal planners), the
blackout, the streamed ground, the generator, the run flow, the developer's rigs and the day planner.
An Opus builder designed and built it. It changes nothing in play; tests change only where a field
they read went private.

**What was built.** Most readers now call methods the map already had (`city_seed()`,
`home_block_coordinate()`, `precinct_stretches()`, `alley_lots()`, `street_network()`,
`plans_by_block()`, `fenced_park_block()` and the rest); the map gains readers and writers for the
region planner (`square_lots()`, `region_of_node()`, `region_has_calm()`, `wall_stands_at_a()`,
`record_junction_regions()`, `record_calm_regions()`, `record_wall_ends()`), the generator
`record_home_block()`, the day director `fenced_park_act()`, and `soft_sealed_tiles()` is a method. Ten
fields are private (`seed_used`, `home_block`, `precinct_spans`, `alley_rects`, `big_buildings`,
`zone_rects`, `fenced_park`, `fenced_park_act`, `region_of_junction`, `region_has_calm`), and
`BlockedLayer.replace_soft_sealed_tiles()`, which nothing called, is deleted. `tools/field_reads.txt`
lost 30 lines and gained none.

**What is left of the map's part:** the fields the events read (`network`, `main_road`,
`block_plans`, `calm_blocks`, `closed_tiles`, `power_station`, `boundary_wall_at_a`,
`square_rects`, `playgrounds`), which stay public until the events' pass, and the scene recipes'
draft and runtime reads, whose tests set state no game method sets.

**Proposed, not asked for, open to the player:** keeping the fields the events read public rather
than one-token edits in six event files outside this pull request's fence; converting the day
planner's `home_block` read but not its `network` read, which would pull about 130 test reads in;
leaving the scene recipes' reads for the tests-one-module item or row 3c of `event-interface.md`. The
city skill's street-hierarchy sentence names `CityMap.precinct_stretches()` where it named the field.
