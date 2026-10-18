extends RefCounted
## A rig that walks past the roadblocks on one of the escape's streets and answers what the walk
## did to the meter and whether a guard caught her. Shared by `tests/test_finale.gd`, which pins
## that a lured-off roadblock is passable and a posted one is not, and
## `tests/probes/escape_roadblock_cost.gd`, which prints the table.
##
## **What is real and what is stood in for.** The plan is the finale's own
## (`FinalePlanner.plan()`), and the roadblocks on a street are `EventInstance`s built on the real
## map from its placements, stepped by hand at 60Hz the way `EventManager` steps them: told where
## she is and whether she runs (`_tell_them_where_she_is()`), asked whether one catches her
## (`is_lethal_at()`), and the meter fed from the strongest of them — they are
## `barrier_structure`, so only the strongest counts (`excitement_sources_at()`) — the way
## `Baby._update_excitement()` feeds it, with `Tuning.SLEEPING_SENSITIVITY` while asleep and the
## wake at `Tuning.EXCITEMENT_WAKE_THRESHOLD`. Her body is a point moved along her line; the decay
## is the street's (`Tuning.EXCITEMENT_DECAY_WALKING`, `_RUNNING` and `_IDLE` at a multiplier of
## 1). **The roadblocks alone**: nothing else of the plan is live, so the figures are theirs.
##
## **Her line** is the middle of the open sidewalk: the widest run of offsets across the street
## her body fits on at every roadblock's own place along it, past the bands' solid pieces
## (`EventScheduler.EscapeGround.solids_of()`), from `BEYOND` before the first band to `BEYOND`
## past the last.

const STEP := 1.0 / 60.0
const BEYOND := 260.0
const LANE_SCAN := 4.0

## The finale's plan for a seed, built the way `tests/test_finale.gd` builds it.
static func plan_for(seed_value: int) -> Dictionary:
	var map := CityGenerator.generate(seed_value)
	GameState.city_state.begin_day(map.block_plans, 1)
	map.repaint(GameState.city_state)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"map": map, "plan": FinalePlanner.plan(map, rng)}

## The plan's roadblocks on each open street that carries any, `[segment, Array[Planned]]` pairs.
static func roadblock_streets(map: CityMap, plan: FinalePlanner.Plan) -> Array:
	var found: Array = []
	for segment in plan.open_streets:
		var rect := map.tile_rect_to_world(segment.tile_rect())
		var group: Array[EventScheduler.Planned] = []
		for placement in plan.placements:
			if placement.def.id == "roadblock" and rect.grow(1.0).has_point(placement.position):
				group.append(placement)
		if not group.is_empty():
			found.append([segment, group])
	return found

## The two ends of her line along the street, or empty when no offset across the street fits at
## every band.
static func her_line(t: Node, map: CityMap, segment: StreetNetwork.Segment,
		group: Array[EventScheduler.Planned]) -> PackedVector2Array:
	var ground := EventScheduler.EscapeGround.new(map, [], [])
	var along := Vector2.RIGHT if segment.horizontal else Vector2.DOWN
	var across := Vector2(-along.y, along.x)
	var rect := map.tile_rect_to_world(segment.tile_rect())
	var centre := rect.get_center()
	var solids: Array[EventScheduler.EscapeSolid] = []
	var holder := Node2D.new()
	t.add_child(holder)
	var places: Array[float] = []
	for placement in group:
		solids.append_array(ground.solids_of(placement))
		var instance := EventInstance.new()
		instance.setup(placement.def, placement.position, placement.path, placement.facing, map)
		holder.add_child(instance)
		places.append((instance.body_position() - centre).dot(along))
	holder.free()
	var half_width := (rect.size.y if segment.horizontal else rect.size.x) * 0.5
	var runs: Array[Vector2] = []
	var run_start := INF
	var offset := -half_width
	while offset <= half_width + 0.01:
		var fits := true
		for place in places:
			var at := centre + along * place + across * offset
			if not _she_fits(map, at):
				fits = false
				break
			for solid in solids:
				if solid.stops_her_at(at):
					fits = false
					break
			if not fits:
				break
		if fits and run_start == INF:
			run_start = offset
		elif not fits and run_start != INF:
			runs.append(Vector2(run_start, offset - LANE_SCAN))
			run_start = INF
		offset += LANE_SCAN
	if run_start != INF:
		runs.append(Vector2(run_start, half_width))
	if runs.is_empty():
		return PackedVector2Array()
	var widest := runs[0]
	for run in runs:
		if run.y - run.x > widest.y - widest.x:
			widest = run
	var lane := (widest.x + widest.y) * 0.5
	places.sort()
	return PackedVector2Array([centre + along * (places[0] - BEYOND) + across * lane,
			centre + along * (places[places.size() - 1] + BEYOND) + across * lane])

static func _she_fits(map: CityMap, at: Vector2) -> bool:
	var reach := Tuning.PLAYER_BODY_RADIUS - 1.0
	for offset: Vector2 in [Vector2.ZERO, Vector2(reach, 0), Vector2(-reach, 0),
			Vector2(0, reach), Vector2(0, -reach)]:
		var tile := map.world_to_tile(at + offset)
		if not map.in_bounds(tile) or not map.is_walkable(tile) or map.is_closed(tile):
			return false
	return true

## The street's roadblocks, live: `[holder, Array[EventInstance]]`. Freeing the holder frees them
## and their bands.
static func build(t: Node, map: CityMap, group: Array[EventScheduler.Planned]) -> Array:
	var holder := Node2D.new()
	t.add_child(holder)
	var made: Array[EventInstance] = []
	for placement in group:
		var instance := EventInstance.new()
		instance.setup(placement.def, placement.position, placement.path, placement.facing, map)
		holder.add_child(instance)
		instance.set_process(false)
		instance._attach_the_band()
		made.append(instance)
	return [holder, made]

## A meter fed the way `Baby._update_excitement()` feeds it.
class Meter extends RefCounted:
	var value := 0.0
	var peak := 0.0
	var asleep := true

	func _init(start: float, starts_asleep: bool) -> void:
		value = start
		peak = start
		asleep = starts_asleep

	func feed(instances: Array[EventInstance], her: Vector2, running: bool, idle: bool) -> void:
		var strongest := 0.0
		for instance in instances:
			strongest = maxf(strongest, instance.contribution_at(her))
		var incoming := strongest + (Tuning.EXCITEMENT_FROM_RUNNING if running else 0.0)
		incoming *= Tuning.SLEEPING_SENSITIVITY if asleep else 1.0
		var decay := Tuning.EXCITEMENT_DECAY_IDLE if idle else (
				Tuning.EXCITEMENT_DECAY_RUNNING if running else Tuning.EXCITEMENT_DECAY_WALKING)
		value = clampf(value + (incoming - decay) * STEP, 0.0, Tuning.METER_MAX)
		peak = maxf(peak, value)
		if asleep and value >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
			asleep = false

## The camera's view round her once it has settled on her walking `heading`: `Tuning.VIEW_HALF_EXTENT`
## either way of her, led by `Stroller.CAMERA_LOOK_AHEAD` the way `Stroller` leads it (its
## `OBLIQUE_Y` squash on the vertical). What `EventManager` hands a waiting charger as
## `EventInstance.player_view`; the view round her alone for no heading.
static func view_round(her: Vector2, heading: Vector2) -> Rect2:
	var lead := Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	return Rect2(her + lead - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)

## One frame of the world round her: every instance told where she is and stepped, then asked
## whether it catches her. True on a catch. With a `heading` (the way she faces), each is handed the
## camera's view round her too (`view_round()`).
static func _tick(instances: Array[EventInstance], her: Vector2, running: bool,
		heading := Vector2.ZERO) -> bool:
	for instance in instances:
		instance.player_at = her
		instance.player_view = view_round(her, heading) if heading != Vector2.ZERO else Rect2()
		instance.player_running = running
		instance.baby_awake = false
		instance._process(STEP)
	for instance in instances:
		if instance.is_lethal_at(her):
			return true
	return false

static func _charging(instances: Array[EventInstance]) -> int:
	var count := 0
	for instance in instances:
		if instance.is_chasing():
			count += 1
	return count

## At a walk from `from` to `to` past the street's roadblocks, `built` (from `build()`) or a fresh
## set, which it frees. Answers `cost` (the meter's peak less where it started), `peak`, `end`,
## `caught`, `charged` (how many guards charged her), `strongest` (the most any of them charged a
## second at her on the way) and `at`, where she stopped.
static func walk(t: Node, map: CityMap, group: Array[EventScheduler.Planned], from: Vector2,
		to: Vector2, meter: Meter, built: Array = []) -> Dictionary:
	var made: Array = built if not built.is_empty() else build(t, map, group)
	var instances: Array[EventInstance] = made[1]
	var start := meter.value
	# The peak is this walk's own, not what an earlier lure ran the meter up to.
	meter.peak = meter.value
	var her := from
	var heading := (to - from).normalized()
	var length := from.distance_to(to)
	var walked := 0.0
	var caught := false
	var charged := {}
	var strongest := 0.0
	while walked < length:
		her = from + heading * walked
		if _tick(instances, her, false, heading):
			caught = true
			break
		for instance in instances:
			if instance.is_chasing():
				charged[instance] = true
			strongest = maxf(strongest, instance.contribution_at(her))
		meter.feed(instances, her, false, false)
		walked += Tuning.WALK_SPEED * STEP
	made[0].free()
	return {"cost": meter.peak - start, "peak": meter.peak, "end": meter.value, "caught": caught,
			"charged": charged.size(), "strongest": strongest, "at": her}

## The lure, as baiting is played: in from `from` at a walk until a guard charges, on at the walk
## for `Tuning.BAIT_REACTION`, then turned and run straight back, her speed changing at
## `Tuning.ACCELERATION` as hers does, until every charge has given up; then standing until each
## guard who charged has left his post for good (at most 30s); then `walk()` from there to `to`. Answers `{"lure": …, "after": …}`, each in
## `walk()`'s shape; `after` is empty when the lure itself was caught.
static func lure(t: Node, map: CityMap, group: Array[EventScheduler.Planned], from: Vector2,
		to: Vector2, meter: Meter) -> Dictionary:
	var made := build(t, map, group)
	var instances: Array[EventInstance] = made[1]
	var start := meter.value
	var heading := (to - from).normalized()
	var her := from
	var caught := false
	var lured := {}
	var frames := 0
	while _charging(instances) == 0 and her.distance_to(from) < from.distance_to(to):
		if _tick(instances, her, false, heading):
			caught = true
			break
		meter.feed(instances, her, false, false)
		her += heading * Tuning.WALK_SPEED * STEP
	# Positive is on along `heading`, toward the band.
	var speed := Tuning.WALK_SPEED
	var since := 0.0
	while not caught and _charging(instances) > 0 and frames < int(20.0 / STEP):
		for instance in instances:
			if instance.is_chasing():
				lured[instance] = true
		var wanted := Tuning.WALK_SPEED if since < Tuning.BAIT_REACTION else -Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		her += heading * speed * STEP
		var running := speed < -Tuning.WALK_SPEED
		if _tick(instances, her, running, heading if speed >= 0.0 else -heading):
			caught = true
			break
		meter.feed(instances, her, running, false)
		since += STEP
		frames += 1
	frames = 0
	while not caught and frames < int(30.0 / STEP):
		var gone := true
		for instance: EventInstance in lured:
			gone = gone and instance.is_a_spent_guard() and not instance.is_leaving
		if gone:
			break
		if _tick(instances, her, false, -heading):
			caught = true
			break
		meter.feed(instances, her, false, true)
		frames += 1
	var luring := {"cost": meter.peak - start, "peak": meter.peak, "end": meter.value,
			"caught": caught, "charged": lured.size(), "strongest": 0.0, "at": her}
	if caught:
		made[0].free()
		return {"lure": luring, "after": {}}
	return {"lure": luring, "after": walk(t, map, group, her, to, meter, made)}
