class_name InteriorTile
extends RefCounted
## The ground and elevation kinds an interior floor plan is built from, and which of them a
## walker may stand on. Kept apart from `GameEnums.TileType`, which is the outdoor city's own
## vocabulary — a stairwell landing and a park tile share nothing worth a common name, and
## `CityMap`'s guarantees (route redundancy, the doorstep exemption) have no meaning inside a
## building with one way through it.

enum Kind {
	NONE,                 ## No floor and no wall: absent from a floor's own `tiles`/`north_wall`.
	HALLWAY_FLOOR,         ## Plain hallway ground. Unused while the hallway is only two tiles
	                       ## deep — every row is one of the four edges below — kept for a wider
	                       ## hallway later.
	HALLWAY_FLOOR_EDGE_N,  ## Against the north wall.
	HALLWAY_FLOOR_EDGE_E,  ## The hallway's east end cap.
	HALLWAY_FLOOR_EDGE_S,  ## The south edge; its own picture implies the apartment doors below
	                       ## the view.
	HALLWAY_FLOOR_EDGE_W,  ## The hallway's west end cap.
	STAIRWELL_FLOOR,       ## The mechanical floor a stairwell door's own threshold stands on.
	STAIR_FLIGHT_E,        ## A walkable tread tile, descending toward east.
	STAIR_FLIGHT_W,        ## A walkable tread tile, descending toward west.
	LANDING,               ## The flat platform between two flights, or a lower landing that
	                       ## triggers the transition to the floor below.
	BASEMENT_FLOOR,        ## Unused for the same reason as HALLWAY_FLOOR — see above.
	BASEMENT_FLOOR_EDGE_N,
	BASEMENT_FLOOR_EDGE_E,
	BASEMENT_FLOOR_EDGE_S,
	BASEMENT_FLOOR_EDGE_W,
	PUDDLE,                ## A decal over basement floor. Never placed as a `tiles` entry of its
	                       ## own — see `InteriorFloor.puddle_tiles` — since it changes nothing
	                       ## about what is beneath it.
	WALL,                  ## Elevation, along a hallway's north edge. Never in `tiles`.
	WINDOW,                ## Elevation, a wall column with a window. Never in `tiles`.
	LIFT_DOOR,             ## Elevation, the dead lift. Never in `tiles`.
	ENTRANCE_DOOR,         ## Elevation, the ground floor's barricaded main entrance.
	ENTRANCE_BARRICADE,    ## Drawn in front of ENTRANCE_DOOR; not a `north_wall` column of its
	                       ## own — see `InteriorScene._rebuild_walls()`.
	BRICK_WALL,            ## Elevation, the basement's own wall material.
	STAIRWELL_DOOR,        ## The threshold between a hallway and its stairwell. Walkable.
	EMERGENCY_EXIT,        ## The basement's way out. Walkable, and a transition trigger.
}

## Every kind that ever appears in a floor's `tiles` dictionary is one she can stand on; a kind
## that only ever appears in `north_wall` (or is drawn as an overlay, like PUDDLE and
## ENTRANCE_BARRICADE) is elevation or decoration and never walkable. Written as a lookup rather
## than a `match` over two dozen arms, so a kind newly added to `tiles` cannot be silently left
## off an arm nobody remembered to extend.
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
	Kind.STAIRWELL_DOOR: true,
	Kind.EMERGENCY_EXIT: true,
}

static func is_walkable(kind: Kind) -> bool:
	return _WALKABLE.get(kind, false)
