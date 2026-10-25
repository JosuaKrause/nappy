class_name WalkGround
extends RefCounted
## **The walk stays open past everything that stands on it**: every street of the walk keeps one
## sidewalk walkable from junction to junction, and nothing standing cuts the walk anywhere else —
## asked of each candidate before it is accepted and never repaired afterwards (`docs/CITY.md`,
## "Check before accepting"). *(Inbox #747: "one sidewalk must be open if they're en-route. the
## escape's street should not have fully blocking events like in the normal game.")* One rule, asked
## by the event scheduler's own judge (`EventScheduler._best_of()`) of any walk whose spec keeps it
## (`DaySpec.keeps_the_walk_open`), stated over the walk it is handed (`RouteSource`): its streets,
## where it starts and where it has to get to.
##
## It holds the ground of the walk with everything that stands on it for the whole walk: the seals
## first, then each placement as it is accepted (`catch_up()`).
##
## **The two halves are the two things a day keeps a route by.** The sidewalk is the day's width
## rule (`EventScheduler._leaves_the_routes_sidewalk_open()`), asked of both of a street's sidewalks
## rather than the one a day's route is walked along — `leaves_a_sidewalk_open()`. The rest of the
## walk is the day's junction rule (`EventScheduler._leaves_the_route_junctions_open()`), asked of the
## ground around the candidate rather than of a junction box — `keeps_the_walk_joined()`. The day's
## rules themselves are stated over a day's `Corridor`, which a walk that is not a tree has none of;
## and the junction rule alone would not be enough if it could: a chain also joins a street in the
## middle of a block, out of an alley, a park or a courtyard, and a van and a roadblock either side
## of that mouth shut it while the street's far sidewalk stays open from junction to junction.
##
## **Everything is counted as it stands for the whole walk, at the body it actually has.** A van
## that hunts stays parked and solid until long after it has noticed her, a roadblock's band stands
## after its guard has left (`EventInstance._stand_as_the_barrier()`), and a burst leaves its
## crater where it went off for the rest of the sequence — so a row that spawns a solid successor
## is counted at the successor's body too (`solids_of()`). Mobile rows are traffic and close no
## ground. Each body is where `EventInstance.setup()` will put it — recentred on the pavement band,
## laid along the street's own spread axis, in its own pieces — rather than a disc at the tile it
## was rolled on, because the half tile between the two is what decides whether a lane survives.
##
## **And a lethal reach that stands is counted as ground she cannot cross** (`held_by()`): the van's
## 54px, round where it is parked, takes her however open the ground under it is, so a sidewalk kept
## open past the van's 22px body but not past its reach is a walk that ends the section. A reach that
## moves — a pursuer's, which warns before it charges — is the fairness contract's, not ground.
##
## **The seals are counted like everything else.** They stand on the streets and alleys the walk
## does not use, but an alley's mouth wall (`SealPlanner.alley_mouth_wall()`) lies along the street
## the alley opens onto, and with her body on top it reaches the outer lane of that street's
## sidewalk for about six tiles — so a walk's street with an unused alley beside it has that much
## less sidewalk before anything of the walk's own is put down.

## One solid piece of something that stands for the whole walk, where it actually stands:
## `EventInstance.solid_part_centres()`, `solid_part_shapes()` and `solid_axis()` for a body that
## does not exist yet, off the same statics the instance reads when it is built.
class Solid extends RefCounted:
	## How far apart a capsule's covering discs may be — see `discs()`. At 8px a 24px-round band's
	## discs are a third of a pixel wider than the band.
	const DISC_PITCH := 8.0

	var centre := Vector2.ZERO
	var shape: GroundShape
	var axis := Vector2.RIGHT
	## The furthest her centre can be held off from `centre`, squared: the quick refusal
	## `stops_her_at()` asks before measuring against the spine.
	var _held_within_squared := 0.0
	var _rounding := 0.0

	func _init(at: Vector2, piece_shape: GroundShape, along: Vector2) -> void:
		centre = at
		shape = piece_shape
		axis = along.normalized()
		_rounding = shape.radius if shape.kind != GroundShape.Kind.RECT else 0.0
		var held := shape.reach() + Tuning.PLAYER_BODY_RADIUS
		_held_within_squared = held * held

	## Whether her centre at `at` is held off by this piece: inside its body grown by her own
	## `Tuning.PLAYER_BODY_RADIUS`, measured against the spine in the piece's own frame.
	func stops_her_at(at: Vector2) -> bool:
		var offset := at - centre
		if offset.length_squared() >= _held_within_squared:
			return false
		var local := Vector2(offset.dot(axis), offset.dot(Vector2(-axis.y, axis.x)))
		return shape.distance_to_spine(local) < _rounding + Tuning.PLAYER_BODY_RADIUS

	## Whether any of the piece's body comes within `margin` of `rect`.
	func reaches(rect: Rect2, margin: float) -> bool:
		return rect.grow(shape.reach() + margin).has_point(centre)

	## The piece as discs, `Vector3(x, y, radius)`, for `closes_a_walked_sidewalk_band()`, which
	## asks about discs. **A cover, never an approximation from inside**: a capsule is laid as
	## discs at most `DISC_PITCH` apart along its spine, each grown to the half-pitch's diagonal so
	## the gaps between them are covered too, and a rectangle as the one disc of its own reach.
	func discs() -> Array[Vector3]:
		match shape.kind:
			GroundShape.Kind.POINT:
				return [Vector3(centre.x, centre.y, shape.radius)]
			GroundShape.Kind.SEGMENT:
				var along := axis * shape.half_length
				var count := ceili(shape.half_length * 2.0 / DISC_PITCH) + 1
				var pitch := shape.half_length * 2.0 / float(count - 1)
				var grown := Vector2(shape.radius, pitch * 0.5).length()
				var found: Array[Vector3] = []
				for i in count:
					var at := centre - along + along * (2.0 * float(i) / float(count - 1))
					found.append(Vector3(at.x, at.y, grown))
				return found
			_:
				return [Vector3(centre.x, centre.y, shape.reach())]

## The pitch of the lattice her centre is asked about on, a quarter of a tile: fine enough that
## a gap her 28px body fits through has a point in it, and the same lattice
## `tests/test_finale.gd` floods the finished plan over.
const STEP := 8.0
## The side of the square buckets standing pieces are filed in, so a question about one
## candidate's ground reads the handful of bodies near it rather than all of them.
const _CHUNK := 128.0
## `_fits` values: not asked yet, her body fits on the ground there, it does not.
const _UNASKED := 0
const _FITS := 1
const _DOES_NOT_FIT := 2

var _map: CityMap
var _chunks := {}
## One byte per lattice point of the whole map, filled in as `_she_fits()` is asked.
var _fits := PackedByteArray()
## One byte per tile of the map, the same three values, filled in as `_tile_open()` is asked.
var _tiles := PackedByteArray()
var _columns := 0
var _rows := 0
## The lattice points the walk has to join whatever stands: where she starts and where it ends.
var _ends: Array[Vector2i] = []
## The streets of the walk, each of which keeps a sidewalk open.
var _streets: Array[StreetNetwork.Segment] = []
## Every placement already put down, by instance id, so `catch_up()` puts each down once.
var _stood := {}

## The ground of `map`, with `standing` put down on it, for the walk `route` hands in: its streets and
## its ends. A walk of no route (`RouteSource` itself, or none) has neither, and is what a caller
## that only asks where a body stands (`solids_of()`) builds.
func _init(map: CityMap, standing: Array[EventScheduler.Planned] = [],
		route: RouteSource = null) -> void:
	_map = map
	_columns = ceili(float(map.size.x * Tuning.TILE_SIZE) / STEP) + 1
	_rows = ceili(float(map.size.y * Tuning.TILE_SIZE) / STEP) + 1
	_fits.resize(_columns * _rows)
	_tiles.resize(map.size.x * map.size.y)
	for plan in standing:
		stand(plan)
	if not route:
		return
	_streets = route.streets_on_the_walk()
	var ends: Array[Vector2] = []
	if route.start() != Vector2.INF:
		ends.append(route.start())
	ends.append_array(route.ends())
	for at in ends:
		_ends.append(Vector2i(roundi(at.x / STEP), roundi(at.y / STEP)))

## **Whether the walk stays open with `candidate` standing too**: every street it reaches keeps a
## sidewalk open, and the ground round it still joins up the way it did without it, past its body
## and its standing lethal reach (`held_by()`). A candidate with nothing that stands for the whole
## walk is accepted as it is.
func accepts(candidate: EventScheduler.Planned) -> bool:
	var own := held_by(candidate)
	if own.is_empty():
		return true
	return leaves_a_sidewalk_open(own) and keeps_the_walk_joined(own)

## Puts down every placement of `plans` not put down yet, in order: what a judge asks before a
## candidate, so the walk stands everything already accepted whoever accepted it.
func catch_up(plans: Array[EventScheduler.Planned]) -> void:
	for plan in plans:
		if not _stood.has(plan.get_instance_id()):
			stand(plan)

## Puts a placement's pieces down for every later question.
func stand(plan: EventScheduler.Planned) -> void:
	_stood[plan.get_instance_id()] = true
	for solid in held_by(plan):
		var reach := solid.shape.reach()
		var low := _chunk_of(solid.centre - Vector2.ONE * reach)
		var high := _chunk_of(solid.centre + Vector2.ONE * reach)
		for cy in range(low.y, high.y + 1):
			for cx in range(low.x, high.x + 1):
				var key := Vector2i(cx, cy)
				if not _chunks.has(key):
					_chunks[key] = []
				_chunks[key].append(solid)

## **The ground a placement holds her off for the whole walk**: its body (`solids_of()`), and the
## lethal reach of a row that stands — not mobile, `hard_fail` and no pursuer — as a disc round where
## its body stands, whose edge is where her centre is taken (`EventDef.lethal_reach()`, measured from
## the instance to her centre, as `EventInstance` measures it). A reach no wider than her own body
## holds nothing her body does not already.
func held_by(plan: EventScheduler.Planned) -> Array[Solid]:
	var found := solids_of(plan)
	var def := plan.def
	if def.mobile or not def.hard_fail or def.pursuit != null:
		return found
	var reach := def.lethal_reach() - Tuning.PLAYER_BODY_RADIUS
	if reach <= 0.0:
		return found
	found.append(Solid.new(_stands_at(plan), GroundShape.point(reach), Vector2.RIGHT))
	return found

## Where a placement stands once it is built: the first point of its path when it has one,
## recentred on the pavement band when it has a body `pavement_side` does not pin — the reading
## `EventInstance.setup()` makes.
func _stands_at(plan: EventScheduler.Planned) -> Vector2:
	var at: Vector2 = plan.path[0] if plan.path.size() > 0 else plan.position
	if plan.def.obstructs_radius > 0.0 and plan.def.pavement_side == EventDef.Pavement.ANY:
		at = EventInstance._centred_on_the_pavement_band(_map, at)
	return at

## A placement's pieces as they stand for the whole walk — its own body, and its successor's
## where it leaves a solid one — with nothing for a mobile row or one with no body. The same
## reading `EventInstance.setup()` makes of a stationary body: the first point of its path when
## it has one, recentred on the pavement band unless `pavement_side` pins it, its pieces laid
## by `EventInstance._spread_is_vertical()` and its spine along `EventManager._body_axis()`.
func solids_of(plan: EventScheduler.Planned) -> Array[Solid]:
	var found: Array[Solid] = []
	var defs: Array[EventDef] = [plan.def]
	if plan.def.spawns_on_finish != "":
		var successor := EventCatalogue.by_id(plan.def.spawns_on_finish)
		if successor:
			defs.append(successor)
	for def in defs:
		if def.mobile or def.obstructs_radius <= 0.0 or def.shape == null:
			continue
		var at: Vector2 = plan.path[0] if def == plan.def and plan.path.size() > 0 \
				else plan.position
		if def.pavement_side == EventDef.Pavement.ANY:
			at = EventInstance._centred_on_the_pavement_band(_map, at)
		var axis := EventManager._body_axis(_map, def, at, plan.facing)
		var vertical := EventInstance._spread_is_vertical(_map, at)
		for piece in def.parts():
			var offset := piece.offset_for(vertical)
			found.append(Solid.new(
					at + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0)),
					piece.shape, axis))
	return found

## **One sidewalk of every street the candidate reaches stays walkable from junction to
## junction**, with everything already standing whose body reaches that street. The day's own
## physical reading, `closes_a_walked_sidewalk_band()` — whether a set of bodies leaves no
## four-connected run of free sidewalk tiles from one end of a band to the other — which a day
## asks of the one band its route is walked along. Here it is asked of **both** bands, and the
## candidate is refused only when neither stays open, because the player's sentence is *one
## sidewalk* and nothing on such a street is a route drawn along one side of it.
##
## **Over every street the candidate reaches rather than only its own**, because a body on a
## street's last tile reaches the end of the cross street's sidewalk at the same corner.
func leaves_a_sidewalk_open(own: Array[Solid]) -> bool:
	for segment in _streets:
		var rect := segment.tile_rect()
		var world := _map.tile_rect_to_world(rect)
		var touched := false
		for solid in own:
			if solid.reaches(world, Tuning.PLAYER_BODY_RADIUS):
				touched = true
				break
		if not touched:
			continue
		var near := own.duplicate()
		near.append_array(_standing_near(world.grow(Tuning.PLAYER_BODY_RADIUS)))
		var open := false
		for band in EventScheduler._sidewalk_bands(rect, segment.horizontal):
			# Only the discs that reach this band are handed in: the band's own question is
			# every tile against every disc, and most of a street's bodies stand on the other
			# side of it.
			var reach := _map.tile_rect_to_world(band).grow(Tuning.PLAYER_BODY_RADIUS)
			var bodies: Array = []
			for solid: Solid in near:
				if not solid.reaches(reach, 0.0):
					continue
				for disc in solid.discs():
					if reach.grow(disc.z).has_point(Vector2(disc.x, disc.y)):
						bodies.append(disc)
			if not EventScheduler.closes_a_walked_sidewalk_band(_map, band, segment.horizontal,
					bodies, _map.closed_tiles):
				open = true
				break
		if not open:
			return false
	return true

## **The ground around the candidate still joins up everything it joined without it.** The
## day's junction rule asks whether a junction box still carries a walk between every route
## street that meets it; this asks the same of a box drawn round the candidate's own reach, with
## the whole of the box's rim as its arms: every two points on the rim that a walk inside the
## box joined before the candidate must still be joined with it standing, and so must the
## walk's start and either end if the box holds them.
##
## **That is the whole walk's question, answered locally.** A walk from the door to an exit that
## passes through the box enters and leaves it through the rim, and the candidate changes
## nothing outside the box, so if every pair of rim points the box joined is still joined, every
## walk that existed still does — and the seals alone leave the walk's ends reachable (the escape's
## both exits, `tests/test_finale.gd`), so by induction over the placements the finished plan does
## too.
## It refuses more than it has to — two rim points the box joined may also be joined round the
## outside — and that is the safe direction: the copy is rolled again, or not placed.
##
## Asked of her centre on the `STEP` lattice: a point is open when the ground under her body is
## walkable (`_she_fits()`) and no piece standing holds her off it.
func keeps_the_walk_joined(own: Array[Solid]) -> bool:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for solid in own:
		var reach := solid.shape.reach() + Tuning.PLAYER_BODY_RADIUS
		low = low.min(solid.centre - Vector2.ONE * reach)
		high = high.max(solid.centre + Vector2.ONE * reach)
	# A lattice step clear of anything the candidate can hold her off, so the rim is ground the
	# candidate never changes.
	var first := Vector2i(floori(low.x / STEP) - 1, floori(low.y / STEP) - 1)
	var last := Vector2i(ceili(high.x / STEP) + 1, ceili(high.y / STEP) + 1)
	var width := last.x - first.x + 1
	var height := last.y - first.y + 1
	var box := Rect2(Vector2(first) * STEP, Vector2(last - first) * STEP)
	# Each body is laid over the points its own box covers rather than every point asking every
	# body, which is what keeps this to a few hundred points' work per candidate.
	var held := PackedByteArray()
	held.resize(width * height)
	for solid in _standing_near(box.grow(Tuning.PLAYER_BODY_RADIUS)):
		_lay(solid, first, width, height, held, 1)
	for solid in own:
		_lay(solid, first, width, height, held, 2)
	var before := PackedByteArray()
	before.resize(width * height)
	var after := PackedByteArray()
	after.resize(width * height)
	var changed := false
	for row in height:
		var y := first.y + row
		for column in width:
			var i := row * width + column
			if held[i] & 1:
				continue
			# `_she_fits()`'s own cache read inline, since this is the loop it is asked from.
			var x := first.x + column
			if x < 0 or y < 0 or x >= _columns or y >= _rows:
				continue
			var known := _fits[y * _columns + x]
			if known == _DOES_NOT_FIT or (known == _UNASKED and not _she_fits(Vector2i(x, y))):
				continue
			before[i] = 1
			if held[i] & 2:
				changed = true
			else:
				after[i] = 1
	if not changed:
		return true
	var keys := PackedInt32Array()
	for column in width:
		keys.append(column)
		keys.append((height - 1) * width + column)
	for row in range(1, height - 1):
		keys.append(row * width)
		keys.append(row * width + width - 1)
	for end in _ends:
		var inside := end - first
		if inside.x >= 0 and inside.y >= 0 and inside.x < width and inside.y < height:
			keys.append(inside.y * width + inside.x)
	var was := _components(before, width, height)
	var now := _components(after, width, height)
	var joined := {}
	for i in keys:
		if before[i] == 0:
			continue
		if after[i] == 0:
			return false
		if joined.has(was[i]) and joined[was[i]] != now[i]:
			return false
		joined[was[i]] = now[i]
	return true

## Her centre may stand on this lattice point as far as the ground goes: the tile under it and
## the four her body reaches are in the map, walkable and not closed.
func _she_fits(point: Vector2i) -> bool:
	if point.x < 0 or point.y < 0 or point.x >= _columns or point.y >= _rows:
		return false
	var index := point.y * _columns + point.x
	var known := _fits[index]
	if known != _UNASKED:
		return known == _FITS
	var at := Vector2(point) * STEP
	var reach := Tuning.PLAYER_BODY_RADIUS - 1.0
	var fits := _tile_open(at) and _tile_open(at + Vector2(reach, 0.0)) \
			and _tile_open(at - Vector2(reach, 0.0)) and _tile_open(at + Vector2(0.0, reach)) \
			and _tile_open(at - Vector2(0.0, reach))
	_fits[index] = _FITS if fits else _DOES_NOT_FIT
	return fits

## Whether the tile under `at` is in the map, walkable and not closed, asked of the map once per
## tile.
func _tile_open(at: Vector2) -> bool:
	var tile := WorldMap.tile_of(at)
	if not _map.in_bounds(tile):
		return false
	var index := tile.y * _map.size.x + tile.x
	var known := _tiles[index]
	if known == _UNASKED:
		known = _FITS if _map.is_walkable(tile) and not _map.is_closed(tile) \
				else _DOES_NOT_FIT
		_tiles[index] = known
	return known == _FITS

## Marks `bit` on every point of a `width` by `height` window from `first` that `solid` holds
## her centre off.
static func _lay(solid: Solid, first: Vector2i, width: int, height: int,
		held: PackedByteArray, bit: int) -> void:
	var reach := solid.shape.reach() + Tuning.PLAYER_BODY_RADIUS
	var low := Vector2i(maxi(floori((solid.centre.x - reach) / STEP) - first.x, 0),
			maxi(floori((solid.centre.y - reach) / STEP) - first.y, 0))
	var high := Vector2i(mini(ceili((solid.centre.x + reach) / STEP) - first.x, width - 1),
			mini(ceili((solid.centre.y + reach) / STEP) - first.y, height - 1))
	for row in range(low.y, high.y + 1):
		for column in range(low.x, high.x + 1):
			var i := row * width + column
			if held[i] & bit:
				continue
			if solid.stops_her_at(Vector2(first.x + column, first.y + row) * STEP):
				held[i] |= bit

## Each open cell's four-connected component within a `width` by `height` grid of bytes, as a
## small integer, and -1 where the cell is shut.
static func _components(open: PackedByteArray, width: int, height: int) -> PackedInt32Array:
	var group_of := PackedInt32Array()
	group_of.resize(open.size())
	group_of.fill(-1)
	var queue := PackedInt32Array()
	queue.resize(open.size())
	var group := 0
	for start in open.size():
		if open[start] == 0 or group_of[start] >= 0:
			continue
		group_of[start] = group
		queue[0] = start
		var head := 0
		var tail := 1
		while head < tail:
			var at := queue[head]
			head += 1
			var column := at % width
			if column + 1 < width and open[at + 1] != 0 and group_of[at + 1] < 0:
				group_of[at + 1] = group
				queue[tail] = at + 1
				tail += 1
			if column > 0 and open[at - 1] != 0 and group_of[at - 1] < 0:
				group_of[at - 1] = group
				queue[tail] = at - 1
				tail += 1
			if at + width < open.size() and open[at + width] != 0 \
					and group_of[at + width] < 0:
				group_of[at + width] = group
				queue[tail] = at + width
				tail += 1
			if at >= width and open[at - width] != 0 and group_of[at - width] < 0:
				group_of[at - width] = group
				queue[tail] = at - width
				tail += 1
		group += 1
	return group_of

## Every standing piece whose body reaches `rect`, each once.
func _standing_near(rect: Rect2) -> Array[Solid]:
	var found: Array[Solid] = []
	var seen := {}
	var low := _chunk_of(rect.position)
	var high := _chunk_of(rect.end)
	for cy in range(low.y, high.y + 1):
		for cx in range(low.x, high.x + 1):
			for solid: Solid in _chunks.get(Vector2i(cx, cy), []):
				if seen.has(solid) or not solid.reaches(rect, 0.0):
					continue
				seen[solid] = true
				found.append(solid)
	return found

static func _chunk_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / _CHUNK), floori(at.y / _CHUNK))
