class_name CrowdLanes
extends RefCounted
## The lane geometry of the street grid, for anything that travels along it.
##
## The city is a lattice of corridors, each `sidewalk | road | sidewalk` across. A lane is
## one tile-wide strip of one of those bands, running the length of a corridor. This is the
## single place that converts between "corridor 3, offset 4" and a world coordinate, so the
## crowd never has to re-derive the layout arithmetic that `CityMap` already owns.

## Sidewalk offsets across a corridor, outermost first on each side. Four lanes of pavement
## per corridor is what makes a busy street look busy rather than look like a queue.
##
## Walkers have **no side convention**: a pedestrian picks any of the four and either direction.
## They are not mirrored the way the carriageway is — they are simply unordered, which is a
## different thing and not a bug. Giving them one would be a design change with a measured cost:
## the contact numbers the pavement is balanced on (eleven bumps down a lane centre against one on
## the midline) assume a walker may be coming the other way in any lane.
const SIDEWALK_OFFSETS: Array[int] = [0, 1, 4, 5]

## How far each footway lane is pushed away from the middle of its own footway, in px.
##
## **The careful line has to be wide enough to aim at.** A contact fires inside `BUMP_RADIUS` of a
## lane centre, so the line with no contact on it is `TILE_SIZE - 2 * BUMP_RADIUS` wide — at tile
## centres, **four pixels**. The crowd is built on "careless is expensive and careful is free", and
## a careful half nobody can aim at is one they can only occasionally be on: measured over three
## seeds, forty seconds down an arterial lane centre costs 13.7 contacts and the midline costs 0.0,
## which is 148 points of a 100 meter riding on those pixels.
##
## Pushing the two lanes of a footway apart widens that line without touching `BUMP_RADIUS`, which
## is the honest direction: the body stays the size it is drawn and the *street* is what changes.
## At 8 the clear line is 20px — she aims at the middle of the pavement and gets it — and the
## lanes sit 8px inside the footway's own edges, so nobody walks in a wall or off a kerb.
##
## It is deliberately **not** applied in a precinct: `PRECINCT_OFFSETS` is six lanes across a
## street with no carriageway in it, so there are no footways to have a middle, and the pairs the
## spread would make are arbitrary. `walker_lane_centre` takes the lane list for that reason.
const SIDEWALK_LANE_SPREAD := 8.0
## And the same for a precinct, which has no carriageway between its two footways: every tile
## across it is somewhere a person may be. Without its own list it inherits the street's, and the
## middle of a pedestrianised street is then empty — not a steering bug, simply nowhere anything
## was ever placed, because those two offsets are the carriageway on every other street.
const PRECINCT_OFFSETS: Array[int] = [0, 1, 2, 3, 4, 5]

## The lanes a walker may use in a corridor: the whole width of a precinct, the two footways of
## anything else.
static func walkable_offsets(map: CityMap, vertical: bool, index: int,
		along_tile: int) -> Array[int]:
	if map.street_kind(vertical, index, along_tile) == GameEnums.StreetKind.PEDESTRIAN:
		return PRECINCT_OFFSETS
	return SIDEWALK_OFFSETS
## The two carriageway lanes, across the corridor: `ROAD_OFFSETS[0]` is the one with the smaller
## cross-axis coordinate. Which way each runs depends on the **axis** — see `road_direction()`.
const ROAD_OFFSETS: Array[int] = [2, 3]

## How much busier the arterial is than an ordinary street. This file is the only place that says
## which corridor is the main road; two answers to that question is one too many.
##
## **The share is taken over the streets the player can see, not over the city**, because the crowd
## is populated around her — so this weight buys much more traffic than the same number would over
## sixteen corridors. Push it and the arterial has a safe gap in it under one percent of the time,
## with a mean wait at the kerb of twenty-two seconds out of a hundred and eighty.
##
## A road you have to wait for is the hazard it is meant to be. A road that can only be crossed at
## a zebra is *also* fine — traffic gives way there, and the generator puts one at every junction,
## so nowhere on a street is more than seven tiles from one. What is not fine is a road that cannot
## be crossed at all and does not say so.
##
## At 5.0 the arterial keeps the noise floor it has to keep (see `tests/test_crowd.gd`, "a busy
## street never lets the meter fall") and jaywalking it is a real gamble rather than an
## impossibility. Measured with a probe, not derived; re-measure if the population moves.
const ARTERIAL_BUSYNESS := 5.0

## Corridors per axis: one on each side of every block, so one more than there are blocks.
static func corridor_count(axis_blocks: int) -> int:
	return axis_blocks + 1

## World coordinate of the centre of the lane at `offset` in corridor `index`.
##
## The tile centre, which is where a **car** drives and where a footway's own edges are measured
## from. A walker stands `SIDEWALK_LANE_SPREAD` off it — see `walker_lane_centre`, and note that
## `CrowdAgent._pavement_band` deliberately keeps using this one, because the band is the extent
## of the pavement rather than the extent of the lanes on it.
static func lane_centre(index: int, offset: int) -> float:
	return (index * CityMap.period() + offset + 0.5) * Tuning.TILE_SIZE

## Where a walker in that lane actually walks: the tile centre, pushed toward the near edge of its
## own footway so the two lanes of a pavement leave a gap between them worth aiming at.
##
## `offsets` is the lane list the walker was chosen from, so a precinct — which has six lanes and
## no footways — is left alone. Offsets 0 and 4 are the outer lane of their footway and 1 and 5 the
## inner one, which is what the parity test reads.
static func walker_lane_centre(index: int, offset: int, offsets: Array[int]) -> float:
	var centre := lane_centre(index, offset)
	if offsets.size() != SIDEWALK_OFFSETS.size():
		return centre
	return centre + (SIDEWALK_LANE_SPREAD if offset % 2 == 1 else -SIDEWALK_LANE_SPREAD)

## Corridor index a world coordinate falls in, or -1 when it is inside a block.
static func corridor_at(world_coordinate: float) -> int:
	var tile := floori(world_coordinate / Tuning.TILE_SIZE)
	if CityMap.corridor_offset(tile) < 0:
		return -1
	return floori(float(tile) / CityMap.period())

## The sidewalk lane nearest a world coordinate within corridor `index`. Used when a walker
## turns a corner: it keeps to the pavement it is already standing on rather than snapping
## across the road.
static func nearest_sidewalk(index: int, world_coordinate: float) -> int:
	var best := SIDEWALK_OFFSETS[0]
	var best_distance := INF
	for offset in SIDEWALK_OFFSETS:
		var distance := absf(lane_centre(index, offset) - world_coordinate)
		if distance < best_distance:
			best_distance = distance
			best = offset
	return best

## Which way traffic runs in a carriageway lane: +1 along the axis, -1 against it.
##
## **The city drives on the right, and that is a rule about the side of the road relative to
## travel, not about the offset.** It flips with the axis. A fixed rule like `offset == 3 means
## positive` is right-hand traffic on the east-west streets and left-hand traffic on the
## north-south ones, and **nothing in the suite can see it**: separation, headway, capacity and
## noise are all true either way, and a still frame does not say which way a car is pointing. It
## shows up the moment a human watches a junction.
##
## Screen coordinates have Y pointing down, so along a **vertical** corridor +1 is south and the
## driver's right is west — the *smaller* cross coordinate. Along a **horizontal** one +1 is east
## and their right is south — the larger. Hence the flip.
static func road_direction(vertical: bool, offset: int) -> float:
	var positive_lane := ROAD_OFFSETS[0] if vertical else ROAD_OFFSETS[1]
	return 1.0 if offset == positive_lane else -1.0

## The inverse: which lane a car travelling `direction` along this axis belongs in. Written as
## the pair of one function so the two can never drift — a car that turns a corner picks its
## lane from its new direction, and a car that spawns picks its direction from its lane.
static func road_lane(vertical: bool, direction: float) -> int:
	var positive_lane := ROAD_OFFSETS[0] if vertical else ROAD_OFFSETS[1]
	return positive_lane if direction > 0.0 else (ROAD_OFFSETS[0] + ROAD_OFFSETS[1] - positive_lane)

## The corridor the arterial runs down, for one axis.
static func arterial_index(axis_blocks: int) -> int:
	return axis_blocks / 2

## How busy a corridor is, relative to an ordinary street. Seeded from the city rather than
## the day, because it is a property of the city: the same street is busy every morning, and
## learning which ones are quiet is most of what a fixed city is *for*.
##
## The plain form is the pavement's answer. `busyness_for` is the one anything placing an agent
## should ask, because the two populations do not want the same streets: a precinct is the busiest
## pavement in the city and has no cars on it at all.
##
## **It takes the map, because "which corridor is the main road" is a fact about a city and not
## about an axis.** Answering it as `index == arterial_index(blocks)` — with `blocks` from whichever
## axis is being asked about — weights the middle corridor of **each** axis at `ARTERIAL_BUSYNESS`,
## and the city then has one main road you can see and two the traffic believes in, with the
## weighting measured for one street spent on two. Measured that way over five seeds, the phantom
## east-west arterial held **14.6 cars against the spine's 11.2**: more traffic on the street with
## no lights, no dark asphalt and no clearway than on the one that has all three.
##
## `street_kind`, `GroundTiles`, `TrafficSignals` and `decay_multiplier` all ask the map. This is
## the fourth place that has to agree with them and the easiest one to leave behind.
static func busyness(map: CityMap, vertical: bool, index: int) -> float:
	if vertical and index == map.main_road:
		return ARTERIAL_BUSYNESS
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("busy:%d:%s:%d" % [map.seed_used, "v" if vertical else "h", index])
	return rng.randf_range(0.5, 1.7)

## How busy a corridor is *for one kind of traffic*.
##
## A pedestrianised street is the whole reason this is not one number. There is no carriageway on
## it, so a car's weight there is zero — not low, zero, because a car that picks it has nowhere
## legal to be and diverts out on its first frame, which reads as cars appearing in a precinct
## and immediately leaving. Its pavement, meanwhile, is the busiest in the city, which is the
## other end of the trade it offers: nothing on it can kill you and a great deal of it is in
## your way.
static func busyness_for(map: CityMap, vertical: bool, index: int, cars: bool) -> float:
	for span in map.precinct_spans:
		if (span.x == 1) != vertical or span.y != index:
			continue
		# Walkers only. A precinct is three blocks of an otherwise ordinary street, so the cars
		# keep their weight and divert at the bollards; what changes is that the corridor is now
		# the busiest pavement in the city, and because the crowd is a box around the player,
		# "busiest corridor" delivers its people to wherever on it she is standing.
		if not cars:
			return Tuning.PRECINCT_BUSYNESS
	return busyness(map, vertical, index)

## A corridor chosen in proportion to how busy it is. This is what makes a route decision
## out of a grid: a uniform crowd would make every street equally loud, and then there would
## be nothing to choose between them.
static func pick_corridor(rng: RandomNumberGenerator, map: CityMap, vertical: bool,
		cars: bool) -> int:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	return pick_corridor_in_range(rng, map, vertical, Vector2i(0, corridor_count(blocks) - 1),
			cars)

## The same, restricted to an inclusive range of corridor indices — the streets that are
## actually inside the crowd's field.
##
## The weighting survives the restriction, and that is the point of doing it this way rather
## than picking uniformly among the few streets in view: the arterial is still the busy one
## when it is one of three corridors on screen, so a player who has learned which street is
## loud is still right about it.
##
## A window with no weight in it at all is possible and is not an error — a car whose field only
## reaches precincts — so it falls back to the first corridor rather than dividing by nothing.
## The caller re-rolls anyway; see `CrowdAgent._recycle`.
static func pick_corridor_in_range(rng: RandomNumberGenerator, map: CityMap, vertical: bool,
		range_inclusive: Vector2i, cars: bool) -> int:
	var lo := range_inclusive.x
	var hi := maxi(lo, range_inclusive.y)
	var total := 0.0
	for index in range(lo, hi + 1):
		total += busyness_for(map, vertical, index, cars)
	if total <= 0.0:
		return lo
	var target := rng.randf() * total
	for index in range(lo, hi + 1):
		target -= busyness_for(map, vertical, index, cars)
		if target <= 0.0:
			return index
	return hi

## A point on the pavement beside the north-south arterial, half way down the map. The one
## place the crowd's noise floor is highest, which makes it the place worth measuring.
static func arterial_pavement(map: CityMap) -> Vector2:
	var x := map.main_road * CityMap.period() + Tuning.SIDEWALK_WIDTH - 1
	return map.tile_to_world(Vector2i(x, map.size.y / 2))

## The same, for whichever north-south corridor this city made the quietest.
static func quietest_pavement(map: CityMap) -> Vector2:
	var count := corridor_count(Tuning.CITY_BLOCKS.x)
	var quietest := 0
	for index in count:
		if busyness(map, true, index) < busyness(map, true, quietest):
			quietest = index
	var x := quietest * CityMap.period() + Tuning.SIDEWALK_WIDTH - 1
	return map.tile_to_world(Vector2i(x, map.size.y / 2))
