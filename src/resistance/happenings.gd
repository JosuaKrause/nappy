class_name ResistanceHappenings
extends RefCounted
## What the resistance's story puts in the street that is not a task: the neighbor leaving for
## work on the mornings before day 10, and the once-only happenings of days 10 to 13 that are not
## the scheduler's to plan. Owned and ticked by `ResistanceDirector`, which is the one node that
## already knows the day, the city and where she is.
##
## **Each happening arrives a different way, and each leaves something the run keeps**
## (`docs/TODO.md`, M181: "waiting at home, found gone, closing in front of her, coming on her
## way"): day 10's raid is **waiting at home** and the neighbor is gone from the next morning; day
## 11's market is **found gone**, a block ahead of her boarded up before she gets there, and it
## stays boarded; day 12's park **closes in front of her** once she has reached its swing, and stays
## requisitioned; day 13's column **comes down the main road on her way**, and the barricade it
## stops at stays for the rest of the run.
##
## **Deterministic from the run seed and the day**, like every other placement: its own stream
## (`GameState.day_rng(day, "happenings")`), so nothing here moves a draw the director or the
## scheduler makes.

## The day the neighbor is out in the city rather than leaving at dawn, and the day of the raid.
## Named here rather than read off `ResistanceSteps` because the neighbor's mornings are the story
## whether or not this run is ever offered the task.
const NEIGHBOR_DAY := 10

## How far beside her the neighbor comes out of the door, along the street: enough that the two
## figures do not stand in one another on the first frame, not so far that they read as strangers.
const NEIGHBOR_BESIDE_HER := 1.5 * Tuning.TILE_SIZE

## How far along her street either van of the raid stands from her door, in tiles: far enough
## apart that the doorstep between them is plainly open, near enough that both are at her building.
const RAID_VAN_OFFSET_TILES := 3
## How far along her street the raid's patrol car paces either way from her door, in tiles.
const RAID_PATROL_REACH_TILES := 7

## The day the market is gone, and the day the column comes down the main road. Day 12's park is
## `ResistanceSteps.swing_day()`'s, the day its task sends her to the swing.
const MARKET_DAY := 11
const COLUMN_DAY := 13

var _city: City
var _map: CityMap
var _day := 0
var _rng: RandomNumberGenerator
## The neighbor's morning figure, or null on a day that has none. Kept for the tests.
var morning_neighbor: EventInstance
## The raid at her building, once it has arrived: the vans and the patrol. Empty before then and on
## every other day.
var raid: Array[EventInstance] = []
## Where the raid will stand, worked out at dawn so waiting for her to be out of sight costs a
## distance and a screen test a frame: the vans' points, and the patrol's beat.
var _raid_vans := PackedVector2Array()
var _raid_beat := PackedVector2Array()

## How long today has run, and how much of it she has spent walking rather than standing — a
## happening sited on her way waits for her to have chosen a way, as day 3's fire does, on the same
## clock (`EventDirector.site_what_is_on_her_way()`: seconds at `Tuning.AHEAD_MIN_SPEED` or more).
var _elapsed := 0.0
var _walked := 0.0
## The way she is going, read off her own velocity while she moves.
var _heading := Vector2.ZERO
## Counts down to the next look for the market's block — once a second, not every frame.
var _look_in := 0.0
## Whether today still owes the market, and the day's routes to site it on.
var _market_owed := false
var _siting: EventScheduler.WalkSiting = null
## The block boarded up today, `(-1, -1)` before then and on every other day. Kept for the tests.
var market_block := Vector2i(-1, -1)
## Day 12's park closing: its ground as rings, outermost first, and the clock to the next ring.
var _closing: Array = []
var _closing_every := 0.0
var _closing_in := 0.0
var _closing_park := Vector2i(-1, -1)
## Whether today still owes the column, and its trucks once it has come. Kept for the tests.
var _column_owed := false
var column: Array[EventInstance] = []

func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map

## Starts the day's happenings: on the mornings before `NEIGHBOR_DAY` the neighbor walks out of
## her building beside her and off along her street.
func start_day(day: int) -> void:
	_day = day
	_rng = GameState.day_rng(day, "happenings")
	morning_neighbor = null
	raid.clear()
	_raid_vans = PackedVector2Array()
	_raid_beat = PackedVector2Array()
	_elapsed = 0.0
	_walked = 0.0
	_heading = Vector2.ZERO
	_look_in = 0.0
	_siting = null
	market_block = Vector2i(-1, -1)
	_closing.clear()
	_closing_park = Vector2i(-1, -1)
	column.clear()
	_market_owed = day == MARKET_DAY
	_column_owed = day == COLUMN_DAY
	if day < NEIGHBOR_DAY:
		morning_neighbor = _send_the_neighbor_to_work()
	if day == NEIGHBOR_DAY:
		_plan_the_raid()

## Once a frame, from the director: brings in whatever the day is waiting to bring in. `her` is her
## position, `Vector2.INF` with no player, and `velocity` hers; `sight` is the danger edge's own
## on-screen test, which a rig may leave unset.
func tick(delta: float, her: Vector2, velocity: Vector2, sight: Callable) -> void:
	_elapsed += delta
	if her != Vector2.INF and velocity.length() >= Tuning.AHEAD_MIN_SPEED:
		_heading = velocity.normalized()
		_walked += delta
	if not _raid_vans.is_empty() and raid.is_empty():
		_maybe_raid(her, sight)
	if _market_owed:
		_maybe_the_market(delta, her)
	if not _closing.is_empty():
		_close_a_ring(delta)
	if _column_owed:
		_maybe_the_column(her)

# ------------------------------------------------------------------ the raid ---

## Where day 10's raid stands at her building: **vans in the street at her building with a patrol,
## and the doorstep stays reachable** (PLAYTEST-122). Two `night_raid` vans on the far sidewalk of
## her own street, `RAID_VAN_OFFSET_TILES` either side of her door, and a patrol car pacing the
## carriageway between them. The far sidewalk rather than hers, because a van body closes the
## sidewalk it stands on (44px against a 64px band), and on her own side two of them would leave the
## door reachable only across the traffic; on the far side her own sidewalk runs past the door
## open both ways, and the vans are across the street from it, facing it.
func _plan_the_raid() -> void:
	if not _map:
		return
	var door := _map.world_to_tile(_map.doorstep_world_position())
	var corridor := door.y - CityMap.corridor_offset(door.y)
	var far_side := corridor + Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH
	for side in [-1, 1]:
		var tile := Vector2i(door.x + side * RAID_VAN_OFFSET_TILES, far_side)
		if _map.tile_at(tile) == GameEnums.TileType.SIDEWALK and not _map.is_closed(tile):
			_raid_vans.append(_map.tile_to_world(tile))
	var lane := corridor + Tuning.SIDEWALK_WIDTH
	var from := Vector2i(door.x - RAID_PATROL_REACH_TILES, lane)
	var to := Vector2i(door.x + RAID_PATROL_REACH_TILES, lane)
	if _map.is_walkable(from) and _map.is_walkable(to):
		_raid_beat = PackedVector2Array([_map.tile_to_world(from), _map.tile_to_world(to)])

## **What she comes home to**: the raid arrives once she has left, is `Tuning.OUT_OF_SIGHT` from
## her door and none of it would be on screen — *nothing is seen to appear* — so it is waiting at
## home rather than arriving in front of her. Cold, whatever the run's heat: `night_raid` hunts at
## `Tuning.HEAT_HUNTS_LEVEL`, and a van that ran her down at her own door would make the doorstep
## the one place the day cannot end, which is the opposite of what the raid was decided as.
func _maybe_raid(her: Vector2, sight: Callable) -> void:
	if not _city or not _city.events or her == Vector2.INF:
		return
	var door := _map.doorstep_world_position()
	if her.distance_to(door) < Tuning.OUT_OF_SIGHT:
		return
	var points: Array[Vector2] = []
	points.append_array(Array(_raid_vans))
	points.append_array(Array(_raid_beat))
	if sight.is_valid():
		for point in points:
			if sight.call(point):
				return
	var van := EventCatalogue.by_id("night_raid")
	for at in _raid_vans:
		raid.append(_city.events.spawn_extra(van, at))
	if _raid_beat.size() == 2:
		var row := EventCatalogue.by_id("police_patrol")
		var patrol: EventDef = row.duplicate()
		# `shape` is a plain `RefCounted` field `Resource.duplicate()` does not copy (the note on
		# `EventScheduler._without_its_aftermath()`); dropped, the car draws and charges nothing.
		patrol.shape = row.shape
		patrol.solid_parts = row.solid_parts
		patrol.paces = true
		raid.append(_city.events.spawn_extra(patrol, _raid_beat[0], _raid_beat))
	Telemetry.note("contact", "the raid is at her building: %d vans and a patrol" % _raid_vans.size())

# ---------------------------------------------------------- day 11: the market ---

## **Day 11: the market is gone, and she finds it gone.** A commercial block ahead of her on the
## route she is walking, out of sight, is boarded up there and then — its storefronts shuttered
## (`City.present_block()`) and the market stalls at its frontage taken away with it
## (`EventManager.take_away_within()`) — so the street she was walking toward is dark by the time
## she reaches it. Sited as day 3's fire is (`docs/DECISIONS.md`, M179): after she has walked long
## enough to have chosen a way, on the branch of the day's route tree she is on
## (`EventScheduler.WalkSiting.cells_ahead()`), the block whose frontage she reaches first, and
## never one within `Tuning.OUT_OF_SIGHT` of her, so nothing is seen to change.
##
## **Permanent because it is the block's own arc.** Only a block whose arc is waiting to board up
## is a candidate, and it takes that step today rather than on its own later day
## (`CityState.advance_now()`), so it is boarded for the rest of the run and a lost day gives it
## back with the dawn's photograph. If nothing on her way has qualified by `Tuning.MARKET_GONE_BY`,
## the candidate nearest her that she cannot see goes instead: the city loses its market whichever
## way she walked. A city whose arcs board nothing after day 11 has no market to lose, and says so
## in the run log.
func _maybe_the_market(delta: float, her: Vector2) -> void:
	if her == Vector2.INF or not _city or not _map:
		return
	if _walked < EventDirector.ON_HER_WAY_AFTER and _elapsed < Tuning.MARKET_GONE_BY:
		return
	_look_in -= delta
	if _look_in > 0.0:
		return
	_look_in = EventDirector.ON_HER_WAY_LOOK
	var candidates := market_candidates(_map, GameState.city_state)
	if candidates.is_empty():
		_market_owed = false
		Telemetry.note("contact", "no block is waiting to board up, so there is no market to lose")
		return
	var block := _market_ahead_of(her, candidates)
	if block.x < 0 and _elapsed >= Tuning.MARKET_GONE_BY:
		block = _market_out_of_her_sight(her, candidates)
	if block.x >= 0:
		board_up(block)

## Every block that is commercial today and whose arc is waiting to board up next, in the
## lattice's own order — the blocks day 11's market can be.
static func market_candidates(map: CityMap, state: CityState) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if not map or not state:
		return found
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			if not map.block_plans.has(block):
				continue
			if state.purpose_of(map.block_plans, block) == GameEnums.BlockPurpose.COMMERCIAL \
					and state.next_purpose(map.block_plans, block) \
							== GameEnums.BlockPurpose.BOARDED_UP:
				found.append(block)
	return found

## The candidate whose frontage she reaches first along the branch she is walking, out of her
## sight, or `(-1, -1)`.
func _market_ahead_of(her: Vector2, candidates: Array[Vector2i]) -> Vector2i:
	if not _siting:
		_siting = EventScheduler.WalkSiting.new(_day, _map, _city.route_tree(),
				GameState.settled_this_act(), PackedVector2Array())
	var ahead := _siting.cells_ahead(her, _heading, INF)
	var best := Vector2i(-1, -1)
	var nearest := INF
	for block in candidates:
		var lot := _frontage_of(block)
		if _distance_to_rect(her, lot) < Tuning.OUT_OF_SIGHT:
			continue
		for cell: Vector2i in ahead:
			var walk := float(ahead[cell])
			if walk < nearest and lot.has_point(_siting.cell_centre(cell)):
				nearest = walk
				best = block
	return best

## The candidate nearest her that she cannot see, or `(-1, -1)`.
func _market_out_of_her_sight(her: Vector2, candidates: Array[Vector2i]) -> Vector2i:
	var best := Vector2i(-1, -1)
	var nearest := INF
	for block in candidates:
		var distance := _distance_to_rect(her, _frontage_of(block))
		if distance >= Tuning.OUT_OF_SIGHT and distance < nearest:
			nearest = distance
			best = block
	return best

## Boards `block` up now and takes its market away: the arc's own next step, taken today, the
## buildings shown shuttered, and the stalls at its frontage gone from the day's plan.
func board_up(block: Vector2i) -> bool:
	var state := GameState.city_state
	if not state or not state.advance_now(_map.block_plans, block, _day,
			GameEnums.BlockPurpose.BOARDED_UP, GameEnums.BlockCause.SCHEDULED):
		return false
	market_block = block
	_market_owed = false
	if _city:
		_city.present_block(block, state)
	var stalls := 0
	if _city and _city.events:
		stalls = _city.events.take_away_within(_frontage_of(block), ["market_stall"] as Array[String])
	Telemetry.note("contact", "the market at block %s is gone: boarded up, %d stall(s) taken away"
			% [block, stalls])
	return true

## A block's lot and the sidewalk round it, in world space: what a market on it stands in.
func _frontage_of(block: Vector2i) -> Rect2:
	return _map.tile_rect_to_world(_map.lot_rect(block).grow(Tuning.SIDEWALK_WIDTH))

static func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest := Vector2(clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y))
	return point.distance_to(nearest)

# ------------------------------------------------------------ day 12: the park ---

## **Day 12: the park is taken, and it closes in front of her** once she has reached its swing —
## *"*then* the park starts to close which will force her to go to another park"* (PLAYTEST-119).
## Called by the director the instant the swing is reached. The park stops being forced open and
## takes its arc's requisition now (`CityState.take()`), so it is requisitioned for the rest of the
## run; the city stops counting it as calm (`CityMap.recompute_calm()`); and its ground goes from
## grass to churned mud a ring at a time from the edges in, over `Tuning.PARK_CLOSING_SECONDS`
## (`City.close_ground()`), so the calm left under her shrinks toward the swing while she watches
## and is gone before the baby could be settled in it. Mud is walkable ground: she is never shut
## in, she only has to go elsewhere, and the day has kept a second clean park reachable for exactly
## that (`docs/CITY.md`, "Guarantees"). Returns whether the park was taken.
func take_the_park() -> bool:
	if not _map:
		return false
	var park := CityGenerator.swing_park(_map)
	var state := GameState.city_state
	if park.x < 0 or not state or not state.take(_map.block_plans, park, _day):
		return false
	_map.recompute_calm(state)
	var layout: BlockLayout = _map.block_layouts.get(park)
	_closing = _rings_of(layout.open_rect) if layout else []
	_closing_every = Tuning.PARK_CLOSING_SECONDS / maxf(1.0, float(_closing.size()))
	_closing_in = 0.0
	_closing_park = park
	Telemetry.note("contact", "the park at block %s is being taken: %d rings over %.0fs"
			% [park, _closing.size(), Tuning.PARK_CLOSING_SECONDS])
	return true

## Whether day 12's park is still closing. Kept for the tests.
func is_closing() -> bool:
	return not _closing.is_empty()

## `rect`'s calm tiles in rings from the outside in: ring 0 is the edge, the last ring the middle.
func _rings_of(rect: Rect2i) -> Array:
	var rings: Array = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not Tile.is_calm(_map.tile_at(tile)):
				continue
			var ring := mini(mini(x - rect.position.x, rect.end.x - 1 - x),
					mini(y - rect.position.y, rect.end.y - 1 - y))
			while rings.size() <= ring:
				rings.append([] as Array[Vector2i])
			(rings[ring] as Array[Vector2i]).append(tile)
	return rings

func _close_a_ring(delta: float) -> void:
	_closing_in -= delta
	while _closing_in <= 0.0 and not _closing.is_empty():
		var ring: Array[Vector2i] = _closing.pop_front()
		if _city:
			_city.close_ground(ring)
		else:
			for tile in ring:
				_map.repaint_tile(tile, GameEnums.TileType.SPOILED)
		_closing_in += _closing_every
	if _closing.is_empty():
		var layout: BlockLayout = _map.block_layouts.get(_closing_park)
		if layout and _city and _city.events:
			_city.events.take_away_within(_map.tile_rect_to_world(layout.open_rect),
					["playground"] as Array[String])
		Telemetry.note("contact", "the park at block %s is taken" % _closing_park)

# ----------------------------------------------------------- day 13: the column ---

## **Day 13: a column on the main road, coming on her way** — the morning the army arrives, when
## the convoys start (`military_convoy`'s `first_day`). `Tuning.COLUMN_TRUCKS` army trucks, one
## behind the other `Tuning.COLUMN_SPACING` apart in one lane of the spine, sent down it toward the
## point level with her once she comes within `Tuning.COLUMN_WITHIN` of the main road — or at
## `Tuning.COLUMN_BY` into the day wherever she is, when it passes out of her sight. Each truck is
## the catalogue's own row with its own telegraph contract; the column is sited as a road-going
## row sited at her is (`Tuning.outlasting_telegraph_lead()`), far enough up the road that its
## telegraph is over before its field reaches her, and it drives on past her.
##
## **What it leaves is the barricade** its rear truck stops at, out of her sight beyond where she
## stood — or, where nothing beyond her will do, short of her on the stretch it drives in on — the
## row's own `spawns_on_finish`, so it is a scar and stands for the rest of the run, but only where
## she can still reach home and a calm area with it standing
## (`EventScheduler.WalkSiting.leaves_her_a_way()`), checked before the stop is accepted, a block
## further on at a time. The trucks ahead of it drive on without one. A column with nowhere to stop
## leaves nothing and says so.
func _maybe_the_column(her: Vector2) -> void:
	if her == Vector2.INF or not _city or not _city.events or _map.main_road < 0:
		return
	var near := absf(her.x - _spine_x()) <= Tuning.COLUMN_WITHIN
	if not (near and _walked >= EventDirector.ON_HER_WAY_AFTER) and _elapsed < Tuning.COLUMN_BY:
		return
	_column_owed = false
	send_the_column(her)

## The main road's middle, across it.
func _spine_x() -> float:
	return (float(_map.main_road * CityMap.period()) + Tuning.STREET_WIDTH * 0.5) \
			* Tuning.TILE_SIZE

## Sends the column down the main road toward the point level with `her`, from whichever end the
## day's stream picks, and returns its trucks, front first.
func send_the_column(her: Vector2) -> Array[EventInstance]:
	var def := EventCatalogue.by_id("military_convoy")
	if not def or _map.main_road < 0:
		return column
	var going := 1.0 if _rng.randf() < 0.5 else -1.0
	var top := Tuning.TILE_SIZE * 0.5
	var bottom := _map.size.y * Tuning.TILE_SIZE - Tuning.TILE_SIZE * 0.5
	var lead := Tuning.outlasting_telegraph_lead(Vector2(0.0, -going),
			def.speed + Tuning.WALK_SPEED, def.telegraph_time, Tuning.OFFSCREEN_NOTICE,
			def.field_reach())
	var past := Tuning.OUT_OF_SIGHT + def.field_reach()
	# From the end with room for the whole approach behind her and a stop beyond her, when only
	# one end has it; with neither, from the end with more road behind her. The spine leaves the
	# map by a tunnel and a bridge, so a lead the map cannot hold starts at its edge.
	var fits := func(way: float) -> bool:
		var behind := her.y - top if way > 0.0 else bottom - her.y
		var ahead := bottom - her.y if way > 0.0 else her.y - top
		return behind >= lead and ahead >= past
	if not fits.call(going):
		if fits.call(-going):
			going = -going
		else:
			var behind_here := her.y - top if going > 0.0 else bottom - her.y
			if behind_here < (bottom - top) - behind_here:
				going = -going
	var lane_x := CrowdLanes.lane_centre(_map.main_road, CrowdLanes.road_lane(true, going))
	var start_y := clampf(her.y - going * lead, top, bottom)
	# Beyond her first, the way it is going; and where no stop ahead of her will do, short of her,
	# on the stretch it drives in on, before it has reached her at all.
	var stop := _where_the_column_stops(her, lane_x, her.y + going * past, going, INF, def)
	if stop == Vector2.INF:
		stop = _where_the_column_stops(her, lane_x, her.y - going * past, -going,
				absf(start_y - her.y), def)
	var far_y := bottom if going > 0.0 else top
	var trailing := EventScheduler._without_its_aftermath(def)
	for i in Tuning.COLUMN_TRUCKS:
		var back := -going * Tuning.COLUMN_SPACING * i
		var from := Vector2(lane_x, clampf(start_y + back, top, bottom))
		var rear := i == Tuning.COLUMN_TRUCKS - 1
		var to := Vector2(lane_x, stop.y if rear and stop != Vector2.INF else far_y)
		var truck := def if rear and stop != Vector2.INF else trailing
		column.append(_city.events.spawn_extra(truck, from,
				PackedVector2Array([from, to])))
	Telemetry.note("contact", "a column of %d trucks comes down the main road %s%s" % [
		Tuning.COLUMN_TRUCKS, "south" if going > 0.0 else "north",
		", and stops at %s" % TelemetryLog.tile(_map.world_to_tile(stop)) if stop != Vector2.INF
				else ", with nowhere to stop"])
	return column

## Where the rear truck stops and leaves its barricade: from `wanted_y` on along the road in the
## direction `going`, no further than `limit` from her, the first point in the middle of a street
## (never a junction, which would close the crossing with it) whose barricade leaves her a way home
## and to a calm area — or `Vector2.INF`.
func _where_the_column_stops(her: Vector2, lane_x: float, wanted_y: float, going: float,
		limit: float, def: EventDef) -> Vector2:
	var barricade := EventCatalogue.by_id(def.spawns_on_finish)
	if not barricade:
		return Vector2.INF
	if not _siting:
		_siting = EventScheduler.WalkSiting.new(_day, _map, _city.route_tree(),
				GameState.settled_this_act(), PackedVector2Array())
	var tile := _map.world_to_tile(Vector2(lane_x, wanted_y))
	var step := Vector2i(0, 1 if going > 0.0 else -1)
	# A block at a time once a stop is refused, three blocks at most: each refusal is a flood.
	var refused := 0
	while _map.in_bounds(tile) and refused < 3:
		var at := Vector2(lane_x, _map.tile_to_world(tile).y)
		if absf(at.y - her.y) > limit:
			return Vector2.INF
		if StreetNetwork.segment_containing(tile) == null or not _map.is_driveable_at(true, tile):
			tile += step
			continue
		if _siting.leaves_her_a_way(_city.events.plans(),
				EventScheduler.Planned.new(barricade, at), her):
			return at
		refused += 1
		tile += step * CityMap.period()
	return Vector2.INF

## The neighbor, leaving for work as she does: out of the same door and along the same sidewalk,
## away from her, until the street runs out or something closes it, then off the ordinary way a
## route that ran out leaves (`EventInstance._be_done()`). **Nothing points at them** — no arrow,
## no field, no line of text — so the neighbor is a figure she may notice and never a task.
##
## The way is a coin flip between the two directions along her street, each taken as far as
## `EventScheduler._room_along()` allows and stopped short of a closed tile, the same shape every
## route along a street is given; the longer one when only one fits a block. A figure walking half
## her pace down her own street is out of sight long before the route runs out, whichever way she
## goes, so the departure at its end is one nobody sees.
func _send_the_neighbor_to_work() -> EventInstance:
	if not _city or not _city.events or not _map:
		return null
	var def := EventCatalogue.by_id("neighbor")
	if not def:
		return null
	var door := _map.doorstep_world_position()
	var tile := _map.world_to_tile(door)
	var east := EventScheduler._room_along(_map, tile, Vector2i.RIGHT)
	var west := EventScheduler._room_along(_map, tile, Vector2i.LEFT)
	var along := Vector2i.RIGHT if east >= west else Vector2i.LEFT
	if mini(east, west) >= CityMap.period() and _rng.randf() < 0.5:
		along = -along
	var room := maxi(east, west)
	var length := 0
	for step in range(1, room + 1):
		if _map.is_closed(tile + along * step) or not _map.is_walkable(tile + along * step):
			break
		length = step
	if length < 2:
		return null
	var start := door + Vector2(along) * NEIGHBOR_BESIDE_HER
	var finish := _map.tile_to_world(tile + along * length)
	finish.y = start.y
	var path := PackedVector2Array([start, finish])
	Telemetry.note("contact", "the neighbor leaves for work, %s along her street"
			% ("east" if along.x > 0 else "west"))
	return _city.events.spawn_extra(def, start, path)
