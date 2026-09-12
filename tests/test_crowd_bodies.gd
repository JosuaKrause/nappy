extends RefCounted
## The crowd against the things standing in the street: a café's tables, a construction band, a
## kerbed van, a stall. *("yes every solid body should do that -- not necessarily force a turn
## around but at least avoid the solid".)*
##
## Kept apart from `test_crowd.gd` because that file is already the longest suite on disk and these
## all want the same rig: a real generated city with **no day planned on it**, so `held_segments`
## and `soft_sealed_tiles` are empty and the only thing standing anywhere is the body the test put
## there. The wiring that fills `CityMap.obstructed_tiles` from a real day is `EventManager`'s and
## is asked about by the sweep at the bottom, which plans real days on three seeds.
##
## The three geometry tests place their agents by hand on a straight stretch this seed's city
## actually has, rather than on tile coordinates written down here: a city is generated and the
## streets it happens to grow are not a constant.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	var map := CityGenerator.generate(SEED)
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)

	_test_a_walker_steps_round_a_one_lane_body(t, city, map)
	_test_a_body_across_a_footway_turns_a_walker_at_the_junction(t, city, map)
	_test_a_body_in_a_lane_turns_a_car_and_leaves_the_oncoming_lane_alone(t, city, map)
	_test_a_one_piece_row_records_exactly_the_tiles_its_shape_covers(t, map)
	_test_a_crash_records_its_cars_and_not_the_pavements_beside_them(t, map)

	city.free()
	_test_nobody_ever_stands_in_a_body_on_a_real_day(t)

# ------------------------------------------------------------------- the rig ---

## A straight stretch of ordinary vertical street this city actually has, as the corridor index and
## the first along tile of a run of `length` tiles that is street all the way across and all the way
## down. Returns `-1` for the corridor when the city has no such run, which no generated city does —
## the caller checks, so a rig that has quietly stopped testing anything says so.
func _a_straight_run(map: CityMap, length: int) -> Vector2i:
	for corridor in range(1, CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x) - 1):
		if corridor == map.main_road:
			continue
		for start in range(4, map.size.y - length - 4):
			if _run_is_ordinary_street(map, corridor, start, length):
				return Vector2i(corridor, start)
	return Vector2i(-1, -1)

func _run_is_ordinary_street(map: CityMap, corridor: int, start: int, length: int) -> bool:
	for along in range(start, start + length):
		if map.street_kind(true, corridor, along) != GameEnums.StreetKind.ORDINARY:
			return false
		for offset in range(Tuning.STREET_WIDTH):
			var tile := Vector2i(corridor * CityMap.period() + offset, along)
			if not map.is_street(tile) or map.is_closed(tile):
				return false
	return true

## Stands a solid body on `lanes` over the along tiles `[from, to]`, straight into the record the
## crowd reads. The rasterising of a real `GroundShape` into those tiles is `GroundShape.
## tiles_under()`'s own job and `EventManager`'s to call; what these tests are about is what the
## crowd does once the tiles are there.
func _stand_a_body(map: CityMap, corridor: int, lanes: Array, from: int, to: int) -> void:
	var tiles: Array[Vector2i] = []
	for lane: int in lanes:
		for along in range(from, to + 1):
			tiles.append(Vector2i(corridor * CityMap.period() + lane, along))
	map.obstruct_tiles(1, tiles)

## An agent on one lane of one corridor, walking or driving at a given along position, added to the
## day's (emptied) crowd so `Crowd.step()` moves it exactly as it moves anybody.
func _agent_on(city: City, map: CityMap, kind: CrowdAgent.Kind, corridor: int, lane: int,
		along: float, direction: float) -> CrowdAgent:
	var agent := CrowdAgent.new()
	agent.setup(kind, map, city.crowd.field(), 1, 0.0)
	agent._vertical = true
	agent._corridor = corridor
	agent._lane = lane
	agent._direction = direction
	agent._lane_centre = CrowdLanes.lane_centre(corridor, lane) if kind == CrowdAgent.Kind.CAR \
			else CrowdLanes.walker_lane_centre(corridor, lane, CrowdLanes.SIDEWALK_OFFSETS)
	agent._speed = 60.0 if kind == CrowdAgent.Kind.WALKER else 130.0
	agent._cruise = agent._speed
	agent._set_along(along)
	agent._set_cross(agent._lane_centre)
	agent._junction = -1
	agent._scan_at = Vector2i(-9999, -9999)
	agent._blocked_in = CrowdAgent.LOOKAHEAD_TILES + 1
	city.add_entity(agent)
	city.crowd._agents.append(agent)
	return agent

## Walks the crowd for `seconds` with the field pinned on `at`, and reports what happened to
## `watched`: whether anybody was ever standing on a body's own tile, whether it ever stepped round
## one, and how far down and up the street it got.
##
## **Measured in world coordinates rather than as `_along()`**, because a turn swaps the axes: an
## agent that has taken a corner reports its distance across the old street as its distance along
## the new one, and a test reading that is comparing two different numbers.
func _walk(city: City, map: CityMap, watched: CrowdAgent, at: Vector2,
		seconds: float) -> Dictionary:
	var inside := 0
	var stepped_round := false
	var deepest := watched.position.y
	var shallowest := watched.position.y
	for frame in int(round(seconds / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent in city.crowd.agents():
			if map.is_obstructed(map.world_to_tile(agent.position)):
				inside += 1
		stepped_round = stepped_round or watched._body_detour_held
		deepest = maxf(deepest, watched.position.y)
		shallowest = minf(shallowest, watched.position.y)
	return {"inside": inside, "stepped_round": stepped_round, "deepest": deepest,
			"shallowest": shallowest}

## The cross-axis span of one footway of a vertical corridor, in world px — the ground a walker on
## that pavement stands on, kerb to frontage.
func _footway_span(corridor: int, near: bool) -> Vector2:
	var first: int = CrowdLanes.SIDEWALK_OFFSETS[0 if near else 2]
	var last: int = CrowdLanes.SIDEWALK_OFFSETS[1 if near else 3]
	var half := float(Tuning.TILE_SIZE) * 0.5
	return Vector2(CrowdLanes.lane_centre(corridor, first) - half,
			CrowdLanes.lane_centre(corridor, last) + half)

# ------------------------------------------------------------- one lane taken ---

## A café on one lane of a footway is stepped round rather than turned away from: the other lane of
## the same pavement is clear, so the walker takes it, passes the body and comes back.
##
## The whole run is inside one block's length of street, with no junction in it, so what is being
## asked about is the sidestep and not the random corner turn a walker rolls at every junction.
func _test_a_walker_steps_round_a_one_lane_body(t, city: City, map: CityMap) -> void:
	var run := _a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a straight stretch of ordinary street to stand a body in")
	if run.x < 0:
		return
	var corridor := run.x
	var start := run.y
	var body_at := start + 5
	_stand_a_body(map, corridor, [0], body_at, body_at + 1)
	city.crowd.start_day(1, _rng(1), Vector2.ZERO)
	city.crowd.clear()

	var walker := _agent_on(city, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(start) * Tuning.TILE_SIZE + 4.0, 1.0)
	var at := map.tile_to_world(Vector2i(corridor * CityMap.period() + 1, body_at))
	var walked := _walk(city, map, walker, at, 6.0)

	t.check(walked["inside"] == 0,
			"a walker never stands on a body's own tile while going round it (%d frames it did)"
			% walked["inside"])
	t.check(walked["stepped_round"],
			"and it does go round: the sidestep onto the other lane of its own footway is taken")
	t.check(walked["deepest"] > float(body_at + 2) * Tuning.TILE_SIZE,
			"and it gets past the body rather than stopping at it (reached %.0f, body ends %.0f)"
			% [walked["deepest"], float(body_at + 2) * Tuning.TILE_SIZE])
	map.clear_day_obstructions()

# ---------------------------------------------------------- a whole footway ---

## A body across **both** lanes of one footway shuts that footway to a walker the way a soft seal
## does, so it turns at the last junction instead of walking into it — and the other footway and the
## carriageway are untouched, which is the whole difference between a body and a seal.
##
## The predicate is asked directly as well as walked, for the reason the region-door test asks its
## own directly: whether `_cannot_go_on` refuses the ground is the question, and whether a randomly
## placed crowd happens to visit one exact tile inside a short window is not.
func _test_a_body_across_a_footway_turns_a_walker_at_the_junction(t, city: City,
		map: CityMap) -> void:
	var run := _a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a long enough stretch for a walker to turn in")
	if run.x < 0:
		return
	var corridor := run.x
	# Far enough down the run that a junction band lies between the walker and the body.
	var body_at := run.y + CityMap.period() + 2
	_stand_a_body(map, corridor, [0, 1], body_at, body_at + 1)
	city.crowd.start_day(1, _rng(1), Vector2.ZERO)
	city.crowd.clear()

	var base := corridor * CityMap.period()
	var walker := _agent_on(city, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)
	t.check(walker._cannot_go_on(true, Vector2i(base + 0, body_at)),
			"a taken footway is shut to a walker on it, the way a soft seal is")
	t.check(not walker._cannot_go_on(true, Vector2i(base + 4, body_at)),
			"and the other footway is not — a body takes a pavement, never a street")
	var car := _agent_on(city, map, CrowdAgent.Kind.CAR, corridor, 2,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	t.check(not car._cannot_go_on(true, Vector2i(base + 2, body_at)),
			"and neither is the carriageway under it")
	city.crowd._agents.erase(car)
	car.queue_free()

	# Walked by hand rather than through `_walk`, because the property is about the walker's own
	# footway rather than about the street: the **other** pavement is deliberately still open, so a
	# walker that turns at the junction, takes the crossing street and comes back onto this one on
	# the far footway has done exactly the right thing and is past the body's own along position.
	var at := map.tile_to_world(Vector2i(base + 1, body_at))
	var near := _footway_span(corridor, true)
	var inside := 0
	var reached_on_its_own_footway := false
	for frame in int(round(12.0 / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent in city.crowd.agents():
			if map.is_obstructed(map.world_to_tile(agent.position)):
				inside += 1
			if agent.position.x >= near.x and agent.position.x <= near.y \
					and agent.position.y >= float(body_at) * Tuning.TILE_SIZE \
					and agent.position.y < float(body_at + 2) * Tuning.TILE_SIZE:
				reached_on_its_own_footway = true
	t.check(inside == 0,
			"nobody walks into a body that takes their whole footway (%d frames somebody did)"
			% inside)
	t.check(not reached_on_its_own_footway,
			"and nobody gets as far as it on that footway at all — the shut pavement carries no "
			+ "traffic, the way a soft-sealed one does not")
	map.clear_day_obstructions()

# ----------------------------------------------------------------- a car lane ---

## A body in a car's own lane shuts that direction to it — one lane per direction and the oncoming
## one is not an option — so it turns at the last junction through the machinery a closure already
## uses. The oncoming lane is a different tile and keeps flowing, which is what this asks in the
## same breath: both cars are on the road at the same time and only one of them has anything in
## front of it.
func _test_a_body_in_a_lane_turns_a_car_and_leaves_the_oncoming_lane_alone(t, city: City,
		map: CityMap) -> void:
	var run := _a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a long enough stretch for a car to turn in")
	if run.x < 0:
		return
	var corridor := run.x
	var base := corridor * CityMap.period()
	var body_at := run.y + CityMap.period() + 2
	var blocked_lane: int = CrowdLanes.road_lane(true, 1.0)
	var open_lane: int = CrowdLanes.road_lane(true, -1.0)
	_stand_a_body(map, corridor, [blocked_lane], body_at, body_at + 1)
	city.crowd.start_day(1, _rng(1), Vector2.ZERO)
	city.crowd.clear()

	var blocked := _agent_on(city, map, CrowdAgent.Kind.CAR, corridor, blocked_lane,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	var oncoming := _agent_on(city, map, CrowdAgent.Kind.CAR, corridor, open_lane,
			float(body_at + 8) * Tuning.TILE_SIZE, -1.0)
	t.check(blocked._cannot_go_on(true, Vector2i(base + blocked_lane, body_at)),
			"a body in a car's lane is a wall to it")
	t.check(not oncoming._cannot_go_on(true, Vector2i(base + open_lane, body_at)),
			"and the oncoming lane, which is a different tile, is untouched")

	var at := map.tile_to_world(Vector2i(base + blocked_lane, body_at))
	var oncoming_started := oncoming.position.y
	var walked := _walk(city, map, blocked, at, 10.0)
	t.check(walked["inside"] == 0,
			"no car ever stands on the body's own tile (%d frames one did)" % walked["inside"])
	# Turned off this street, or still on it and stopped short. Both are the entry's own answer —
	# *"a car already in the street with no junction left before the body stops behind it"* — and
	# which one a given seed's geometry produces is not a property worth pinning.
	var turned_away: bool = blocked._corridor != corridor or not blocked._vertical \
			or blocked._direction < 0.0
	t.check(turned_away or walked["deepest"] < float(body_at) * Tuning.TILE_SIZE,
			"and it turns off the street or comes to rest short of the body")
	t.check(oncoming_started - oncoming.position.y > float(CityMap.period()) * Tuning.TILE_SIZE,
			"while the oncoming lane keeps flowing past it (%.0fpx covered)"
			% (oncoming_started - oncoming.position.y))
	map.clear_day_obstructions()

# --------------------------------------------------------- a body in pieces ---
# `EventManager.obstructed_footprint()` rasterises `EventDef.parts()` rather than the row's one
# `shape`. Every row but the crash declares no parts, which means one piece at the origin carrying
# `shape`, and these two tests are the two halves of that sentence: nothing moved for the rows that
# are one piece, and the crash records its two cars instead of the street they are lying across.

## A row that is one piece records **exactly** the tiles its own `shape` covers — the tiles it
## recorded before the record learned about pieces.
##
## Asserted against `GroundShape.tiles_under()` directly rather than against a written-down list,
## because the point is that the two agree: a list would pass while both drifted together. Three
## rows of different shapes, so a point body and a band body are both covered.
func _test_a_one_piece_row_records_exactly_the_tiles_its_shape_covers(t, map: CityMap) -> void:
	var run := _a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a straight stretch to site a body on")
	if run.x < 0:
		return
	var at := map.tile_to_world(Vector2i(run.x * CityMap.period() + 1, run.y + 3))
	var checked := 0
	for id: String in ["cafe_tables", "construction", "delivery_van"]:
		var def := EventCatalogue.by_id(id)
		if def == null or def.shape == null or def.obstructs_radius <= 0.0:
			continue
		t.check(def.parts().size() == 1, "'%s' is one piece, so it is this test's business" % id)
		var placed := at
		if def.pavement_side == EventDef.Pavement.ANY:
			placed = EventInstance._centred_on_the_pavement_band(map, at)
		var axis := EventManager._body_axis(map, def, placed, Vector2.RIGHT)
		var before := def.shape.tiles_under(placed, axis)
		var after := EventManager.obstructed_footprint(map, def, at, Vector2.RIGHT)
		before.sort()
		after.sort()
		t.check(not before.is_empty(), "'%s' stands on ground at all (%d tiles)" % [id, before.size()])
		t.check(after == before,
				"'%s' records exactly its own shape's tiles: %d against %d"
				% [id, after.size(), before.size()])
		checked += 1
	t.check(checked == 3, "there were one-piece rows to ask about (%d)" % checked)

## A crash records **its two cars** and not the street they are lying across: the tiles its whole
## 192px band would have taken are a strict superset, and the pavement lanes the picture leaves open
## are in the difference.
##
## Sited by hand on an unheld street rather than by planning a day, and that is the test's own
## finding as much as its rig: on a real day a crash is a hard seal, `SealPlanner.plan_day` marks
## every hard seal's segment in `CityMap.held_segments`, and the record skips a body on held ground
## because the whole street is shut to the crowd already. So this asks the rasterising — the half
## M118 changed — on ground where the answer is not thrown away.
func _test_a_crash_records_its_cars_and_not_the_pavements_beside_them(t, map: CityMap) -> void:
	var run := _a_straight_run(map, Tuning.BLOCK_SIZE)
	if run.x < 0:
		return
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("car_accident"), true)
	t.check(def.parts().size() == 2, "a crash is two cars (%d pieces)" % def.parts().size())
	var base := run.x * CityMap.period()
	var along := run.y + 3
	# The middle of the carriageway, which is where `SealPlanner._hard_positions` stands the one
	# copy a 96px reach takes to span a 6-tile street.
	var at := Vector2(float(base) * Tuning.TILE_SIZE + float(Tuning.STREET_WIDTH) * 16.0,
			(float(along) + 0.5) * Tuning.TILE_SIZE)
	var axis := EventManager._body_axis(map, def, at, Vector2.RIGHT)
	var whole_band := def.shape.tiles_under(at, axis)
	var cars := EventManager.obstructed_footprint(map, def, at, Vector2.RIGHT)
	t.check(not cars.is_empty(), "the cars stand on ground (%d tiles)" % cars.size())
	t.check(cars.size() < whole_band.size(),
			"the two cars take less ground than the band across the street would (%d of %d tiles)"
			% [cars.size(), whole_band.size()])
	var left_out := 0
	for tile: Vector2i in whole_band:
		if not cars.has(tile):
			left_out += 1
	t.check(left_out > 0, "and the ground between and beside them is open (%d tiles)" % left_out)
	# The pavements the picture shows an onlooker standing on, never the cars: the outermost lane of
	# each footway, which is as far from the carriageway's middle as this street gets.
	for offset: int in [CrowdLanes.SIDEWALK_OFFSETS[0], CrowdLanes.SIDEWALK_OFFSETS[3]]:
		var pavement := Vector2i(base + offset, along)
		t.check(not cars.has(pavement),
				"the pavement at offset %d beside the crash carries no body" % offset)
		t.check(whole_band.has(pavement),
				"and the whole-street band it replaces did carry one, so this is a real difference")

# ------------------------------------------------------------------ the sweep ---

## Nobody is ever inside a body's own footprint, over a day's real crowd on a day's real plan,
## across several seeds. The property the whole item is for, asked the way
## `test_crowd.gd`'s hard-seal test asks its own: a count of frames, and the count is zero.
##
## **Stated over the record rather than over the catalogue**, because the record is what the crowd
## reads: a seed whose day happened to place nothing solid would pass vacuously, so the tile count
## is checked as well.
##
## **A crash's two cars are asked about separately, and off the catalogue rather than off the
## record.** They are not in the record at all — a crash is a hard seal and the record skips a body
## on held ground — so what keeps the crowd out of them is `CityMap.held_segments` shutting the
## whole street, and that is a different sentence worth its own count. Vacuity is guarded the same
## way: the number of car bodies the days actually placed is checked.
##
## **Stated as *reaches* rather than *stands in*, and the difference is the placement fallback.**
## `CrowdAgent.setup()` re-rolls a position 24 times against `_stands_on_a_street()` and places the
## agent anyway if every draw lands on shut ground, which a day with many hard seals can produce —
## so a body does occasionally start the day standing on a sealed street, inside a crash among other
## places, and walks off it. That is the crowd's placement, not the seal's siting. What this holds
## is the sentence the siting owns: every agent ever found inside a car is on ground the crowd is
## held off, so no car is ever sited somewhere the crowd can legitimately walk.
func _test_nobody_ever_stands_in_a_body_on_a_real_day(t) -> void:
	var cars_seen := 0
	for city_seed: int in [4242, 24757, 91117]:
		var map := CityGenerator.generate(city_seed)
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(map)
		for day: int in [1, 6]:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			var closures := RandomNumberGenerator.new()
			closures.seed = hash("bodies-closures:%d:%d" % [city_seed, day])
			city.start_day(state, day, closures)
			var events := RandomNumberGenerator.new()
			events.seed = hash("bodies-events:%d:%d" % [city_seed, day])
			var consumed: Array[String] = []
			city.events.start_day(day, events, consumed)
			t.check(map.obstructed_tiles.size() > 0,
					"seed %d day %d stands solid bodies somewhere to be asked about (%d tiles)"
					% [city_seed, day, map.obstructed_tiles.size()])

			var at := map.doorstep_world_position()
			var crowd_rng := RandomNumberGenerator.new()
			crowd_rng.seed = hash("bodies-crowd:%d:%d" % [city_seed, day])
			city.crowd.start_day(day, crowd_rng, at)
			city.crowd.set_gates(city.region_plan().gates)
			var cars := _car_bodies(map, city.events)
			cars_seen += cars.size()
			var inside := 0
			var in_a_car := 0
			var reached_a_car := 0
			for frame in int(round(20.0 / STEP)):
				city.crowd.set_focus(at)
				city.crowd.step(STEP)
				for agent in city.crowd.agents():
					if map.is_obstructed(map.world_to_tile(agent.position)):
						inside += 1
					for car: Array in cars:
						if agent.position.distance_to(car[0]) < float(car[1]):
							in_a_car += 1
							if not map.is_held_at(map.world_to_tile(agent.position)):
								reached_a_car += 1
			t.check(inside == 0,
					"seed %d day %d: nobody in the crowd ever stands inside a solid body "
					% [city_seed, day] + "(%d agent-frames they did)" % inside)
			t.check(reached_a_car == 0,
					"seed %d day %d: nobody in the crowd ever reaches a crashed car across open "
					% [city_seed, day] + "ground (%d agent-frames of %d inside a car were on "
					% [reached_a_car, in_a_car] + "ground the crowd is not held off, over %d cars)"
					% cars.size())
		city.free()
	t.check(cars_seen > 0, "these days stood crashed cars somewhere at all (%d)" % cars_seen)

## Every crashed car standing on the day `events` has planned, as `[centre, radius]` pairs — the
## rows that declare `EventDef.solid_parts`, each piece placed the way
## `EventManager.obstructed_footprint()` places it. Read off the **plan** rather than off the live
## instances for the reason the record is: a plan covers the whole map and an instance only exists
## near the player.
func _car_bodies(map: CityMap, events: EventManager) -> Array:
	var bodies := []
	for plan in events.plans():
		if not plan.is_placed() or plan.def == null or plan.def.solid_parts.is_empty():
			continue
		var placed := plan.position
		if plan.def.pavement_side == EventDef.Pavement.ANY:
			placed = EventInstance._centred_on_the_pavement_band(map, placed)
		var vertical := EventInstance._spread_is_vertical(map, placed)
		for piece in plan.def.parts():
			var offset := piece.offset_for(vertical)
			var centre := placed + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0))
			bodies.append([centre, piece.shape.reach()])
	return bodies

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-bodies:%d:%d" % [SEED, day])
	return rng
