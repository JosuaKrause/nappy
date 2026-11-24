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

**Rejected.** A public `EventSpawner` method for where the engine stops: the spawner's own file is its only game reader, so
the test-only-members check lists it as own-file-only and refuses it. A public observer entry point for one frame of
watching: only the test would call it, which is no seam. The first form of the map method was the old static moved as it
was, right only from the sidewalk tile against the block; the review found it answered the opposite kerb's road tile
from the kerb-side tile. It now steps the tiles that remain of the sidewalk band, so from either sidewalk tile of a kerb
it answers the road tile against that kerb, and the game's own callers, which ask only from the tile against the block,
get the same point as before. The city map suite checks it from both sidewalk tiles of each side of a corridor on both
axes; the two kerb-side checks of each axis fail with the old step.

**Measured.** Outside the two suites the file keeps, both counting commands print nothing. The observers suite has
two checks more (the manager found, the warning put up), none dropped.
