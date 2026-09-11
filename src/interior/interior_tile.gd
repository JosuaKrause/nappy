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
	STAIR_FLIGHT_E,         ## A walkable tread tile. Its picture drops one tile height over one
	                        ## tile width toward the south-east, so a run of them is a diagonal
	                        ## line — see `InteriorMap._lay_flight()`.
	STAIR_FLIGHT_W,         ## The same, toward the south-west.
	LANDING,                ## The flat platform at a switchback's turn, or a lower landing that
	                         ## doubles as the next floor's own top landing.
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
	Kind.LANDING: true,
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

## `+1` if `kind` is a flight tile descending toward east (`STAIR_FLIGHT_E`), `-1` toward west
## (`STAIR_FLIGHT_W`), `0` for every other kind — including `LANDING`, which is flat. The one
## number `Stroller`'s own slope redirection needs; see `InteriorScene.slope_dir_at()`.
static func flight_direction(kind: Kind) -> int:
	if kind == Kind.STAIR_FLIGHT_E:
		return 1
	if kind == Kind.STAIR_FLIGHT_W:
		return -1
	return 0
