class_name WorldMap
extends RefCounted
## **The one map interface every world implements and everything that stands in a world is handed**:
## the city's map (`CityMap`) and the building's (`InteriorMapPlan`). An event manager, each event, the
## crowd, the stroller and the run log are given the map of the world they are in by whoever builds
## them, and ask it every question about the ground: which tile a point is on, whether a mover may
## stand there, whether a line is clear, whether a wall keeps a field from her, how to get somewhere
## (through its `navigator()`), how to add something to the world on a draw layer, and what the ground
## under her does to her walk (`slope_dir_at()`, `process_player()`). None of them asks which world it
## is in, so an event indoors walks round the building's walls and sees along its flights by the same
## code that walks it round a café outdoors.
##
## **The questions are answered here, over two answers each map gives about its own ground**: whether
## the ground as built lets a mover onto a tile (`_ground_lets()`), and whether a tile is open to sight
## (`_open()`). The line walk, the wall's depth, the blocked record and the tile conversions are this
## class's, written once for both worlds.
##
## **The street questions answer "no street here" unless a map has streets**: which way a pavement
## faces, which alley or lot a tile is in, whether a car on it gives way. The city answers them; the
## building has no streets and keeps the answers below, so an event that asks one indoors gets the
## answer it gets on a square or a park.
##
## **A `WorldMap` of this class itself is open ground** (`open_ground()`): every tile passable, every
## line clear, no wall and no street. It is what a data rig with no world stands an event or a mover
## on, and what the navigator answers every way straight on (`has_ground()`).

## A tile a sweep has not reached, and one it treats as a wall: two values so a sweep can paint what
## is blocked into its grid before it starts rather than ask per neighbour.
const UNREACHED := -1
const BLOCKED := -2

## The map's size in tiles; zero for open ground, which has no edge.
var size := Vector2i.ZERO
## What stands on the ground today — a precinct's posts, the closures, the soft seals and every
## stationary solid body — as the one record every mover asks through `passable()`
## (`BlockedLayer`). The ground's own type is the map's (`_ground_lets()`).
var blocked := BlockedLayer.new()
## Bumped by every write to a per-day record that is not a body (the city's holds, soft seals and
## closures): a version a reader only compares with the one its own answer was built from.
var day_record_version := 0
## The world this map is drawn in, which `add_entity()` and `process_player()` go through: handed
## over by the world node when it takes the map (`City.build()`, `InteriorScene.build()`). Null for a
## map no world draws — a data rig's; `has_world()` asks.
var world: WorldContext = null

## The map's one navigator while anything holds it (`navigator()`), kept by a weak reference: a map
## holding its navigator strongly while the navigator holds the map would be a reference cycle that
## is never freed.
var _navigator: WeakRef = null

## Open ground: a map with no ground of its own (see the class doc).
static func open_ground() -> WorldMap:
	return WorldMap.new()

## Whether this map has ground of its own. False only for open ground, where the navigator takes every
## step whole and every way straight rather than searching a grid that is not there.
func has_ground() -> bool:
	return false

# ----------------------------------------------------------------- conversion ---

## The tile a world point is on: tiles are `Tuning.TILE_SIZE` square from the world origin in both
## worlds, so this is the one conversion every reader uses.
static func tile_of(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / Tuning.TILE_SIZE),
			floori(world_position.y / Tuning.TILE_SIZE))

## The centre of a tile in world space.
static func centre_of(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * Tuning.TILE_SIZE

func world_to_tile(world_position: Vector2) -> Vector2i:
	return tile_of(world_position)

## Centre of a tile in world space.
func tile_to_world(tile: Vector2i) -> Vector2:
	return centre_of(tile)

func tile_rect_to_world(rect: Rect2i) -> Rect2:
	return Rect2(Vector2(rect.position) * Tuning.TILE_SIZE,
			Vector2(rect.size) * Tuning.TILE_SIZE)

func in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < size.x and tile.y < size.y

# ------------------------------------------------------------ the ground itself ---

## Whether the ground as built lets anybody stand on `tile`: `passable()` for `Mover.lattice()`.
func is_walkable(_tile: Vector2i) -> bool:
	return true

## Whether the ground as built lets a mover stopped by `layers` (`Mover`) onto `tile`: the ground's
## own type, a post, and street ground, as `layers` asks. Each map answers for its own ground.
func _ground_lets(_tile: Vector2i, _layers: int) -> bool:
	return true

## Whether the segment from `from` to `to` meets the closed part of `tile`, a tile `_ground_lets()`
## refuses a mover stopped by `layers`: the whole tile, unless a map's ground is closed over only part
## of a tile (the building's flights, `InteriorMapPlan`), where a line through the open part of it
## passes.
func _ground_stops(_tile: Vector2i, _layers: int, _from: Vector2, _to: Vector2) -> bool:
	return true

## Whether the tile at (`x`, `y`) is open to sight, for `wall_between()`: walkable ground, posts left
## open, since a post blocks a body and not a look.
func _open(_x: int, _y: int) -> bool:
	return true

## Every tile's ground type as one byte a tile, row by row, with `walkable_lut()` saying which bytes
## are walkable: what a sweep over the whole map reads by index rather than by call (`ArrowField`).
## Empty for open ground.
func walk_tiles() -> PackedByteArray:
	return PackedByteArray()

## `1` at each byte of `walk_tiles()` that is walkable ground, `0` elsewhere.
func walkable_lut() -> PackedByteArray:
	return PackedByteArray([1])

# ------------------------------------------------------------ the blocked record ---

## **Whether `mover` may stand on `tile`**: the one question every step, line, flood and placement
## asks of the ground, for the layers the mover names (`Mover`). The ground's own type, a post and
## street ground are the map as built (`_ground_lets()`); today's closures, soft seals and bodies are
## the day's record (`blocked`).
func passable(tile: Vector2i, mover: Mover) -> bool:
	var layers := mover.blocked_by
	return _ground_lets(tile, layers) and not blocked.blocks(tile, layers & Mover.TODAY)

## Tiles a stationary solid body stands on today, as tile -> how many bodies stand there
## (`BlockedLayer.bodies`).
var obstructed_tiles: Dictionary:
	get:
		return blocked.bodies
	set(value):
		blocked.bodies = value
## Bumped whenever a tile enters or leaves `obstructed_tiles`: a version a reader compares with the
## one its own answer was built from (`BlockedLayer.body_version`).
var obstruction_version: int:
	get:
		return blocked.body_version
	set(value):
		blocked.body_version = value

## Clears today's solid bodies, once a day.
func clear_day_obstructions() -> void:
	blocked.clear_bodies()

## Records one body's footprint under `owner`, an `Object.get_instance_id()` handed back later to
## `release_obstruction()`.
func obstruct_tiles(owner: int, tiles_covered: Array[Vector2i]) -> void:
	blocked.obstruct(owner, tiles_covered)

## Gives one body's footprint back; an unknown owner is a no-op.
func release_obstruction(owner: int) -> void:
	blocked.release(owner)

## Whether a stationary solid body is standing on a tile today.
func is_obstructed(tile: Vector2i) -> bool:
	return obstructed_tiles.has(tile)

# ---------------------------------------------------------------------- lines ---

## **Whether the straight line from `from` to `to` crosses only ground `mover` may enter**
## (`passable()`, `Mover.lattice()` when none is named): every tile the segment enters is asked,
## found by stepping from one tile boundary to the next along it rather than by sampling, so a line
## that clips a wall's corner by a pixel is blocked however short it is, and a line through a corner
## point exactly asks both tiles beside it. **The line a pursuer notices her along, lunges along and
## catches her along** (`EventInstance._clear_line_to()`), and the line day 13's waiting guard is
## placed to have from the roadblock he guards (`ResistanceDirector._roadblock_guard_spot()`) — one
## walk, so a spot chosen for its line is one his notice sees from (leafy-puffin, inbox #648).
## Stricter than `wall_between()`, which asks how deep into a wall a line runs.
##
## **The day's solids stop it like a wall, with two ends left out.** A line from inside a solid it
## starts in sees out of it — a guard at the middle of his own band — and the tile it ends on is where
## the other one stands, so a body that covers the middle of her tile does not hide her from a man
## beside her. Everything between is asked: a pursuer neither notices nor reaches her through a café,
## a barrier or a seal.
func clear_line(from: Vector2, to: Vector2, mover: Mover = null) -> bool:
	return _line_is_clear(from, to, mover if mover else Mover.lattice(), true)

## Whether the swept step from `from` to `to` crosses only ground `mover` may enter, its landing tile
## included: `clear_line()` without the far end left out, what `Navigator.step()` asks.
func step_is_clear(from: Vector2, to: Vector2, mover: Mover) -> bool:
	return _line_is_clear(from, to, mover, false)

## `clear_line()` and `step_is_clear()`: the same tile walk, the far end's tile left out of the day's
## layers only for a line to somebody (`to_somebody`).
func _line_is_clear(from: Vector2, to: Vector2, mover: Mover, to_somebody: bool) -> bool:
	if not has_ground():
		return true
	var layers := mover.blocked_by
	var today := layers & Mover.TODAY
	var tile := world_to_tile(from)
	if not _ground_lets(tile, layers) and _ground_stops(tile, layers, from, to):
		return false
	# Inside a solid of the day's it starts in: those layers are not asked until it is out.
	var leaving := today != 0 and blocked.blocks(tile, today)
	var last := world_to_tile(to)
	var delta := to - from
	var tile_size := float(Tuning.TILE_SIZE)
	var step := Vector2i(int(signf(delta.x)), int(signf(delta.y)))
	# The fraction of the segment at which it next crosses a vertical (x) or horizontal (y) tile
	# boundary, and how much of the segment one whole tile takes on each axis.
	var next_x := INF
	var each_x := INF
	if step.x != 0:
		next_x = (float(tile.x + maxi(step.x, 0)) * tile_size - from.x) / delta.x
		each_x = tile_size / absf(delta.x)
	var next_y := INF
	var each_y := INF
	if step.y != 0:
		next_y = (float(tile.y + maxi(step.y, 0)) * tile_size - from.y) / delta.y
		each_y = tile_size / absf(delta.y)
	while minf(next_x, next_y) <= 1.0:
		if is_equal_approx(next_x, next_y):
			for side: Vector2i in [tile + Vector2i(step.x, 0), tile + Vector2i(0, step.y)]:
				if not _ground_lets(side, layers) and _ground_stops(side, layers, from, to):
					return false
				if today != 0 and not leaving and blocked.blocks(side, today) \
						and not (to_somebody and side == last):
					return false
			tile += step
			next_x += each_x
			next_y += each_y
		elif next_x < next_y:
			tile.x += step.x
			next_x += each_x
		else:
			tile.y += step.y
			next_y += each_y
		if not _ground_lets(tile, layers) and _ground_stops(tile, layers, from, to):
			return false
		if today == 0:
			continue
		if not blocked.blocks(tile, today):
			leaving = false
		elif not leaving and not (to_somebody and tile == last):
			return false
	return true

## The ground a sweep over the whole map runs on for `mover`: each tile `UNREACHED`, or `BLOCKED`
## where a layer of the day's record `mover` names stands. The ground's own types are not laid out: a
## sweep reads them off `walk_tiles()` itself, a lookup per neighbour against a call. What the red
## arrow's sweep and a pursuer's walk to her run on (`ArrowField`), laid out once for each state of
## the record (`day_record_version`, `obstruction_version`). Empty for open ground.
func ground_for(mover: Mover) -> PackedInt32Array:
	var ground := PackedInt32Array()
	ground.resize(size.x * size.y)
	ground.fill(UNREACHED)
	blocked.lay_out(ground, size.x, size.y, mover.blocked_by, BLOCKED)
	return ground

# ---------------------------------------------------------------------- walls ---

## **Whether a wall stands between two points deeply enough to keep a source's excitement at one from
## reaching the other**: true when the straight segment between them passes the middle of a wall one
## tile thick, or one tile deep into anything thicker, measured from the nearest open ground
## (`_open()`) (plaid-wombat, inbox #554; inbox #568). `EventInstance.contribution_at()` and
## `CrowdAgent.contribution_at()` ask it of every source whose field reaches her, so the meter, the
## halo and the carets all read the same blocked contribution, in the city and in the building alike.
##
## **Stated over distance from open ground, not over tiles touched**: a pram whose body overlaps a
## wall's edge is shielded by nothing short of the middle of the wall, and a line that clips a
## corner or runs along a face never gets that deep. **Thick or thin is a property of each closed
## tile**: one of its corners a point where four closed tiles meet holds a point a whole tile from
## open ground and asks `depth` (`Tuning.WALL_SHIELD_DEPTH`, a tile); every other closed tile is part
## of a wall one tile thick, whose deepest points are its middle, and asks `thin_depth`
## (`Tuning.THIN_WALL_SHIELD_DEPTH`, half a tile). So a building two tiles thick blocks only along its
## middle, and not within a tile of an open end of it (bouncy-kestrel, inbox #568).
##
## **Exact, never sampled.** It steps the tiles the segment crosses, the same tile-boundary walk the
## catch's line takes, and in each closed tile asks whether the segment meets the part of it that
## tile's depth or more from open ground: the tile shrunk by that depth on every side facing an open
## tile, less a disc of that radius round each corner an open tile meets only diagonally. Only a
## tile's eight neighbours can be nearer than a whole tile, which is why neither depth may exceed
## `Tuning.TILE_SIZE`. A segment exactly the depth from open ground at its deepest is blocked.
func wall_between(from: Vector2, to: Vector2, depth := Tuning.WALL_SHIELD_DEPTH,
		thin_depth := Tuning.THIN_WALL_SHIELD_DEPTH) -> bool:
	if not has_ground():
		return false
	var tile_size := float(Tuning.TILE_SIZE)
	var x := floori(from.x / tile_size)
	var y := floori(from.y / tile_size)
	var delta := to - from
	var step_x := int(signf(delta.x))
	var step_y := int(signf(delta.y))
	# The fraction of the segment at which it next crosses a vertical (x) or horizontal (y) tile
	# boundary, and how much of the segment one whole tile takes on each axis.
	var next_x := INF
	var each_x := INF
	if step_x != 0:
		next_x = (float(x + maxi(step_x, 0)) * tile_size - from.x) / delta.x
		each_x = tile_size / absf(delta.x)
	var next_y := INF
	var each_y := INF
	if step_y != 0:
		next_y = (float(y + maxi(step_y, 0)) * tile_size - from.y) / delta.y
		each_y = tile_size / absf(delta.y)
	while true:
		if not _open(x, y) \
				and _reaches_the_middle_of(Vector2i(x, y), from, delta, depth, thin_depth):
			return true
		if minf(next_x, next_y) > 1.0:
			return false
		# Through a vertex exactly, the two tiles beside it share only that one point with the
		# segment, and the diagonal tile asked next holds that point too.
		if next_x < next_y:
			x += step_x
			next_x += each_x
		elif next_y < next_x:
			y += step_y
			next_y += each_y
		else:
			x += step_x
			y += step_y
			next_x += each_x
			next_y += each_y
	return false

## Whether the segment `from + t * delta`, `t` in [0, 1], meets the part of closed tile `tile` that
## is at least this tile's depth from every open tile — `depth` where one of its corners is shared by
## four closed tiles, `thin_depth` where none is; see `wall_between()`. The shrunk rectangle is
## clipped first (an open side's band is shallower than the depth all along it), then what is left
## of the segment has to escape the open corner discs: it is shallow only if every point of it lies
## strictly inside one of them.
func _reaches_the_middle_of(tile: Vector2i, from: Vector2, delta: Vector2, depth: float,
		thin_depth: float) -> bool:
	var tile_size := float(Tuning.TILE_SIZE)
	var low := Vector2(tile) * tile_size
	var high := low + Vector2(tile_size, tile_size)
	var open_west := _open(tile.x - 1, tile.y)
	var open_east := _open(tile.x + 1, tile.y)
	var open_north := _open(tile.x, tile.y - 1)
	var open_south := _open(tile.x, tile.y + 1)
	var open_north_west := _open(tile.x - 1, tile.y - 1)
	var open_north_east := _open(tile.x + 1, tile.y - 1)
	var open_south_west := _open(tile.x - 1, tile.y + 1)
	var open_south_east := _open(tile.x + 1, tile.y + 1)
	# A corner with closed ground on all four tiles round it is a whole tile from every open tile,
	# so this tile belongs to something thicker than one tile; with no such corner it is part of a
	# wall one tile thick, whose deepest points are its middle.
	var thick := (not open_west and not open_north and not open_north_west) \
			or (not open_east and not open_north and not open_north_east) \
			or (not open_west and not open_south and not open_south_west) \
			or (not open_east and not open_south and not open_south_east)
	if not thick:
		depth = thin_depth
	var span := _clip_to(from.x, delta.x, low.x + (depth if open_west else 0.0),
			high.x - (depth if open_east else 0.0), Vector2(0.0, 1.0))
	span = _clip_to(from.y, delta.y, low.y + (depth if open_north else 0.0),
			high.y - (depth if open_south else 0.0), span)
	if span.x > span.y:
		return false
	# A corner whose two sides are both closed but whose diagonal neighbour is open: the open tile is
	# nearest at that corner point, so the shallow ground there is a disc round it.
	var shallow: Array[Vector2] = []
	if not open_west and not open_north and open_north_west:
		shallow.append(_inside_disc(from, delta, low, depth))
	if not open_east and not open_north and open_north_east:
		shallow.append(_inside_disc(from, delta, Vector2(high.x, low.y), depth))
	if not open_west and not open_south and open_south_west:
		shallow.append(_inside_disc(from, delta, Vector2(low.x, high.y), depth))
	if not open_east and not open_south and open_south_east:
		shallow.append(_inside_disc(from, delta, high, depth))
	# Walk forward from the start of the span through every disc that strictly contains the point
	# reached so far; the segment reaches the middle unless that walk passes the span's end.
	var reached := span.x
	var moved := true
	while moved:
		moved = false
		for interval in shallow:
			if interval.x < reached and reached < interval.y:
				reached = interval.y
				moved = true
	return reached <= span.y

## `span` narrowed to where `start + t * along` lies in [`low`, `high`] on one axis — empty (start
## past end) when it never does, and when the band itself is empty (`low` past `high`, a tile shrunk
## from both sides by more than half of it).
static func _clip_to(start: float, along: float, low: float, high: float, span: Vector2) -> Vector2:
	if low > high:
		return Vector2(1.0, 0.0)
	if along == 0.0:
		return span if start >= low and start <= high else Vector2(1.0, 0.0)
	var a := (low - start) / along
	var b := (high - start) / along
	if a > b:
		var swap := a
		a = b
		b = swap
	return Vector2(maxf(span.x, a), minf(span.y, b))

## The open interval of `t` for which `from + t * delta` is strictly within `radius` of `centre`, or
## an empty one (start past end) when it never is.
static func _inside_disc(from: Vector2, delta: Vector2, centre: Vector2, radius: float) -> Vector2:
	var offset := from - centre
	var a := delta.dot(delta)
	var c := offset.dot(offset) - radius * radius
	if a == 0.0:
		return Vector2(-INF, INF) if c < 0.0 else Vector2(1.0, 0.0)
	var b := 2.0 * offset.dot(delta)
	var discriminant := b * b - 4.0 * a * c
	if discriminant <= 0.0:
		return Vector2(1.0, 0.0)
	var root := sqrt(discriminant)
	return Vector2((-b - root) / (2.0 * a), (-b + root) / (2.0 * a))

# ---------------------------------------------------------------------- moving ---

## How anything that walks or drives over this map moves (`Navigator`): **one per map**, the same
## one to every caller for as long as anything holds it — the city (`City.navigator`), the event
## manager, the director, the crowd, the resistance, every figure on the map — and a fresh one only
## once nothing does. The one other navigator over a map is one a caller builds itself
## (`Navigator.new(map)`), which only a test does, to step a figure by hand.
func navigator() -> Navigator:
	var held: Navigator = _navigator.get_ref() if _navigator else null
	if held == null:
		held = Navigator.new(self)
		_navigator = weakref(held)
	return held

## A way from `from` to `to` round whatever stands between, for `mover` (`Navigator.path()`).
func path(from: Vector2, to: Vector2, mover: Mover) -> PackedVector2Array:
	return navigator().path(from, to, mover)

## The part of the step `delta` from `from` that `mover` takes (`Navigator.step()`).
func step(from: Vector2, delta: Vector2, mover: Mover) -> Vector2:
	return navigator().step(from, delta, mover)

# ----------------------------------------------------------- the street questions ---
# Each answers "no street here" on a map with no streets (see the class doc); `CityMap` answers them
# from its lattice.

## Whether this map is laid out on the street lattice, so a car on it holds at a junction's line and
## gives way at a zebra (`EventInstance._room_to_its_line()`).
func has_street_lattice() -> bool:
	return false

## Street ground: pavement, carriageway or crossing.
func is_street(_tile: Vector2i) -> bool:
	return false

## Whether a car on `tile` is on the carriageway, where a car that drives at her strikes her
## (`EventInstance._on_the_carriageway()`). Open ground is open to a car everywhere.
func is_carriageway(_tile: Vector2i) -> bool:
	return true

## Whether `tile` is a zebra's paint.
func is_crossing(_tile: Vector2i) -> bool:
	return false

## Which way is away from the carriageway from a pavement tile, as a unit tile step; zero where there
## is no single answer, and everywhere off a pavement.
func pavement_inward(_tile: Vector2i) -> Vector2i:
	return Vector2i.ZERO

## How far into a street's corridor `tile` lies on each axis — `x` across a north-south street, `y`
## across an east-west one, `-1` where the tile is in no corridor on that axis. A tile in both is a
## junction; a tile in neither is off the streets (a square, a park, a courtyard, a building).
func corridor_offsets(_tile: Vector2i) -> Vector2i:
	return Vector2i(-1, -1)

## The junction box `tile` stands in, or `(-1, -1)` where it stands in none.
func junction_box_at(_tile: Vector2i) -> Vector2i:
	return Vector2i(-1, -1)

## The kind of street a tile lies on, looking along `vertical`'s axis: a car gives way at a zebra on
## anything but the main road. `MAIN` where there is no street, so nothing gives way there.
func street_kind_at(_vertical: bool, _tile: Vector2i) -> GameEnums.StreetKind:
	return GameEnums.StreetKind.MAIN

## The alley `tile` lies in, as a tile rect, or an empty rect where it lies in none.
func alley_at(_tile: Vector2i) -> Rect2i:
	return Rect2i()

## The lot of the building whose frontage `tile` lies in, as a tile rect, or an empty rect.
func lot_at(_tile: Vector2i) -> Rect2i:
	return Rect2i()

# ------------------------------------------------------------ the world it is in ---

## Adds `node` to the world this map is drawn in, on `layer` (`DrawLayer.Layer`, an `int` for the
## reason `DrawLayer.z_of()` gives), the y-sorted `ENTITIES` unless the caller asks for another
## (`WorldContext.add_entity()`). Only on a map a world draws (`has_world()`).
func add_entity(node: Node, layer: int = DrawLayer.Layer.ENTITIES) -> void:
	world.add_entity(node, layer)

## Whether a world draws this map, so `add_entity()` has somewhere to add to.
func has_world() -> bool:
	return world != null and is_instance_valid(world)

## What the ground under her does each frame she walks it — the building's doors take her through,
## its light follows her part — asked by the run flow every walking frame (`WorldContext.
## process_player()`). Nothing on a map no world draws.
func process_player(player: Node2D, delta: float) -> void:
	if has_world():
		world.process_player(player, delta)

## `+1` where `world_position` is on a flight of stairs descending east, `-1` descending west, `0`
## off a flight: what the stroller turns a sideways press along (`Stroller._physics_process()`).
## Only the building has stairs.
func slope_dir_at(_world_position: Vector2) -> int:
	return 0
