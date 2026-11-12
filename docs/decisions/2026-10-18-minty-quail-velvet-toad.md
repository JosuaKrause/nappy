# minty-quail — The routes ask the city map, the route tree and the block layout through methods · 2026-11-12

**The ask.** One object reaches another only through its methods (designing-classes, "Fields are not API"; inbox #1173
in gray-dolphin), and `field-reads.md` converts the readers layer by layer.

## What was built

- **The routes' closure planner, route tree, corridor and reachability grid read the city map, the map interface, the
  route tree and a block layout through methods**, and their 16 lines leave `tools/field_reads.txt`. Eleven of the reads
  use a method that already existed.
- **Two methods are new, each called by the game**: `CityMap.shut_calm()`, the calm areas taken off today's route tree,
  which `RouteTree` asks when it chooses the areas to grow through, so the field goes private as `_shut_calm`; and
  `RouteTree.reachability_grid()`, the grid the tree was grown on, which `Corridor.of()` asks. The field `grid` stays
  public while `EventScheduler` reads it, so the method cannot take its name yet.
- **Three fields the game now reads only by name** (`CityMap.absent_segments`, `power_station_door`,
  `BlockLayout.open_rect`, which `RecipeCityContext` captures and restores by string) stay public, and the suites that
  read or wrote them go through the game's own methods instead, so the test-only check does not list them.
- **Left**: the region and seal planners' reads, which `field-reads.md` keeps with the lines
  the placement rewrite and the third hand-ins pull request touch; `CityMap.fenced_park`, read by the day director,
  which waits for the third hand-ins pull request.

## Verified

`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the routes', the city map's,
the closures' and the touched suites pass; CI is green.
