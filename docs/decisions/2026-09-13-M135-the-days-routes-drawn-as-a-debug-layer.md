## M135 — The day's routes drawn as a debug layer · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "can you add a debug overlay to show
paths (just as purple lines from tile center to tile center)".)* One agent commit and one
evidence commit on `feature/m135-route-lines`, reviewed on the PR; the still is
`evidence/m135-route-lines-2026-09-13/day1-layers5/`.

**A fifth layer, a sibling node.** `RouteLines` (`src/dev/route_lines.gd`) is a `Node2D` beside
`DebugLayers`, built by `main.gd` only in a debug build the same gated way, toggled by `5` and
started by `--layers 5` or `?layers=5`; `parse_layers()` accepts `5` and still drops `4`, the
readout's own key. It takes a `CityMap` and a `RouteTree` rather than the whole city, redraws
only when `main._start_day()` hands it the day's tree, and draws one polyline per route in the
dusk map's own corridor purple at the debug layers' line width, so the live overlay and the
dusk picture agree on what the corridor looks like.

**"Tile centre" is honoured at the ends and not in between.** The tree stores a route as
reachability-grid *cells*, two tiles across, and keeps no record of which tile of a cell a route
crossed (`DECISIONS.md`, M69), so the interior points are cell centres, 64px apart, rather than
tile centres. The two ends are real tiles: the doorstep tile the day starts on, and a calm tile
found by walking outward from the route's last cell the way `RouteTree._access_nodes()` walks
inward, since a route is stored only as far as the access cell outside the calm area. The test
caught the calm endpoint landing on a corner of the access cell itself when the area's open
rect clipped it, and the search now rejects any neighbour still inside that cell.

**The doorstep connector is a hop, not a step.** A branch rejoins the home frontage wherever
its probe happened to find it, never nearer than two cells from the doorstep's own cell over
301 routes measured, and the line is drawn from the fixed doorstep tile regardless, so its first
segment is a straight hop to wherever the tree joins home — visible in the still as lines
fanning out from the door across the street. The test asserts that segment's endpoint only.
Drawing from where the tree actually joins home instead is one line to change if the fan reads
as wrong. `tests/test_route_lines.gd` holds the rest: absent outside a debug build, one polyline
per route over six seeds and four days, first point on the doorstep tile's centre, last on a calm
tile, every interior step one cell apart, the calm connector at its exact distance.

**Open to overturn.** The purple and the width are reused constants rather than new ones; the
z-index is the debug layers' own; the cell-centre interior is the grain the tree has, and a
tile-level line would need the tree to record which tile of a cell it crossed.
