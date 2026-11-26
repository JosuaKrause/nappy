extends RefCounted
## Measurement probe for minty-quail (the ground a deadly event shuts is one stated fact): **what a
## hunting roadblock (the roadblock row at heat 4, where its guard hunts) shuts of a day's ground,
## and what that does to where she can get to and where she touches the task's roadblock from**.
## Not a suite: it prints rather than asserting, and runs only by name:
##
##     tools/test.sh probes/minty_quail_blocking_reach.gd
##
## Each day from 7 to 14 is planned as `downy_llama_route_roadblocks.gd` plans it, at heat 4. It
## asks only what main and the branch both have (`EventPlan.blocking_radius()`, `DayReach`,
## `RuledRoadblockGround.close_by()`, `Corridor.carries_a_route()`), so one file measures both.
## Prints, per day summed over the seeds, `MQ day hunting shut cut`: the hunting roadblocks, the
## tiles their discs shut and the route tiles home no longer reaches over the day's shut ground; and
## on day 13 `MQT seed tile touched close_by`, per hunting roadblock of the first seeds the ground she touches it from
## (walkable, left open, within the disc and a tile and a half) and the ground close by it.
## Writes two crops of the first hunting roadblock of days 7 to 12 and of day 13 under
## `docs/evidence/minty-quail-blocking-reach-2026-11-23/`, named by the `MQ_LABEL` environment variable
## (`main` or `branch`; `run` without it). A tile is dark for a building, light grey for a sidewalk,
## mid grey for a road, green for a park; red is the ground the plan's `blocking_radius()` shuts,
## orange the ring `core_within()` would have shut and `blocking_radius()` does not, a blue dot a
## route tile, a green dot the ground she touches it from, a black cross the body.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const HEAT := 4
## The seeds whose day 13 roadblocks are measured for the ground close by (a flood each).
const TOUCH_SEEDS := 2
const CROP_RADIUS := 10
const CROP_SCALE := 12
const OUT_DIR := "res://docs/evidence/minty-quail-blocking-reach-2026-11-23"

var _saved_a := false
var _saved_b := false

func run(t: TestRunner) -> void:
	var cut_all := 0
	for day in range(7, 15):
		cut_all += _one_day(day)
	print("MQ all cut %d" % cut_all)
	t.check(true, "blocking reach probe ran")

func _one_day(day: int) -> int:
	var hunting := 0
	var shut_tiles := 0
	var cut := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE + i * STEP)
		# The run's mast sites, worked out once on the city as built, as the game does.
		var sites := MastSites.compute(EventCatalogue.shipped(), map)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day, null)
		var spec := DaySpec.for_day(day)
		# The day's own closures, holds, region wall and seals, planned as the game plans them
		# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
		# stand as the day's standing and hold their locations.
		var region_plan := RegionPlanner.plan_day(EventCatalogue.shipped(), map, spec, tree)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
		var closures := ClosurePlanner.plan_day(EventCatalogue.shipped(), map, spec, closure_rng, tree, region_plan)
		map.close_streets(closures)
		map.clear_day_holds()
		for closure: RoadClosure in closures:
			map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
		for segment: StreetNetwork.Segment in region_plan.wall_segments():
			map.hold_segment(segment.key(), HeldStreets.Why.WALL)
		for segment: StreetNetwork.Segment in region_plan.door_segments():
			map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
		for segment: StreetNetwork.Segment in map.street_network().around_blocks(
				Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			map.hold_segment(segment.key(), HeldStreets.Why.HOME)
		var boundary := {}
		for segment in region_plan.wall_segments():
			boundary[segment.key()] = true
		for segment in region_plan.door_segments():
			boundary[segment.key()] = true
		for rect in region_plan.walled_alleys():
			boundary[rect.position] = true
		for rect in region_plan.door_alleys():
			boundary[rect.position] = true
		var seal_rng := RandomNumberGenerator.new()
		seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
		var seals := SealPlanner.plan_day(EventCatalogue.shipped(), map, spec, tree, seal_rng, boundary, map.held_streets())
		for seal in seals:
			seal.stand_as_a_seal()
		var doors := PackedVector2Array()
		for body in region_plan.door_plans():
			doors.append(body.placed_at())
		var standing: Array[EventPlan] = []
		standing.append_array(seals)
		standing.append_array(region_plan.wall_plans())
		for body in region_plan.wall_plans():
			body.stand_in_the_wall()
		var corridor := Corridor.of(tree)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
		var guarded := ResistanceSteps.guarded_row_on(day)
		var consumed: Array[String] = []
		var guarded_row: EventDef = null
		if guarded != "":
			guarded_row = EventCatalogue.shipped().heated(EventCatalogue.shipped().by_id(guarded), HEAT)
		var placements := GameDawn.of(spec, rng, map).masts(sites).spent(consumed).on(tree) \
				.heat(HEAT).doors(doors).standing(standing) \
				.roadblock(guarded_row).plan().placements()
		var everything: Array[EventPlan] = []
		everything.append_array(standing)
		everything.append_array(placements)
		var reach := DayReach.of(map, everything)
		var shut := DayReach.shut_by(map, everything)
		for tile: Vector2i in corridor_tiles(map, corridor):
			if map.is_walkable(tile) and not shut.has(tile) and not reach.reaches(tile):
				cut += 1
		for plan in placements:
			if plan.row_id() != "roadblock" or not plan.is_placed() or not plan.row().ends_the_day():
				continue
			hunting += 1
			var own := EventScheduler.blocked_by(map, [plan] as Array[EventPlan])
			shut_tiles += own.size()
			var touched := _touched_from(map, shut, plan)
			if day == 13 and i < TOUCH_SEEDS:
				var close := RuledRoadblockGround.close_by(map, shut, plan)
				print("MQT %d %s %d %d" % [i, RunTrace.tile(map.world_to_tile(plan.body_at())),
						touched.size(), close.size()])
			if day == 13 and not _saved_b:
				_saved_b = true
				_crop(map, corridor, plan, touched, "day13")
			elif day < 13 and not _saved_a:
				_saved_a = true
				_crop(map, corridor, plan, touched, "shut")
	print("MQ %d %d %d %d" % [day, hunting, shut_tiles, cut])
	return cut

## The route tiles of the whole map.
static func corridor_tiles(map: CityMap, corridor: Corridor) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var size := map.size_in_tiles()
	for y in size.y:
		for x in size.x:
			var tile := Vector2i(x, y)
			if corridor.carries_a_route(tile):
				found.append(tile)
	return found

## The walkable ground left open within the plan's disc and a tile and a half of its body, as the
## director and the roadblock phase work it out (`blocking_radius() + 1.5 tiles`).
static func _touched_from(map: CityMap, shut: Dictionary, plan: EventPlan) -> Array[Vector2i]:
	var reach := plan.blocking_radius() + Tuning.TILE_SIZE * 1.5
	var centre := map.world_to_tile(plan.body_at())
	var span := ceili(reach / Tuning.TILE_SIZE)
	var found: Array[Vector2i] = []
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.in_bounds(tile) and map.is_walkable(tile) and not shut.has(tile) \
					and map.tile_to_world(tile).distance_to(plan.body_at()) <= reach:
				found.append(tile)
	return found

func _crop(map: CityMap, corridor: Corridor, plan: EventPlan, touched: Array[Vector2i],
		name: String) -> void:
	var label := OS.get_environment("MQ_LABEL")
	if label == "":
		label = "run"
	var dir := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	var centre := map.world_to_tile(plan.body_at())
	var side := CROP_RADIUS * 2 + 1
	var image := Image.create(side * CROP_SCALE, side * CROP_SCALE, false, Image.FORMAT_RGBA8)
	var shut_now := EventScheduler.blocked_by(map, [plan] as Array[EventPlan])
	var core_only := {}
	var core_disc := {}
	EventScheduler.block_a_disc(map, core_disc, plan.body_at(), plan.row().core_within())
	for tile: Vector2i in core_disc:
		if not shut_now.has(tile):
			core_only[tile] = true
	for dy in side:
		for dx in side:
			var tile := centre + Vector2i(dx - CROP_RADIUS, dy - CROP_RADIUS)
			var colour := Color(0.05, 0.05, 0.05)
			if map.in_bounds(tile):
				colour = _ground_colour(map.tile_at(tile))
				if shut_now.has(tile):
					colour = colour.lerp(Color(0.9, 0.1, 0.1), 0.6)
				elif core_only.has(tile):
					colour = colour.lerp(Color(1.0, 0.6, 0.1), 0.6)
			image.fill_rect(Rect2i(dx * CROP_SCALE, dy * CROP_SCALE, CROP_SCALE, CROP_SCALE), colour)
			if map.in_bounds(tile) and corridor.carries_a_route(tile):
				image.fill_rect(Rect2i(dx * CROP_SCALE + 2, dy * CROP_SCALE + 2, 4, 4),
						Color(0.1, 0.3, 1.0))
			if touched.has(tile):
				image.fill_rect(Rect2i(dx * CROP_SCALE + 7, dy * CROP_SCALE + 7, 4, 4),
						Color(0.1, 0.8, 0.2))
	var body := (plan.body_at() - Vector2(centre) * float(Tuning.TILE_SIZE)) \
			/ float(Tuning.TILE_SIZE) * float(CROP_SCALE) \
			+ Vector2(CROP_RADIUS, CROP_RADIUS) * float(CROP_SCALE)
	for k in range(-4, 5):
		image.set_pixel(clampi(roundi(body.x) + k, 0, image.get_width() - 1), clampi(roundi(body.y), 0,
				image.get_height() - 1), Color.BLACK)
		image.set_pixel(clampi(roundi(body.x), 0, image.get_width() - 1), clampi(roundi(body.y) + k, 0,
				image.get_height() - 1), Color.BLACK)
	var path := "%s/%s_%s.png" % [dir, name, label]
	image.save_png(path)
	print("MQ crop %s radius %.0f core %.0f at %s" % [path, plan.blocking_radius(),
			plan.row().core_within(), RunTrace.tile(centre)])

static func _ground_colour(kind: GameEnums.TileType) -> Color:
	match kind:
		GameEnums.TileType.BUILDING:
			return Color(0.25, 0.25, 0.28)
		GameEnums.TileType.SIDEWALK:
			return Color(0.85, 0.85, 0.85)
		GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING:
			return Color(0.55, 0.55, 0.58)
		GameEnums.TileType.PARK, GameEnums.TileType.FOREST:
			return Color(0.45, 0.7, 0.4)
		_:
			return Color(0.75, 0.72, 0.6)
