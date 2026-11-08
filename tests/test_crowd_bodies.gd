extends "res://tests/crowd_street_rig.gd"
## The crowd against the things standing in the street: a café's tables, a construction band, a
## kerbed van, a stall. *("yes every solid body should do that -- not necessarily force a turn
## around but at least avoid the solid".)*
##
## Kept apart from `crowd_rig.gd` because that file already holds the longest cases on disk and these
## all want the same rig: a crowd on a real generated map with **no day planned on it**, so
## `held` and `soft_sealed_tiles` are empty and the only thing standing anywhere is the
## body the test put there. No city is built around it (`Crowd.setup()` is handed a bare world, the
## map and its lights, as a task scene's rig hands it): this suite tests the crowd. The wiring that
## fills `CityMap.obstructed_tiles` from a real day is `EventManager`'s and is asked about by
## `test_crowd_bodies_on_a_real_day.gd`.
##
## The geometry tests place their agents by hand on a straight stretch this seed's map actually
## has, rather than on tile coordinates written down here: a map is generated and the streets it
## happens to grow are not a constant.

const MapCache := preload("res://tests/city_map_cache.gd")
const SEED := 4242
const STEP := 1.0 / 60.0

func run(t) -> void:
	var map := MapCache.of(SEED)
	var crowd := a_crowd(t, map)

	_test_a_walker_steps_round_a_one_lane_body(t, crowd, map)
	_test_a_body_across_a_footway_turns_a_walker_where_it_meets_it(t, crowd, map)
	_test_a_body_in_a_lane_turns_a_car_and_leaves_the_oncoming_lane_alone(t, crowd, map)
	_test_a_one_piece_row_records_exactly_the_tiles_its_shape_covers(t, map)
	_test_a_crash_records_its_cars_and_not_the_pavements_beside_them(t, map)
	_test_a_walker_passes_a_crash_on_its_pavement(t, crowd, map)
	_test_a_row_at_the_kerb_leaves_both_lanes_driving(t, crowd, map)
	_test_a_row_across_the_whole_street_still_turns_a_car(t, crowd, map)
	_test_a_precinct_blocked_across_its_width_turns_walkers_round(t, crowd, map)
	_test_partial_bodies_in_neighbouring_rows_wall_a_precinct(t, crowd, map)

	free_crowd(crowd)

# ------------------------------------------------------------------- the rig ---

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

## A body of `kind` the crowd accepts somewhere on this city's ordinary streets, whatever a day has
## sealed or held there: the first spot along any vertical corridor that the entry
## (`Crowd.add_recipe_actor()`) takes, or `null` when there is none.
func any_agent(crowd: Crowd, map: CityMap, kind: CrowdAgent.Kind, seed_value := 1) -> CrowdAgent:
	for corridor in range(1, CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x) - 1):
		for tile in range(8, map.size.y - 8, 3):
			var lane := CrowdLanes.road_lane(true, 1.0) if kind == CrowdAgent.Kind.CAR else 0
			var centre := CrowdLanes.lane_centre(corridor, lane) if kind == CrowdAgent.Kind.CAR \
					else CrowdLanes.walker_lane_centre(corridor, lane, CrowdLanes.SIDEWALK_OFFSETS)
			var placed := crowd.add_recipe_actor("any-%d" % crowd.agent_count(), kind,
					Vector2(centre, float(tile) * Tuning.TILE_SIZE), Vector2.DOWN,
					60.0 if kind == CrowdAgent.Kind.WALKER else 130.0, seed_value)
			if placed["error"] == "":
				return placed["actor"]
	return null

## A seed that gives a walker pinned with it the door answer `answer`: the first roll of the seed is
## the one a placement draws its answer from (`WalkerStrategy.door_answer_for()`).
func seed_for_door_answer(answer: WalkerStrategy.DoorAnswer) -> int:
	for seed_value in range(1, 1000):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if WalkerStrategy.door_answer_for(rng.randf()) == answer:
			return seed_value
	return -1

## Whether `car` is still driving in the positive direction down vertical corridor `corridor`: its
## heading is straight down the street and it is standing in that corridor.
func still_driving_down(car: CrowdAgent, corridor: int) -> bool:
	return car.heading().is_equal_approx(Vector2.DOWN) \
			and CrowdLanes.corridor_at(car.position.x) == corridor

## Walks the crowd for `seconds` with the field pinned on `at`, and reports what happened to
## `watched`: whether anybody was ever standing on a body's own tile, whether it ever stepped round
## one, and how far down and up the street it got.
##
## **Measured in world coordinates rather than as `_along()`**, because a turn swaps the axes: an
## agent that has taken a corner reports its distance across the old street as its distance along
## the new one, and a test reading that is comparing two different numbers.
func _walk(crowd: Crowd, map: CityMap, watched: CrowdAgent, at: Vector2,
		seconds: float) -> Dictionary:
	var inside := 0
	var stepped_round := false
	var deepest := watched.position.y
	var shallowest := watched.position.y
	var lane_x := watched.position.x
	for frame in int(round(seconds / STEP)):
		crowd.set_focus(at)
		crowd.step(STEP)
		for agent in crowd.agents():
			if map.is_obstructed(map.world_to_tile(agent.position)):
				inside += 1
		# A walker that goes round a body leaves the lane it started in, onto the other lane of its
		# own footway, a tile over; nothing else a walker does on this stretch takes it off its line.
		stepped_round = stepped_round or (watched.kind == CrowdAgent.Kind.WALKER
				and absf(watched.position.x - lane_x) > Tuning.TILE_SIZE * 0.5)
		deepest = maxf(deepest, watched.position.y)
		shallowest = minf(shallowest, watched.position.y)
	return {"inside": inside, "stepped_round": stepped_round, "deepest": deepest,
			"shallowest": shallowest}

## Whether any along tile in `[from, to)` is inside a junction band.
func _a_junction_below(from: int, to: int) -> bool:
	for along in range(from, to):
		if CityMap.corridor_offset(along) >= 0:
			return true
	return false

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
func _test_a_walker_steps_round_a_one_lane_body(t, crowd: Crowd, map: CityMap) -> void:
	var run := a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a straight stretch of ordinary street to stand a body in")
	if run.x < 0:
		return
	var corridor := run.x
	var start := run.y
	var body_at := start + 5
	_stand_a_body(map, corridor, [0], body_at, body_at + 1)
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()

	var walker := place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(start) * Tuning.TILE_SIZE + 4.0, 1.0)
	var at := map.tile_to_world(Vector2i(corridor * CityMap.period() + 1, body_at))
	var walked := _walk(crowd, map, walker, at, 6.0)

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

## A body across **both** lanes of one footway shuts that footway to a walker — and it shuts it
## *where it stands*, so the walker walks the pavement past the last junction, right up to the body,
## and turns round there. *(2026-09-19: "they should only give up if they touch an impassable
## wall".)* The other footway and the carriageway are untouched, which is the whole difference
## between a body and a seal.
##
## The predicate is asked directly as well as walked, for the reason the region-door test asks its
## own directly: whether `LaneStrategy.cannot_go_on()` refuses the ground is the question, and whether a randomly
## placed crowd happens to visit one exact tile inside a short window is not.
##
## **The junction before the body is what the walk is measured against**, rather than a distance in
## tiles: giving up at the last junction is exactly the behaviour this replaces, so the pavement
## between that junction and the body is the ground that used to be empty and now is not.
func _test_a_body_across_a_footway_turns_a_walker_where_it_meets_it(t, crowd: Crowd,
		map: CityMap) -> void:
	var run := a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a long enough stretch for a walker to turn in")
	if run.x < 0:
		return
	var corridor := run.x
	# Far enough down the run that a junction band lies between the walker and the body, **and**
	# that two tiles of plain pavement lie between that junction and the body — the ground a walker
	# that gave the street up at the junction never set foot on, which is what the walk below
	# counts. Landing the body against the junction's own last row leaves that window empty and the
	# count says nothing.
	var body_at := -1
	for along in range(run.y + 2, run.y + CityMap.period() + Tuning.BLOCK_SIZE - 1):
		if CityMap.corridor_offset(along - 1) >= 0 or CityMap.corridor_offset(along - 2) >= 0:
			continue
		if not _a_junction_below(run.y, along - 2):
			continue
		body_at = along
		break
	t.check(body_at > 0, "the run has a junction with pavement past it to stand a body on")
	if body_at < 0:
		return
	_stand_a_body(map, corridor, [0, 1], body_at, body_at + 1)
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()

	var base := corridor * CityMap.period()
	var walker := place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)
	t.check(walker.strategy.cannot_go_on(true, Vector2i(base + 0, body_at)),
			"a taken footway is shut to a walker on it, the way a soft seal is")
	t.check(not walker.strategy.cannot_go_on(true, Vector2i(base + 4, body_at)),
			"and the other footway is not — a body takes a pavement, never a street")
	var car := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, 2,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	t.check(not car.strategy.cannot_go_on(true, Vector2i(base + 2, body_at)),
			"and neither is the carriageway under it")
	crowd.clear()
	walker = place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)

	# The last junction band before the body, which is where this walker used to give the street up.
	var last_junction := -1
	for along in range(body_at - 1, run.y - 1, -1):
		if CityMap.corridor_offset(along) >= 0:
			last_junction = along
			break
	t.check(last_junction > run.y,
			"there is a junction between the walker and the body to not turn at (%d)" % last_junction)

	# Walked by hand rather than through `_walk`, because the property is about the walker's own
	# footway rather than about the street: the **other** pavement is deliberately still open, so a
	# walker that turns at the junction, takes the crossing street and comes back onto this one on
	# the far footway has done exactly the right thing and is past the body's own along position.
	var at := map.tile_to_world(Vector2i(base + 1, body_at))
	var near := _footway_span(corridor, true)
	var inside := 0
	var past_the_junction := 0
	for frame in int(round(12.0 / STEP)):
		crowd.set_focus(at)
		crowd.step(STEP)
		for agent in crowd.agents():
			if map.is_obstructed(map.world_to_tile(agent.position)):
				inside += 1
			if agent.position.x >= near.x and agent.position.x <= near.y \
					and agent.position.y > float(last_junction + 1) * Tuning.TILE_SIZE \
					and agent.position.y < float(body_at) * Tuning.TILE_SIZE:
				past_the_junction += 1
	t.check(inside == 0,
			"nobody walks into a body that takes their whole footway (%d frames somebody did)"
			% inside)
	t.check(past_the_junction > 0,
			("and the pavement between that junction and the body carries people right up to it "
			+ "(%d walker-frames on it)") % past_the_junction)
	map.clear_day_obstructions()

# ----------------------------------------------------------------- a car lane ---

## A body in a car's own lane shuts that direction to it — one lane per direction and the oncoming
## one is not an option — so it turns at the last junction through the machinery a closure already
## uses. The oncoming lane is a different tile and keeps flowing, which is what this asks in the
## same breath: both cars are on the road at the same time and only one of them has anything in
## front of it.
func _test_a_body_in_a_lane_turns_a_car_and_leaves_the_oncoming_lane_alone(t, crowd: Crowd,
		map: CityMap) -> void:
	var run := a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a long enough stretch for a car to turn in")
	if run.x < 0:
		return
	var corridor := run.x
	var base := corridor * CityMap.period()
	var body_at := run.y + CityMap.period() + 2
	var blocked_lane: int = CrowdLanes.road_lane(true, 1.0)
	var open_lane: int = CrowdLanes.road_lane(true, -1.0)
	_stand_a_body(map, corridor, [blocked_lane], body_at, body_at + 1)
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()

	var blocked := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, blocked_lane,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	var oncoming := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, open_lane,
			float(body_at + 8) * Tuning.TILE_SIZE, -1.0)
	t.check(blocked.strategy.cannot_go_on(true, Vector2i(base + blocked_lane, body_at)),
			"a body in a car's lane is a wall to it")
	t.check(not oncoming.strategy.cannot_go_on(true, Vector2i(base + open_lane, body_at)),
			"and the oncoming lane, which is a different tile, is untouched")

	var at := map.tile_to_world(Vector2i(base + blocked_lane, body_at))
	var oncoming_started := oncoming.position.y
	var walked := _walk(crowd, map, blocked, at, 10.0)
	t.check(walked["inside"] == 0,
			"no car ever stands on the body's own tile (%d frames one did)" % walked["inside"])
	# Turned off this street, or still on it and stopped short. Both are the entry's own answer —
	# *"a car already in the street with no junction left before the body stops behind it"* — and
	# which one a given seed's geometry produces is not a property worth pinning.
	var turned_away := not still_driving_down(blocked, corridor)
	t.check(turned_away or walked["deepest"] < float(body_at) * Tuning.TILE_SIZE,
			"and it turns off the street or comes to rest short of the body")
	t.check(oncoming_started - oncoming.position.y > float(CityMap.period()) * Tuning.TILE_SIZE,
			"while the oncoming lane keeps flowing past it (%.0fpx covered)"
			% (oncoming_started - oncoming.position.y))
	map.clear_day_obstructions()

# ------------------------------------------------------------ a precinct ---
# A precinct is one footway six lanes wide. A body in one of its lanes is stepped round, and
# whatever leaves a walker no way past is a wall it turns round in front of, as on any other street,
# instead of slowing to a stop with the walkers behind it queueing. *(PLAYTEST-143 statement 5, and
# velvet-marten #696: "people still pile up in the pedestrian zone instead of turning around at
# barriers".)* Six walkers, one per lane, start four tiles short of the first row of bodies and walk
# at it for twenty seconds; `_walk_at_a_precinct_wall` counts three things: walker-frames standing
# inside a body's tile (none, ever), walkers that have turned round or off the street by the end,
# and walker-frames spent between 1.5 tiles short of the first row and the last row of bodies, which
# a queue fills for the whole run and a walker that turns spends a stride in.

## A body across all six lanes of one row.
func _test_a_precinct_blocked_across_its_width_turns_walkers_round(t, crowd: Crowd,
		map: CityMap) -> void:
	var got := _walk_at_a_precinct_wall(t, crowd, map, [[0, 1, 2, 3, 4, 5]], "across its width")
	if got.is_empty():
		return
	var walker: CrowdAgent = got["probe_walker"]
	var wall: int = got["wall"]
	var vertical: bool = got["vertical"]
	var base: int = got["base"]
	var gap := Vector2i(base + 2, wall + 2) if vertical else Vector2i(wall + 2, base + 2)
	t.check(not walker.strategy.cannot_go_on(vertical, gap), "while the ground behind it is open")

## The shape seed 67 day 3 stands in its east-west precinct and seed 24757 day 5 repeats, with the
## seal's lanes stood in by bodies here: three neighbouring rows, none of them full, that no lane runs
## through. Row 0 takes lanes 0, 1, 4 and 5 (a soft seal on a real day), then a construction band over
## lanes 1 to 3, then café tables over lanes 4 and 5. A walker in lane 2 or 3 passes row 0 and meets
## the band; lanes 0, 4 and 5 beyond are open but are not reached from it. With the wall decided one
## row at a time the walkers stood at row 0, since no row was full and the sidestep had no better
## lane to go to.
func _test_partial_bodies_in_neighbouring_rows_wall_a_precinct(t, crowd: Crowd,
		map: CityMap) -> void:
	_walk_at_a_precinct_wall(t, crowd, map,
			[[0, 1, 4, 5], [1, 2, 3], [4, 5]], "of staggered partial rows")

## Walls a precinct with `rows` (the lanes taken in the rows `wall`, `wall + 1`, ...), walks six
## walkers at it and checks that they turn round. Returns the site and a walker, or an empty
## dictionary when this city has no precinct with the room to do it in.
func _walk_at_a_precinct_wall(t, crowd: Crowd, map: CityMap, rows: Array,
		label: String) -> Dictionary:
	var span := Vector4i(-1, -1, -1, -1)
	for candidate in map.precinct_spans:
		span = candidate
		break
	t.check(span.x >= 0, "this city has a precinct to wall off")
	if span.x < 0:
		return {}
	var vertical := span.x == 1
	var corridor := span.y
	var base := corridor * CityMap.period()
	# A wall mid-block, with five tiles of plain street (no junction band) short of it to walk.
	var wall := -1
	for along in range(span.z * CityMap.period() + 12, (span.w + 1) * CityMap.period()):
		var clear := true
		for i in range(1, 6):
			var tile := Vector2i(base + 2, along - i) if vertical else Vector2i(along - i, base + 2)
			if CityMap.corridor_offset(along - i) >= 0 or not map.is_street(tile):
				clear = false
				break
		if clear:
			wall = along
			break
	t.check(wall > 0, "the precinct has five tiles of plain street to walk at a wall")
	if wall < 0:
		return {}
	var lanes: Array[int] = CrowdLanes.PRECINCT_OFFSETS
	var taken: Array[Vector2i] = []
	for i in rows.size():
		for lane: int in rows[i]:
			taken.append(Vector2i(base + lane, wall + i) if vertical \
					else Vector2i(wall + i, base + lane))
	map.obstruct_tiles(1, taken)
	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()

	var walkers: Array[CrowdAgent] = []
	for lane in lanes:
		walkers.append(place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, lane,
				float(wall - 4) * Tuning.TILE_SIZE, 1.0, vertical, lanes))
	var last_lane: int = rows[rows.size() - 1][0]
	var probe := Vector2i(base + last_lane, wall + rows.size() - 1) if vertical \
			else Vector2i(wall + rows.size() - 1, base + last_lane)
	t.check(walkers[0].strategy.cannot_go_on(vertical, probe),
			"a body %s is a wall to a walker on a precinct" % label)

	var edge := Vector2i(base + rows[0][0], wall) if vertical else Vector2i(wall, base + rows[0][0])
	t.check(walkers[0].strategy.cannot_go_on(vertical, edge),
			"and so is the first body's own edge lane, asked from the walker at the start")
	var at := map.tile_to_world(probe)
	var first_px := float(wall) * Tuning.TILE_SIZE - 1.5 * Tuning.TILE_SIZE
	var last_px := float(wall + rows.size()) * Tuning.TILE_SIZE
	var standing := 0
	var inside := 0
	var turned := 0
	for frame in int(round(20.0 / STEP)):
		crowd.set_focus(at)
		crowd.step(STEP)
		for walker in walkers:
			if walker.travelling_vertically() == vertical:
				var along := walker.position.y if vertical else walker.position.x
				if along > first_px and along < last_px:
					standing += 1
			if map.is_obstructed(map.world_to_tile(walker.position)):
				inside += 1
	for walker in walkers:
		if walker.travelling_vertically() != vertical \
				or walker.heading().dot(Vector2.DOWN if vertical else Vector2.RIGHT) < 0.0:
			turned += 1
	t.check(inside == 0, "nobody walks into a body %s (%d frames somebody did)" % [label, inside])
	t.check(turned == walkers.size(),
			"every walker has turned round or off the street (%d of %d)" % [turned, walkers.size()])
	# Six walkers over 1200 frames is 7200 walker-frames; a stride is a few dozen of them each.
	t.check(standing < 6 * 150,
			"and they do not stand at it (%d walker-frames in front of it)" % standing)
	map.clear_day_obstructions()
	return {"probe_walker": walkers[0], "wall": wall, "vertical": vertical, "base": base}

# --------------------------------------------------------- a body in pieces ---
# `EventSpawner.obstructed_footprint()` rasterises `EventDef.parts()` rather than the row's one
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
	var run := a_straight_run(map, Tuning.BLOCK_SIZE)
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
		# Where the row's body stands once sited at `at`: the instance the spawner makes puts a
		# stationary, unpinned body on the middle of its pavement band when it is set up.
		var sited := EventInstance.new()
		sited.setup(def, at, PackedVector2Array(), Vector2.RIGHT, map)
		var placed := sited.position
		sited.free()
		var axis := EventFootprints.body_axis(map, def, placed, Vector2.RIGHT)
		var before := def.shape.tiles_under(placed, axis)
		var after := EventSpawner.obstructed_footprint(map, def, at, Vector2.RIGHT)
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
## every hard seal's segment in `CityMap.held`, and the record skips a body on held ground
## because the whole street is shut to the crowd already. So this asks the rasterising — the half
## M118 changed — on ground where the answer is not thrown away.
func _test_a_crash_records_its_cars_and_not_the_pavements_beside_them(t, map: CityMap) -> void:
	var run := a_straight_run(map, Tuning.BLOCK_SIZE)
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
	var axis := EventFootprints.body_axis(map, def, at, Vector2.RIGHT)
	var whole_band := def.shape.tiles_under(at, axis)
	var cars := EventSpawner.obstructed_footprint(map, def, at, Vector2.RIGHT)
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

## A walker walks past a car accident on the pavement beside it. *(2026-09-19: "they should still
## walk through a car accident since the sidewalk is free there".)* The crash's two cars stand on
## the two carriageway lanes and nothing else, so the road is shut to a car and both footways are
## open — which is the same pair of sentences `_test_a_crash_records_its_cars_and_not_the_pavements_
## beside_them` above asks of the record, asked here of what the crowd does with it.
##
## **The street is deliberately not held here.** On a real day a crash is a hard seal and its
## segment is held as well, which is what turns a car a junction early rather than at the cars
## themselves; what this test is about is the half a walker reads, and the hold has nothing to say
## to a walker.
func _test_a_walker_passes_a_crash_on_its_pavement(t, crowd: Crowd, map: CityMap) -> void:
	var run := a_straight_run(map, Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a straight stretch to stand a crash in")
	if run.x < 0:
		return
	var corridor := run.x
	var base := corridor * CityMap.period()
	var body_at := run.y + 5
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("car_accident"), true)
	var covered := _stand_a_row(map, def,
			Vector2(float(base) * Tuning.TILE_SIZE + float(Tuning.STREET_WIDTH) * 16.0,
			(float(body_at) + 0.5) * Tuning.TILE_SIZE))
	var offsets := _offsets_of(covered, base)
	t.check(offsets.size() == CrowdLanes.ROAD_OFFSETS.size()
			and offsets.has(CrowdLanes.ROAD_OFFSETS[0])
			and offsets.has(CrowdLanes.ROAD_OFFSETS[1]),
			"a crash's two cars stand on the carriageway and nowhere else (offsets %s)" % [offsets])

	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()
	var walker := place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)
	for offset: int in CrowdLanes.SIDEWALK_OFFSETS:
		t.check(not walker.strategy.cannot_go_on(true, Vector2i(base + offset, body_at)),
				"the pavement beside it stays open to a walker at offset %d" % offset)
	var driver := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor,
			CrowdLanes.road_lane(true, 1.0), float(run.y) * Tuning.TILE_SIZE, 1.0)
	for offset: int in CrowdLanes.ROAD_OFFSETS:
		t.check(driver.strategy.cannot_go_on(true, Vector2i(base + offset, body_at)),
				"and the carriageway under it is shut to a car at offset %d" % offset)
	crowd.clear()
	walker = place_on(crowd, map, CrowdAgent.Kind.WALKER, corridor, 0,
			float(run.y) * Tuning.TILE_SIZE + 4.0, 1.0)

	var at := map.tile_to_world(Vector2i(base + 1, body_at))
	var walked := _walk(crowd, map, walker, at, 6.0)
	t.check(walked["inside"] == 0,
			"nobody stands inside one of the cars (%d frames somebody did)" % walked["inside"])
	t.check(walked["deepest"] > float(body_at + 1) * Tuning.TILE_SIZE,
			"and the walker gets past the crash on its own pavement (reached %.0f, the cars end "
			% walked["deepest"] + "%.0f)" % (float(body_at + 1) * Tuning.TILE_SIZE))
	map.clear_day_obstructions()

# ------------------------------------------------- what a body takes of a street ---
# "cars shouldn't avoid it. I noticed cars turning around even though the obstacle is on the
# sidewalk. only things like a fallen tree (which blocks the whole street) should prevent cars from
# entering" (playtest 78, 2026-09-19). A body stands on the tiles whose **middle** it covers, so
# these two are the two ends of that one rule: a van at the kerb, which overhangs the carriageway
# and takes none of it, and a tree across the street, which takes all of it.

## Stands a real row's own body on the street through the same `EventSpawner.obstructed_footprint()`
## a day fills the record with, and gives back the tiles it took. Sited by hand rather than by
## planning a day, so the placement under test is this one and not whatever the seed rolled.
func _stand_a_row(map: CityMap, def: EventDef, at: Vector2) -> Array[Vector2i]:
	var covered := EventSpawner.obstructed_footprint(map, def, at, Vector2.RIGHT)
	map.obstruct_tiles(2, covered)
	return covered

## The offsets across a vertical corridor a footprint covers, as a sorted list — what "which lanes
## of the street does this body take" reads as in a failure message.
func _offsets_of(covered: Array[Vector2i], base: int) -> Array:
	var offsets := []
	for tile: Vector2i in covered:
		var offset := tile.x - base
		if offset >= 0 and offset < Tuning.STREET_WIDTH and not offsets.has(offset):
			offsets.append(offset)
	offsets.sort()
	return offsets

## A van parked at the kerb takes its own lane of pavement and no carriageway at all, so both lanes
## keep driving and a car goes past it.
##
## The van is `GroundShape.band(22.0)` and the kerb lane centre is 16px from the kerb, so its body
## genuinely overhangs the road by six pixels — the tile the overhang lands in is the whole
## question, and the record answers it by asking whether the middle of that tile is covered.
func _test_a_row_at_the_kerb_leaves_both_lanes_driving(t, crowd: Crowd, map: CityMap) -> void:
	var run := a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	t.check(run.x >= 0, "this city has a long enough stretch to park a van on")
	if run.x < 0:
		return
	var corridor := run.x
	var base := corridor * CityMap.period()
	var body_at := run.y + CityMap.period() + 2
	var def := EventCatalogue.by_id("delivery_van")
	t.check(def != null and def.pavement_side == EventDef.Pavement.AT_THE_KERB,
			"'delivery_van' is the kerb-pinned row this test is about")
	var kerb_lane: int = CrowdLanes.SIDEWALK_OFFSETS[1]
	var covered := _stand_a_row(map, def, Vector2(CrowdLanes.lane_centre(corridor, kerb_lane),
			(float(body_at) + 0.5) * Tuning.TILE_SIZE))
	var offsets := _offsets_of(covered, base)
	t.check(offsets == [kerb_lane],
			"a van at the kerb stands on its own lane of pavement and nothing else (offsets %s)"
			% [offsets])

	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()
	var lane: int = CrowdLanes.road_lane(true, 1.0)
	var driver := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, lane,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	t.check(not driver.strategy.cannot_go_on(true, Vector2i(base + lane, body_at)),
			"and the carriageway beside it is not shut to a car")
	var at := map.tile_to_world(Vector2i(base + lane, body_at))
	var walked := _walk(crowd, map, driver, at, 5.0)
	t.check(walked["deepest"] > float(body_at + 1) * Tuning.TILE_SIZE,
			"so the car drives straight past it (reached %.0f, the van's tile ends %.0f)"
			% [walked["deepest"], float(body_at + 1) * Tuning.TILE_SIZE])
	t.check(still_driving_down(driver, corridor),
			"without turning off the street it was on")
	map.clear_day_obstructions()

## A fallen tree lies across the whole street — both pavements and both lanes — so a car still turns
## away from it at the last junction. The turn-at-the-junction is a car's only answer: it cannot
## turn round against a barrier, and a car stopped nose to one holds the junction behind it.
func _test_a_row_across_the_whole_street_still_turns_a_car(t, crowd: Crowd, map: CityMap) -> void:
	var run := a_straight_run(map, CityMap.period() + Tuning.BLOCK_SIZE)
	if run.x < 0:
		return
	var corridor := run.x
	var base := corridor * CityMap.period()
	var body_at := run.y + CityMap.period() + 2
	var def := SealPlanner.sealed_variant(EventCatalogue.by_id("fallen_tree"), true)
	# The middle of the street, which is where `SealPlanner._hard_positions` stands the one copy a
	# 96px reach takes to span a 6-tile street.
	var covered := _stand_a_row(map, def,
			Vector2(float(base) * Tuning.TILE_SIZE + float(Tuning.STREET_WIDTH) * 16.0,
			(float(body_at) + 0.5) * Tuning.TILE_SIZE))
	var offsets := _offsets_of(covered, base)
	t.check(offsets.size() == Tuning.STREET_WIDTH,
			"a fallen tree takes every lane of the street, kerb to kerb (offsets %s)" % [offsets])

	crowd.start_day(1, _rng(1), Vector2.ZERO)
	crowd.clear()
	var lane: int = CrowdLanes.road_lane(true, 1.0)
	var driver := place_on(crowd, map, CrowdAgent.Kind.CAR, corridor, lane,
			float(run.y) * Tuning.TILE_SIZE, 1.0)
	t.check(driver.strategy.cannot_go_on(true, Vector2i(base + lane, body_at)),
			"and it is a wall to a car on the lane under it")
	var at := map.tile_to_world(Vector2i(base + lane, body_at))
	var walked := _walk(crowd, map, driver, at, 10.0)
	t.check(walked["inside"] == 0,
			"no car ever stands on the tree's own tile (%d frames one did)" % walked["inside"])
	# Turned off this street, or still on it and stopped short — the same two answers a body in a
	# lane already has, and which one a seed's geometry produces is not worth pinning.
	var turned_away := not still_driving_down(driver, corridor)
	t.check(turned_away or walked["deepest"] < float(body_at) * Tuning.TILE_SIZE,
			"and it turns off the street or comes to rest short of the tree")
	map.clear_day_obstructions()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-bodies:%d:%d" % [SEED, day])
	return rng
