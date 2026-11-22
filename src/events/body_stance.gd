class_name BodyStance
extends RefCounted
## **How a body built at a point stands on its street**, derived once from the row, the map, the
## build point and the way the body was sited facing, and then handed round: where its center
## stands, whether it lies down the screen, whether a vehicle standing still shows its side, the
## direction its spine lies along, and its pieces where they stand. The dawn's planners
## (`PlanBuilder`, `WalkGround`), the spawner's record of a body, the live event
## (`EventInstance`, `EventBody`), its look and its footprint and the developer's rigs all read
## one value, so a planned body and its built one agree because both are the same derivation.
##
## **A stance is made from a build point and never from another stance** (`of()`, `of_plan()`):
## the point a body is built at is moved to where it stands, and a stance holds the point it was
## moved to. A body that moves to other ground (`EventInstance.move_to()`) is given a stance made
## from the point it is moved to. Standing a point already stood gives the same point, so a
## successor built where its predecessor stood (`EventSpawner.successor_of()`) stands there too.
##
## Two questions stay statics, both about a street rather than a body: where the lattice alone
## stands a body (`stands_without_a_map()`, which a plan, holding no map, asks) and whether a
## street lies down the screen (`lies_vertically_at()`, which the developer's rig asks as well).
##
## The measuring of a row's pictures is not here: `EventFootprints` reads the baked pictures for
## the looks and the siting's drawn box. This reads the row's data and the map.

## The row this stance is of: whether its body drives, how it lies, the pieces it is made of.
var _row: EventDef
## Where its center stands, the build point moved to where the row stands a body.
var _center := Vector2.ZERO
## Whether it lies down the screen rather than across it, the street's own direction.
var _vertical := false
## Whether a vehicle standing still shows its side rather than its end.
var _side_on := true
## The way it was sited facing, which a car that drives lies along and a body on a junction or on
## ground outside the lattice takes its side from.
var _facing := Vector2.RIGHT
## The direction its spine lies along on its street, for every row but a car that drives.
var _street_spine := Vector2.RIGHT
## The pieces it is made of laid round the origin along its street's spine, made the first time
## they are asked for and kept: a body that does not drive never turns.
var _round_the_origin: Array[StandingPiece] = []

## Not asked for directly: `of()` and `of_plan()` are how a stance is made.
func _init(row: EventDef, center: Vector2, vertical: bool, side_on: bool,
		facing: Vector2) -> void:
	_row = row
	_center = center
	_vertical = vertical
	_side_on = side_on
	_facing = facing
	_street_spine = _spine_on_its_street(row, vertical, side_on)

## **How a body of `row` built at `at` and sited facing `facing` stands**: its center where
## the row stands it (`_stood_at()`), and, read at that point, the way its street runs
## (`lies_vertically_at()`) and the side a vehicle standing still shows. `EventInstance.setup()`
## and `move_to()` stand the live body from it, the scheduler's and the walk's siting of its band
## and the body's recorded footprint (`EventSpawner.footprint_of()`) read it for a body not
## yet built, so a body moved after dawn stands where the record says it does.
static func of(map: WorldMap, row: EventDef, at: Vector2, facing: Vector2) -> BodyStance:
	var center := _stood_at(map, row, at)
	return BodyStance.new(row, center, lies_vertically_at(map, center),
			_stands_side_on(row.body(), map, center, facing), facing)

## **How a planned body stands once it is built**: `of()` of where its plan was placed
## (`EventPlan.placed_at()`) and the way it is sited facing (`EventPlan.faces()`), the one
## stance the walk's ground, the plan builder (`PlanBuilder.body_stands_at()`) and the route rig
## ask. `EventInstance.setup()` stands the built body from the same point. A plan's route does
## not enter into it: every plan that carries one starts its route where it was placed (the
## director's and the finale's are made at `path[0]`, the plan builder's along-street route
## starts at the placed tile), and no row is planned cross-street, the one route that starts
## elsewhere.
static func of_plan(map: WorldMap, plan: EventPlan) -> BodyStance:
	return of(map, plan.row(), plan.placed_at(), plan.faces())

## **Where a body of `row` built at `at` stands, as far as the lattice says without a map**: on
## the kerb beside its carriageway lane when the row stands at its kerb
## (`EventDef.stands_at_its_kerb()`, the roadblock, `CityMap.kerb_beside()`), otherwise `at`.
## The one place that decides the kerb: `of()` starts from it, and the plan's own reading of
## where its body stands (`EventPlan.body_at()`) asks it. **A plan's own reading stays without
## the move onto a sidewalk band's middle**: the move needs the pavement, which a plan holds no
## map to read, keeps a body on its own sidewalk, at most half a tile across it, and the day's
## rules have always read a sidewalk body where it was placed; the kerb changes what a band
## covers, the street's far sidewalk, and so is read here.
static func stands_without_a_map(row: EventDef, at: Vector2) -> Vector2:
	return CityMap.kerb_beside(at) if row.stands_at_its_kerb() else at

# ------------------------------------------------------------------ questions ---

## The row it is the stance of.
func row() -> EventDef:
	return _row

## Where its center stands: the build point moved to the middle of its pavement band when the
## row is a stationary solid body that `pavement_side` does not pin to an edge and that does not
## span the street (`EventDef.stands_on_its_band_middle()`), to the kerb beside its carriageway
## lane for a row that stands at its kerb, and the build point itself for any other.
func center() -> Vector2:
	return _center

## Whether it lies down the screen rather than across it, as its street runs
## (`lies_vertically_at()`): never a per-row field, since two rows on the same street face the
## same way for the same reason, and a row that had to say so itself could disagree with the
## street it was actually placed on.
func lies_vertically() -> bool:
	return _vertical

## Whether a vehicle standing still shows its side rather than its end: the moving van stands
## along its street while the burnt car lies across it, and a junction, off-street ground or
## open ground follows its facing.
func stands_side_on() -> bool:
	return _side_on

## The direction its spine lies along while it heads along `heading`: the heading for a car that
## drives (`EventDef.drives()`; the way it is driving, turned by
## `EventCarDriving.turn_the_body()`), and its street's lay for every other row, whatever the
## heading: a spread-drawn row down the screen on a street laid that way and across it
## otherwise, a stationary vehicle along whichever of the street's axes it shows. Never asked of
## a point shape, where an axis means nothing.
func spine_along(heading: Vector2) -> Vector2:
	if _row.drives():
		return heading.normalized() if not heading.is_zero_approx() else Vector2.RIGHT
	return _street_spine

## **Its pieces where they stand**, each at its own offset along its street's axis from where its
## center stands (`BodySpec.pieces()`, each by its own reading of the picture in use), its spine
## along `spine_along()` the way it was sited facing. Nothing for a row with no body or no ground
## shape. It does not filter a row that moves or a door's body: each caller asks for the rows it
## counts. The one layout of a body not yet built, or built and recorded: the walk's ground, the
## map's record of standing bodies and the route rig ask it, so the three cannot disagree.
func pieces() -> Array[StandingPiece]:
	var none: Array[StandingPiece] = []
	if _row.ground_shape() == null or not _row.has_a_body():
		return none
	return pieces_at(_center, _facing)

## **Its pieces laid out round `center`**, a body that is standing or driving there and heading
## along `heading`: the one layout, which a live body's own footprint and its shadow are laid
## out by round the origin, and a live body's solid pieces by round where it is now. A new array
## every time.
func pieces_at(center: Vector2, heading: Vector2) -> Array[StandingPiece]:
	return _laid_out(center, spine_along(heading))

## Its pieces laid out round the origin along its street's spine, made once and kept: what its
## shadow is drawn from on every frame for a body that does not drive. **Read only**: the array
## is the one the stance keeps, so a caller that changed it would change every later answer. A
## car that drives has its pieces laid out for each heading (`pieces_at()`).
func round_the_origin() -> Array[StandingPiece]:
	if _round_the_origin.is_empty():
		_round_the_origin = _laid_out(Vector2.ZERO, _street_spine)
	return _round_the_origin

# ---------------------------------------------------------------- private ---

## The pieces of its body each offset along its street's axis from `center`, their spines along
## `spine`.
func _laid_out(center: Vector2, spine: Vector2) -> Array[StandingPiece]:
	var laid: Array[StandingPiece] = []
	for piece in _row.body().pieces():
		var offset := piece.offset_for(_vertical)
		laid.append(StandingPiece.new(
				center + (Vector2(0.0, offset) if _vertical else Vector2(offset, 0.0)),
				piece.ground_shape(), spine))
	return laid

## Where a body of `row` built at `at` stands: `at` moved to the middle of its pavement band
## (`_centred_on_the_pavement_band()`) when the row stands on its band's middle, otherwise where
## the lattice puts it (`stands_without_a_map()`).
static func _stood_at(map: WorldMap, row: EventDef, at: Vector2) -> Vector2:
	if row.stands_on_its_band_middle():
		return _centred_on_the_pavement_band(map, at)
	return stands_without_a_map(row, at)

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
	var across := Vector2.RIGHT if x_offset >= 0 else Vector2.DOWN
	# Worked out from the coordinate, as `CityMap.kerb_beside()` is, not from the tile: the point's
	# place across the street in tiles is its tile's offset plus how far into the tile it lies, and
	# it moves by what is left to the band's middle, so a point already there moves nothing.
	var coordinate := at.x if x_offset >= 0 else at.y
	var into := float(offset) + fposmod(coordinate, float(Tuning.TILE_SIZE)) / float(Tuning.TILE_SIZE)
	return at + across * (band_offset - into) * Tuning.TILE_SIZE

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
## street and the burnt car lies across it (`BodySpec.lies()`). A junction or ground outside the
## lattice has no single street axis, so the vehicle's own facing supplies the coherent default.
static func _stands_side_on(body: BodySpec, map: WorldMap, at: Vector2, face: Vector2) -> bool:
	var offsets := map.corridor_offsets(map.world_to_tile(at))
	var on_a_north_south_street := offsets.x >= 0
	var on_an_east_west_street := offsets.y >= 0
	if on_a_north_south_street != on_an_east_west_street:
		var parallel_side := on_an_east_west_street
		return not parallel_side if body.lies() == BodySpec.Lie.ACROSS else parallel_side
	return absf(face.x) >= absf(face.y)

## The direction a row's spine lies along on its street, for every row but a car that drives: a
## spread-drawn row, down the screen on a street laid that way (`vertical`) and across it
## otherwise, or the one stationary-vehicle row wide enough to be a segment (`moving_van`, see
## `GroundShape.band()` on that row), along whichever of the street's axes it is drawn on
## (`side_on`).
static func _spine_on_its_street(row: EventDef, vertical: bool, side_on: bool) -> Vector2:
	var lies := row.body().lies()
	if lies == BodySpec.Lie.SPREAD or lies == BodySpec.Lie.ALONG:
		return Vector2.DOWN if vertical else Vector2.RIGHT
	return Vector2.RIGHT if side_on else Vector2.DOWN
