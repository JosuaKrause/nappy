class_name InteriorMapPlan
extends RefCounted
## The escape scene's whole building as **one** map: a sparse grid of `InteriorTile.Kind` cells
## holding all seven parts — three hallways, two stairwells, the lobby and the basement — laid out
## with wide unwalkable gaps between them, joined only by doors that teleport rather than by a
## shared floor. *(2026-09-10, playtest 55: "instead of multiple maps have all parts of the house
## on the same map with enough space inbetween and on transition fade to black, teleport, then
## fade in again".)* Built once by `InteriorMap.build()`; nothing here mutates it afterwards.
##
## **There is no "current part".** A door does not load or free anything — it moves her, the same
## map open the whole time — so the only state a transition touches is her own position and the
## camera that follows it. See `docs/TODO.md`, "M112 — The escape scene, walkable" for the brief.

## A threshold that teleports to another door's own tile — or, for the basement's
## `EMERGENCY_EXIT`, to the title screen instead, which is not a `Door` at all; see
## `InteriorScene._start_exit()`.
class Door:
	var id := ""              ## Globally unique — "hallway_third:left", "stairwell_left:landing_third".
	var tile := Vector2i.ZERO ## Where this door's threshold stands.
	var target_door := ""     ## The id of the door this one teleports to.

## Tile position -> `InteriorTile.Kind`, for every walkable and non-walkable-but-standable
## interior cell any part actually has (door thresholds included). A position absent from this
## dictionary has no floor at all and is therefore not walkable — see `is_walkable()`. The gaps
## between parts are exactly the positions absent here.
var tiles: Dictionary = {}
## A wall-anchor position -> `InteriorTile.Kind`, elevation drawn at that cell's own north edge.
## Not part of `tiles`: nothing ever stands *on* a wall cell, so a wall needs a position to be
## drawn at rather than a floor-grid position.
var walls: Dictionary = {}
## Where a fresh run starts — the third floor's own door, mid-hallway on its south edge.
var start_tile := Vector2i.ZERO
## `id -> Door`, every door in the building.
var doors: Dictionary = {}
## `Vector2i(-1, -1)` unless the basement's own exit has been placed.
var exit_tile := Vector2i(-1, -1)
## Every barricaded entrance position — read by the renderer to place the barricade and by tests
## that assert what stands in the wall there. Only the lobby has one, but keyed by position rather
## than held as a single field, the same reasoning `walls` already follows now that everything
## shares one coordinate space.
var entrance_tiles: Array[Vector2i] = []
## Ground decals — `PUDDLE`, `DEBRIS` or `RAT` — that change nothing about what is walkable
## beneath them. `tile -> InteriorTile.Kind`.
var decals: Dictionary = {}
## Cells that are not floor (absent from `tiles`, so `is_walkable()` still says no and no flood
## fill ever steps onto one) but must not get a collision blocker either — the two cells flanking
## each diagonal step between two walkable tiles, which touch each other only at a single corner
## point. A circular body of any real radius cannot cross a corner pinched between two full-tile
## blockers on both flanks, so `InteriorMap._mark_diagonal_clearances()` frees them after every
## part is laid, and `InteriorScene._rebuild_collision()` skips them the same way it skips `tiles`.
var collision_clearance: Dictionary = {}
## A named position that is not a door — a stairwell's own landing platform, a hallway's mid-point,
## the lobby's own floor — used both as `--start-escape <part>`'s teleport target and, in
## `tests/test_interior.gd`, as the seed a per-part flood fill starts from. `id -> Vector2i`.
var waypoints: Dictionary = {}

func is_walkable(tile: Vector2i) -> bool:
	return InteriorTile.is_walkable(tiles.get(tile, InteriorTile.Kind.NONE))

func door(id: String) -> Door:
	return doors.get(id)
