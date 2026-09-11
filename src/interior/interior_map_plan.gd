class_name InteriorMapPlan
extends RefCounted
## One map's plan — a hallway floor, a stairwell shaft, the lobby or the basement: a sparse grid of
## `InteriorTile.Kind` cells, the elevation standing along it, its doors to other maps, and the
## handful of named positions `InteriorScene` and `tests/test_interior.gd` both need. Built once by
## `InteriorMap.build()`; nothing here mutates it afterwards.
##
## The building has seven of these, joined only through `doors` — never by a shared coordinate
## space, since each map is its own small grid with its own origin. See `docs/TODO.md`, "M112 —
## The escape scene, walkable" for the brief this lays out.

## A threshold to another map — or, for the basement's `EMERGENCY_EXIT`, to the title screen
## instead, which is not a `Door` at all; see `InteriorScene._start_exit()`.
class Door:
	var id := ""                ## Unique within this map's own `doors` — "left", "landing_third".
	var tile := Vector2i.ZERO   ## Where this door's threshold stands on this map.
	## `InteriorMap.MapKind`, kept as a plain `int` — a `class_name` parameter typed to another
	## script's nested enum is the cross-script enum trap the godot skill warns about, so every
	## signature that crosses a file boundary widens to `int` and only `InteriorMap` itself reads
	## it as the enum.
	var target_map := 0
	var target_door := ""       ## The id of the door on `target_map` this one connects to.

## `InteriorMap.MapKind` as a plain `int` — see `Door.target_map`'s own doc for why every
## cross-file reference to the enum widens rather than naming it.
var kind := 0
## Tile position -> `InteriorTile.Kind`, for every walkable and non-walkable-but-standable
## interior cell this map actually has (door thresholds included). A position absent from this
## dictionary has no floor at all and is therefore not walkable — see `is_walkable()`.
var tiles: Dictionary = {}
## A wall-anchor position -> `InteriorTile.Kind`, elevation drawn at that cell's own north edge.
## Not part of `tiles`: nothing ever stands *on* a wall cell, so a wall needs a position to be
## drawn at rather than a floor-grid position. Generalised from a single column dictionary (every
## wall used to stand along row 0) to a full `Vector2i` now that the basement's corridor carries a
## wall along more than one row — "raw brick walls... in elevation along each stretch's north
## edge," each stretch's own row.
var walls: Dictionary = {}
var start_tile := Vector2i.ZERO
## `id -> Door`, this map's own thresholds.
var doors: Dictionary = {}
## `id -> Vector2i`, named positions that are not doors — a stairwell's own landing platforms,
## where its flights meet. Kept apart from a door's own tile, which stands one step to the side of
## a landing rather than on it (see `InteriorMap._build_stairwell()`): continuing down the flights
## crosses every landing without ever standing on the door that opens off it, so passing floor 2 on
## the way to floor 1 never opens floor 2's own door underfoot.
var waypoints: Dictionary = {}
## `Vector2i(-1, -1)` on every map but the basement.
var exit_tile := Vector2i(-1, -1)
## The column the entrance stands at, or `-1` on every map but the lobby — read by the renderer to
## place the barricade and by tests that assert what stands in the wall there.
var entrance_column := -1
## Ground decals — `PUDDLE`, `DEBRIS` or `RAT` — that change nothing about what is walkable
## beneath them. `tile -> InteriorTile.Kind`.
var decals: Dictionary = {}

func is_walkable(tile: Vector2i) -> bool:
	return InteriorTile.is_walkable(tiles.get(tile, InteriorTile.Kind.NONE))

func door(id: String) -> Door:
	return doors.get(id)
