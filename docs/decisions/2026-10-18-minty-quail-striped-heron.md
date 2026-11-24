# minty-quail — The last three private reaches in tests go (tests-public-seams) · 2026-11-23

**What was asked.** `tests-public-seams.md`: a test reaches the game through what the game offers and lets
real frames pass (inbox #1156 and #1159 in gray-dolphin; curly-rabbit #1098). Built as #1682 by a Sonnet agent, for
the three breaches its counting commands still printed.

**What was built.** Where a summoned row stops, the kerb across the street from a point, is a question of the city
map (`CityMap.kerb_across_from()`, beside `pavement_inward()`): the spawner asks it, and the two event manager
suites and two probes ask it too, instead of the spawner's private method. The roadblock test helper takes its host
event when it is made. The observers suite reaches the screen-edge badge with a real fire-engine warning and two real
frames instead of calling the observer's frame function by hand; shown failing with the badge no longer handing the
warning on.

**Measured.** Outside the two suites the file keeps, both counting commands print nothing. The observers suite has
two checks more (the manager found, the warning put up), none dropped.
