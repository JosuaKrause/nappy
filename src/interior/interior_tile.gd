class_name InteriorTile
extends RefCounted
## The ground and elevation kinds an interior map is built from, and which of them a walker may
## stand on. Kept apart from `GameEnums.TileType`, which is the outdoor city's own vocabulary — a
## stairwell landing and a park tile share nothing worth a common name, and `CityMap`'s guarantees
## (route redundancy, the doorstep exemption) have no meaning inside a building with one way
## through it.

enum Kind {
	NONE,                  ## No floor and no wall: absent from a map's own `tiles`/`walls`.
	HALLWAY_FLOOR,          ## Plain hallway ground. Unused while the hallway is only two tiles
	                        ## deep — every row is one of the four edges below — kept for a wider
	                        ## hallway later.
	HALLWAY_FLOOR_EDGE_N,   ## Against the north wall.
	HALLWAY_FLOOR_EDGE_E,   ## Unused now that both hallway ends are doors — see
	                        ## `InteriorMap._build_hallway()`. Kept for a hallway that does not end
	                        ## in one.
	HALLWAY_FLOOR_EDGE_S,   ## The south edge; its own picture implies the apartment doors below
	                        ## the view.
	HALLWAY_FLOOR_EDGE_W,   ## Unused for the same reason as the east edge above.
	STAIRWELL_FLOOR,        ## The mechanical floor a `DOOR` tile's own threshold stands on.
	STAIR_FLIGHT_E,         ## A retained diagonal tread descending south-east, available to the
	                        ## tileset but currently unused.
	STAIR_FLIGHT_W,         ## Its retained mirror, available to the tileset but currently unused.
	STAIR_DOWN,             ## The basement entry's own stair: one level walkable cell seen from
	                        ## the front, its treads narrowing away from her. No slope, so a
	                        ## sideways press on it is a sideways step — see `flight_direction()`.
	LANDING,                ## The retained old flat stair platform kind, currently unused.
	STAIR_TOP_E,            ## `t`: the reviewed upper stair-side role, walkable toward east.
	STAIR_MIDDLE_E,         ## `m`: the reviewed lower stair-side role, walkable toward east.
	STAIR_TOP_W,            ## `T`: the mirrored upper role, walkable toward west.
	STAIR_MIDDLE_W,         ## `M`: the mirrored lower role, walkable toward west.
	STAIR_CORNER_E,         ## `c`: the east continuation triangle. Drawn, but not walkable.
	STAIR_CORNER_W,         ## `C`: its west mirror. Drawn, but not walkable.
	STAIR_BLOCK,            ## `b`: the 16px-deep top-edge side block. Drawn, but not walkable.
	BASEMENT_FLOOR,         ## The short jogs connecting one basement stretch to the next — see
	                         ## `InteriorMap._build_basement()`.
	BASEMENT_FLOOR_EDGE_N,
	BASEMENT_FLOOR_EDGE_E,
	BASEMENT_FLOOR_EDGE_S,
	BASEMENT_FLOOR_EDGE_W,
	PUDDLE,                 ## A decal over basement floor. Never placed as a `tiles` entry of its
	                         ## own — see `InteriorMapPlan.decals` — since it changes nothing about
	                         ## what is beneath it.
	DEBRIS,                 ## The same, for `basement_debris.svg`.
	RAT,                    ## The same, for `rat.svg`.
	WALL,                   ## Elevation, along a stretch's north edge. Never in `tiles`.
	WINDOW,                 ## Elevation, a wall column with a window. Never in `tiles`.
	WALL_LAMP,               ## Elevation, a wall sconce. Never in `tiles`.
	LIFT_DOOR,               ## Elevation, the dead lift. Never in `tiles`.
	ENTRANCE_DOOR,           ## Elevation, the lobby's own barricaded main entrance.
	ENTRANCE_BARRICADE,      ## Drawn in front of ENTRANCE_DOOR; not a `walls` column of its own —
	                         ## see `InteriorScene._rebuild_walls()`.
	BRICK_WALL,              ## Elevation, the basement's own wall material.
	DOOR,                    ## Walkable. The threshold between two maps — a hallway's end and its
	                         ## stairwell's landing, a stairwell's lowest landing and the lobby, or
	                         ## the lobby and the basement. One generic kind rather than one per
	                         ## pair, since every instance is the same picture and the same
	                         ## behaviour: see `InteriorMapPlan.Door`.
	EMERGENCY_EXIT,          ## The basement's own way out. Walkable, and ends the scene rather than
	                         ## leading to another map.
}

## Every kind that ever appears in a map's `tiles` dictionary is one she can stand on; a kind that
## only ever appears in `walls` (or is drawn as a decal, like PUDDLE, DEBRIS and RAT) is elevation
## or decoration and never walkable. Written as a lookup rather than a `match` over two dozen arms,
## so a kind newly added to `tiles` cannot be silently left off an arm nobody remembered to extend.
const _WALKABLE := {
	Kind.HALLWAY_FLOOR: true,
	Kind.HALLWAY_FLOOR_EDGE_N: true,
	Kind.HALLWAY_FLOOR_EDGE_E: true,
	Kind.HALLWAY_FLOOR_EDGE_S: true,
	Kind.HALLWAY_FLOOR_EDGE_W: true,
	Kind.STAIRWELL_FLOOR: true,
	Kind.STAIR_FLIGHT_E: true,
	Kind.STAIR_FLIGHT_W: true,
	Kind.STAIR_DOWN: true,
	Kind.LANDING: true,
	Kind.STAIR_TOP_E: true,
	Kind.STAIR_MIDDLE_E: true,
	Kind.STAIR_TOP_W: true,
	Kind.STAIR_MIDDLE_W: true,
	Kind.BASEMENT_FLOOR: true,
	Kind.BASEMENT_FLOOR_EDGE_N: true,
	Kind.BASEMENT_FLOOR_EDGE_E: true,
	Kind.BASEMENT_FLOOR_EDGE_S: true,
	Kind.BASEMENT_FLOOR_EDGE_W: true,
	Kind.PUDDLE: true,
	Kind.DOOR: true,
	Kind.EMERGENCY_EXIT: true,
}

static func is_walkable(kind: Kind) -> bool:
	return _WALKABLE.get(kind, false)

## `+1` if `kind` is a flight surface descending toward east, `-1` toward west, `0` for every
## other kind. The main shafts use both reviewed walkable roles in each direction; the basement's
## own entry stair answers `0`, because it is a level cell seen from the front rather than a
## diagonal tread and a sideways press on it has no slope to be redirected along. This is the one
## number `Stroller`'s own slope redirection needs; see `InteriorScene.slope_dir_at()`.
static func flight_direction(kind: Kind) -> int:
	if kind in [Kind.STAIR_FLIGHT_E, Kind.STAIR_TOP_E, Kind.STAIR_MIDDLE_E]:
		return 1
	if kind in [Kind.STAIR_FLIGHT_W, Kind.STAIR_TOP_W, Kind.STAIR_MIDDLE_W]:
		return -1
	return 0
