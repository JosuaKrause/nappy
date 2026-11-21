class_name BodyStance
extends RefCounted
## **Where a body built at a point stands on its street and how it lies on it**: the point it is
## recentred to, which axis its pieces are laid along, which of a street's two ways a parked vehicle
## shows, and the direction its spine runs. Pure geometry of a row and a map, holding nothing, so the
## dawn's planners (`PlanBuilder`, `WalkGround`), the spawner's record of a body, the live event
## (`EventInstance`, `EventBody`) and the developer's rigs all ask this one class and a planned
## body and its built one agree because both read it.
##
## It also lays out a body's pieces where they stand (`pieces_at()`, `pieces_laid_out()`): the one
## layout the dawn's walk (`WalkGround`), the map's record of standing bodies and the route rig ask,
## and a live body's own footprint is laid out by.
##
## The measuring of a row's pictures is not here: `EventFootprints` reads the baked pictures for
## the looks and the siting's drawn box. This reads the row's data and the map.

## **Where a body stands once it is built at `at`**, the one reading every place that needs it asks:
## `at` moved to the middle of its pavement band when the row is a stationary solid body that
## `pavement_side` does not pin to an edge and that does not span the street
## (`EventDef.stands_on_its_band_middle()`, `_centred_on_the_pavement_band()`); otherwise where the
## lattice puts it (`EventPlan.stands_without_a_map()`): on the kerb beside its carriageway lane for
## a row that stands at its kerb, the roadblock, and `at` itself for any other.
## `EventInstance.setup()` and `move_to()` stand the body there, the scheduler's and the walk's
## siting of its band and the body's recorded footprint (`EventSpawner.obstructed_footprint()`) read
## it for a body not yet built, so a body moved after dawn stands where the record says it does.
## **A point already stood is returned as it is** (standing it again gives the same point), so a
## caller holding a live body's own position asks it as it asks a build point.
static func stands_at(map: WorldMap, row: EventDef, at: Vector2) -> Vector2:
	if row.stands_on_its_band_middle():
		return _centred_on_the_pavement_band(map, at)
	return EventPlan.stands_without_a_map(row, at)

## **A pavement is one piece of walkable ground, not two lanes a body has to fit inside one of.**
## `EventScheduler` places a stationary body at `map.tile_to_world(tile)` — the centre of whichever
## of the pavement's two lanes the scheduler happened to choose, 16px from that lane's own edge and
## 48px from the far one — so a body sized against the *pavement* rather than the *lane* overhangs
## by exactly the asymmetry between those two numbers (PLAYTEST-19).
##
## The remedy is the position, not a smaller radius: this shifts a stationary, unpinned body from
## the lane tile the scheduler chose to the middle of the two-lane band it belongs to, so a body may
## be up to the full `SIDEWALK_WIDTH * TILE_SIZE` (64px) wide and exactly fill the pavement.
##
## **Exempt: anything `pavement_side` pins to an edge on purpose.** `delivery_van` belongs at the
## kerb and `reversing_lorry` belongs against the building — re-centring either would undo the one
## thing `pavement_side` exists to do. Both stay exactly where `PlanBuilder.build()`
## put them, still measured against the same 64px band: a kerbed `VEHICLE_BODY` (44px) leaves a
## 26px gap to the frontage, narrower than the 28px pram, which is how `docs/EVENTS.md`'s
## `delivery_van` row reads that placement — a **wall** by physical fit, so a van at the kerb is
## *also* "no line to walk," on purpose.
static func _centred_on_the_pavement_band(map: WorldMap, at: Vector2) -> Vector2:
	var tile := map.world_to_tile(at)
	if map.pavement_inward(tile) == Vector2i.ZERO:
		# Not a pavement tile at all, or a junction belonging to both corridors at once — nothing
		# here has one band to be centred on.
		return at
	var offsets := map.corridor_offsets(tile)
	var x_offset := offsets.x
	var offset := x_offset if x_offset >= 0 else offsets.y
	var band_offset := Tuning.SIDEWALK_WIDTH * 0.5 if offset < Tuning.SIDEWALK_WIDTH \
			else float(Tuning.STREET_WIDTH) - Tuning.SIDEWALK_WIDTH * 0.5
	var along := Vector2.RIGHT if x_offset >= 0 else Vector2.DOWN
	# The band's middle lies on the line between two lanes, which belongs to the lane past it. A point
	# already stood sits exactly there, half a tile before that lane's own middle, so it is where
	# the body stands and is returned as it is: standing it again would read the lane past the line
	# and move it half a tile toward the other lane.
	var from_the_lane_middle := (at - map.tile_to_world(tile)).dot(along)
	if is_equal_approx(offset, band_offset) \
			and is_equal_approx(from_the_lane_middle, -Tuning.TILE_SIZE * 0.5):
		return at
	var shift := (band_offset - offset - 0.5) * Tuning.TILE_SIZE
	return at + along * shift

## **A spread's rotation is a property of the street it stands on**, not a field on the row: a
## barrier that lies correctly across a north-south street lies along the kerb — parallel to the
## traffic, blocking nothing — on an east-west one, unless the direction it spreads in changes with
## the street. `CityMap.corridor_offset` answers which axis a tile's corridor runs on without
## caring what the tile's *type* is, so a `ROAD` tile (`checkpoint`, a barricade seal across a
## street) is asked exactly the way a `SIDEWALK` tile is, with no second lookup for either
## (`WorldMap.corridor_offsets()`).
##
## A tile whose two coordinates are **both** inside a corridor band is a junction — belonging to
## two streets at once, with no single direction to be wrong about — and a tile whose coordinates
## are **neither** is off any corridor at all: a square, a park, a courtyard. Both keep the spread's
## default lay along local X, the smallest answer for ground that is not a street to lie across.
static func lies_vertically_at(map: WorldMap, at: Vector2) -> bool:
	var tile := map.world_to_tile(at)
	var alley := map.alley_at(tile)
	if alley.has_area():
		# An alley's barrier closes its short mouth, so a horizontal alley gets a vertical
		# spread and a vertical alley keeps the default horizontal spread.
		return alley.size.x > alley.size.y
	var offsets := map.corridor_offsets(tile)
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	return on_an_east_west_street and not on_a_north_south_street

## Whether a stationary vehicle is seen side-on at this point. The moving van faces along the
## street and the burnt car lies across it (`EventDef.lies_across_its_street`). A junction or ground outside the lattice has
## no single street axis, so the vehicle's own facing supplies the coherent default.
static func stands_side_on(row: EventDef, map: WorldMap, at: Vector2, face: Vector2) -> bool:
	var offsets := map.corridor_offsets(map.world_to_tile(at))
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	if on_a_north_south_street != on_an_east_west_street:
		var parallel_side := on_an_east_west_street
		return not parallel_side if row.lies() == EventDef.Lie.ACROSS else parallel_side
	return absf(face.x) >= absf(face.y)

## The ground-plane direction a row's solid body's spine lies along, for whichever of the three
## families ever has a segment shape: a car that drives (`EventDef.vehicle`), along its own
## `heading`; a spread-drawn row, down the screen on a street laid that way (`spread_vertical`) and
## across it otherwise; or the one stationary-vehicle row wide enough to be a segment (`moving_van` —
## see `GroundShape.band()` on that row), which lies along whichever of the street's axes it is drawn
## on (`side_on`, `stands_side_on()`). Never asked of a point shape, where an axis means nothing.
static func solid_axis_of(row: EventDef, heading: Vector2, spread_vertical: bool,
		side_on: bool) -> Vector2:
	# A car's body lies along the way it is driving, and turns with it (`EventCarDriving.turn_the_body()`).
	if row.drives():
		return heading.normalized() if not heading.is_zero_approx() else Vector2.RIGHT
	if row.lies() == EventDef.Lie.SPREAD or row.lies() == EventDef.Lie.ALONG:
		return Vector2.DOWN if spread_vertical else Vector2.RIGHT
	return Vector2.RIGHT if side_on else Vector2.DOWN

## The ground-plane direction a sited body's spine lies along — `solid_axis_of()` for a body that does
## not exist yet, off the same two statics its instance would read about the street at `placed`.
static func _body_axis(map: WorldMap, row: EventDef, placed: Vector2, facing: Vector2) -> Vector2:
	return solid_axis_of(row, facing, lies_vertically_at(map, placed),
			stands_side_on(row, map, placed, facing))

## **The pieces of a body of `row` built at `at` and sited facing `facing`, each where it stands**: the
## body stood where `stands_at()` puts it, laid along its street (`lies_vertically_at()`), its spine
## along `_body_axis()`, and each of its pieces (`EventDef.body_pieces()`) offset along the street's
## axis by the piece's own reading of the picture in use. Nothing for a row with no body or no ground
## shape. It does not filter a row that moves or a door's body: each caller asks for the rows it
## counts. The one layout of a body not yet built, or built and recorded: the walk's ground, the
## map's record of standing bodies and the route rig all ask it, so the three cannot disagree.
static func pieces_at(map: WorldMap, row: EventDef, at: Vector2,
		facing: Vector2) -> Array[StandingPiece]:
	var none: Array[StandingPiece] = []
	if row.ground_shape() == null or not row.has_a_body():
		return none
	var stands := stands_at(map, row, at)
	return pieces_laid_out(row, stands, _body_axis(map, row, stands, facing),
			lies_vertically_at(map, stands))

## **The pieces of `row`'s body standing at `center`**, its spine along `axis` and laid down the
## screen when `vertical`: each piece offset along that axis by its own reading of the picture in use
## (`EventDef.SolidPart.offset_for()`). For a body whose stance is already decided, a live one's own
## (`EventFootprints.solid_footprint_of()`, laid round its origin); `pieces_at()` decides it first.
static func pieces_laid_out(row: EventDef, center: Vector2, axis: Vector2,
		vertical: bool) -> Array[StandingPiece]:
	var laid: Array[StandingPiece] = []
	for piece in row.body_pieces():
		var offset := piece.offset_for(vertical)
		laid.append(StandingPiece.new(
				center + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0)),
				piece.ground_shape(), axis))
	return laid
