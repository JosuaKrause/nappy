class_name InteriorFloor
extends RefCounted
## One floor's plan: a sparse grid of `InteriorTile.Kind`, the wall run along its hallway's north
## edge, and the handful of named positions `InteriorScene` and `tests/test_interior.gd` both
## need — the start tile, each stairwell's door and lower-landing tile, and (basement only) the
## exit. Built once by `InteriorMap.build()`; nothing here mutates it afterwards.

## One of a floor's two stairwells — the escape scene has exactly one at each end of the hallway.
class Stairwell:
	var side := ""  ## "left" or "right", matching the hallway end it opens off.
	var door_tile := Vector2i.ZERO
	## `Vector2i(-1, -1)` on the basement, which has nothing further down — see
	## `InteriorMap._carve_stairwell()`'s own doc for why a stairwell may be built without one.
	var lower_landing_tile := Vector2i(-1, -1)

	func has_flights() -> bool:
		return lower_landing_tile != Vector2i(-1, -1)

## `InteriorMap.FloorKind`, kept as a plain `int` rather than the enum type — a `class_name`
## parameter typed to another script's nested enum is the cross-script enum trap the godot skill
## warns about, so every signature that crosses a file boundary widens to `int` and only the
## owning file's own code reads it as the enum.
var kind := 0
## Tile position -> `InteriorTile.Kind`, for every walkable and non-walkable-but-standable
## interior cell this floor actually has (door thresholds included). A position absent from this
## dictionary has no floor at all and is therefore not walkable — see `is_walkable()`.
var tiles: Dictionary = {}
## Column -> `InteriorTile.Kind`, the wall standing in elevation along the hallway's north edge.
## Not part of `tiles`: nothing ever stands *on* a wall cell, so a wall needs a column to be drawn
## at rather than a floor-grid position.
var north_wall: Dictionary = {}
var start_tile := Vector2i.ZERO
var stairwells: Array[Stairwell] = []
## `Vector2i(-1, -1)` on every floor but the basement.
var exit_tile := Vector2i(-1, -1)
## The column the entrance stands at, or `-1` on every floor but the ground floor — read by the
## renderer to place the barricade and by tests that assert what stands in the wall there.
var entrance_column := -1
## Basement-only ground decals; never a `tiles` entry of its own — see `InteriorTile.Kind.PUDDLE`.
var puddle_tiles: Array[Vector2i] = []

func is_walkable(tile: Vector2i) -> bool:
	return InteriorTile.is_walkable(tiles.get(tile, InteriorTile.Kind.NONE))

## The stairwell on `side` ("left" or "right"), or `null` if asked for a side this floor does not
## have — which never happens in practice, since `InteriorMap.build()` always carves both.
func stairwell(side: String) -> Stairwell:
	for s in stairwells:
		if s.side == side:
			return s
	return null
