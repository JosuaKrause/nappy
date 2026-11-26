extends RefCounted
## A rig that walks past the roadblocks on one of the escape's streets and answers what the walk
## did to the meter and whether a guard caught her. Shared by `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`), which pins
## that a lured-off roadblock is passable and a posted one is not, and
## `tests/probes/escape_roadblock_cost.gd`, which prints the table.
##
## **What is real and what is stood in for.** The plan is the finale's own (its walk,
## `FinalePlanner.route()`, and what stands on it, `DayPlanner.plan_the_escape_city()`), and the
## roadblocks on a street are `EventInstance`s built on the real map from its placements, stepped by hand at 60Hz the way `EventManager` steps them: told where
## she is and whether she runs (`_tell_them_where_she_is()`), asked whether one catches her
## (`is_lethal_at()`), and the meter fed from the strongest of them — they are
## one-barrier flag, so only the strongest counts (`excitement_sources_at()`) — the way
## `Baby._update_excitement()` feeds it, with `Baby.SLEEPING_SENSITIVITY` while asleep and the
## wake at `Tuning.EXCITEMENT_WAKE_THRESHOLD`. Her body is a point moved along her line; the decay
## is the street's (`Tuning.EXCITEMENT_DECAY_WALKING`, `_RUNNING` and `_IDLE` at a multiplier of
## 1). **The roadblocks alone**: nothing else of the plan is live, so the figures are theirs.
##
## **Her line** is the middle of the open sidewalk: the widest run of offsets across the street
## her body fits on at every roadblock's own place along it, past the bands' solid pieces
## (`WalkGround.solids_of()`), from `BEYOND` before the first band to `BEYOND`
## past the last.

const STEP := 1.0 / 60.0
const BEYOND := 260.0
const LANE_SCAN := 4.0
## How long a charge that has begun is followed past the end of her line, in seconds.
const TAIL := 10.0

## The finale's plan for a seed, built the way `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`) builds it: the map, the walk
## (`plan`) and what stands on it (`placements`).
static func plan_for(seed_value: int) -> Dictionary:
	var map := CityGenerator.generate(seed_value)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 1)
	map.repaint(state)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var walk := FinalePlanner.route(map)
	return {"map": map, "plan": walk,
			"placements": DayPlanner.plan_the_escape_city(map, walk, rng, _city_spec(),
				GamePlanBuilder.over(map))}

## The roadblocks among `placements` on each open street of the walk `plan` that carries any,
## `[segment, Array[EventPlan]]` pairs.
static func roadblock_streets(map: CityMap, plan: FinalePlanner.Plan,
		placements: Array[EventPlan]) -> Array:
	var found: Array = []
	for segment in plan.open_streets:
		var rect := map.tile_rect_to_world(segment.tile_rect())
		var group: Array[EventPlan] = []
		for placement in placements:
			if placement.row_id() == "roadblock" and rect.grow(1.0).has_point(placement.placed_at()):
				group.append(placement)
		if not group.is_empty():
			found.append([segment, group])
	return found

## The two ends of her line along the street, or empty when no offset across the street fits at
## every band.
static func her_line(t: Node, map: CityMap, segment: StreetNetwork.Segment,
		group: Array[EventPlan]) -> PackedVector2Array:
	var ground := WalkGround.new(map)
	var along := Vector2.RIGHT if segment.horizontal else Vector2.DOWN
	var across := Vector2(-along.y, along.x)
	var rect := map.tile_rect_to_world(segment.tile_rect())
	var centre := rect.get_center()
	var solids: Array[WalkGround.Solid] = []
	var stage := Stage.new(t, map)
	var places: Array[float] = []
	for placement in group:
		solids.append_array(ground.solids_of(placement))
		places.append((stage.stand(placement).body_position() - centre).dot(along))
	stage.close()
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
	return PackedVector2Array([_as_far_as_ground_goes(map, centre + along * places[0] + across * lane,
			-along), _as_far_as_ground_goes(map, centre + along * places[places.size() - 1]
			+ across * lane, along)])

## The point `BEYOND` from `from` along `way`, or the last one before the ground stops her body.
static func _as_far_as_ground_goes(map: CityMap, from: Vector2, way: Vector2) -> Vector2:
	var at := from
	var gone := 0.0
	while gone < BEYOND and _she_fits(map, at + way * LANE_SCAN):
		at += way * LANE_SCAN
		gone += LANE_SCAN
	return at

## Where she is after trying to walk to `wanted`: there, or where she was when the ground does not
## take her body there (a building, the edge of the map), as it stops her in play, so a walk that
## runs on past a street's end meets the wall at the end of the street and does not carry on
## through it where no guard can follow.
static func _on_ground(map: CityMap, was: Vector2, wanted: Vector2) -> Vector2:
	return wanted if _she_fits(map, wanted) else was

## **Which way she turns where the ground ahead stops her**: of the two ways square to `heading`,
## the one her body fits along further (up to `BEYOND`), so at a street's end she turns the corner
## into the cross street rather than standing at the wall; `Vector2.ZERO` where neither takes a
## step.
static func _the_way_round(map: CityMap, at: Vector2, heading: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var best_gone := 0.0
	for side: Vector2 in [Vector2(-heading.y, heading.x), Vector2(heading.y, -heading.x)]:
		var gone := _open_along(map, at, side, BEYOND)
		if gone > best_gone:
			best = side
			best_gone = gone
	return best

static func _she_fits(map: CityMap, at: Vector2) -> bool:
	var reach := Tuning.PLAYER_BODY_RADIUS - 1.0
	for offset: Vector2 in [Vector2.ZERO, Vector2(reach, 0), Vector2(-reach, 0),
			Vector2(0, reach), Vector2(0, -reach)]:
		var tile := map.world_to_tile(at + offset)
		if not map.in_bounds(tile) or not map.is_walkable(tile) or map.is_closed(tile):
			return false
	return true

## A world of its own for events to stand in, and a manager over it: the world
## node a city or a building is to its map (`WorldContext`, which the map is handed as its own), a
## run of its own and an `EventManager` over them, its physics off so nothing steps but the caller.
## The Stage's own `EventStreaming` and `EventSpawner` over that manager's world put each plan in
## (`EventStreaming.add()`, then `stream_in()`, as the manager's `stream_around()` does when she
## comes near it), so the spawner makes the instance the way a day's is made, and `event_of()` is
## the Stage's to answer, never the manager's. An instance stands on the map, in the world's entity
## layer, with its look's nodes to attach on the next idle frame (`settle()`). `close()` frees the
## world, gives back the bodies the plans recorded on the map and leaves the map as the stage found
## it, every plan stood out of the world.
class Stage extends RefCounted:
	var world: WorldContext
	var manager: EventManager
	## The plans' own streaming and the spawner it makes instances through, over the manager's
	## world: the manager never ticks, so nothing else streams them.
	var _spawner: EventSpawner
	var _streaming: EventStreaming
	var _map: WorldMap
	## Each plan stood.
	var _stood: Array[EventPlan] = []
	var _successors: Array[EventInstance] = []

	## Under `t`, or in no tree when `t` is null, for a rig that only reads where an event
	## stands once it is made. `atlas` is the page set the manager hands every event it makes, for a
	## case that lets real frames draw them, and `drawer` the drawer it hands them to paint through,
	## for a case that reads what they were drawn with.
	func _init(t: Node, map: WorldMap, atlas: AtlasLibrary = null,
			drawer: EventDrawer = null) -> void:
		_map = map
		world = WorldContext.new()
		if t != null:
			t.add_child(world)
		var run := RunState.new()
		var surroundings := EventSurroundings.new().on(map).drawn_in(world)
		if atlas != null:
			surroundings.drawn_from(atlas)
		if drawer != null:
			surroundings.drawing_through(drawer)
		manager = EventManager.new(surroundings)
		manager.setup(run)
		world.add_child(manager)
		manager.set_physics_process(false)
		_spawner = EventSpawner.new(manager.world, WarningBoard.new(manager.world))
		_streaming = EventStreaming.new(manager.world, _spawner, WalkEvents.new())

	## Puts `plan` in the world as the day's streaming does, and answers the instance, its
	## own process off (a case that lets frames draw it turns it on).
	func stand(plan: EventPlan) -> EventInstance:
		_stood.append(plan)
		_streaming.add(plan)
		_streaming.stream_in(plan)
		var instance := event_of(plan)
		instance.set_process(false)
		return instance

	## The live instance of `plan`, null when it is out of the world.
	func event_of(plan: EventPlan) -> EventInstance:
		return _streaming.event_of(plan)

	## Streams `plan` out of the world and in again, answering the instance streamed back in. A
	## stage holds no player, so nothing is watching the plan go.
	func stream_out_and_in(plan: EventPlan) -> EventInstance:
		_streaming.stream_out(plan)
		_streaming.stream_in(plan)
		return event_of(plan)

	## What `instance` leaves behind when it finishes, made where it stands as the spawner makes it
	## (`EventSpawner.successor_of()`), or null for a row that leaves nothing.
	func successor_of(instance: EventInstance) -> EventInstance:
		var made := _spawner.successor_of(instance)
		if made != null:
			_successors.append(made)
		return made

	## Frees the world and what is in it.
	func close() -> void:
		for made in _successors:
			_map.release_obstruction(made.get_instance_id())
		_stood.reverse()
		for stood: EventPlan in _stood:
			_map.release_obstruction(stood.get_instance_id())
			var instance := event_of(stood)
			if instance != null and is_instance_valid(instance):
				_map.release_obstruction(instance.get_instance_id())
			stood.leave_the_world(stood.saved())
		world.free()

## Lets the idle frames pass that a made event's drawing nodes wait for (`EventLook.build_nodes()`
## defers their attaching), so a band stands in the world beside its guard. The tree's `process_frame`
## signal comes before the frame's deferred calls, so the first one passed is the frame that was
## already starting and the second is the one that attached what the caller left.
static func settle(t: Node) -> void:
	await t.get_tree().process_frame
	await t.get_tree().process_frame

## The street's roadblocks, live: `[stage, Array[EventInstance]]`. `Stage.close()` frees them and
## their bands. Each is handed `atlas` (the pages the spawner hands every event it makes) when a
## case lets real frames draw them.
static func build(t: Node, map: WorldMap, group: Array[EventPlan],
		atlas: AtlasLibrary = null) -> Array:
	var stage := Stage.new(t, map, atlas)
	var made: Array[EventInstance] = []
	for placement in group:
		made.append(stage.stand(placement))
	return [stage, made]

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
			strongest = maxf(strongest, instance.source().contribution_at(her))
		var incoming := strongest + (Baby.EXCITEMENT_FROM_RUNNING if running else 0.0)
		incoming *= Baby.SLEEPING_SENSITIVITY if asleep else 1.0
		var decay := Baby.EXCITEMENT_DECAY_IDLE if idle else (
				Baby.EXCITEMENT_DECAY_RUNNING if running else Tuning.EXCITEMENT_DECAY_WALKING)
		value = clampf(value + (incoming - decay) * STEP, 0.0, Tuning.METER_MAX)
		peak = maxf(peak, value)
		if asleep and value >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
			asleep = false

## The camera's view round her once it has settled on her walking `heading`: `Tuning.VIEW_HALF_EXTENT`
## either way of her, led by `Stroller.CAMERA_LOOK_AHEAD` the way `Stroller` leads it (its
## `OBLIQUE_Y` squash on the vertical): the camera's view of what `EventManager` hands a waiting
## charger as `WhereSheIs.view()`; the view round her alone for no heading.
static func view_round(her: Vector2, heading: Vector2) -> Rect2:
	var lead := Vector2(heading.x, heading.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	return Rect2(her + lead - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)

## One frame of the world round her: `where` (the one the instances were handed) told where
## she is, every instance stepped, then asked whether it catches her. True on a catch. With a
## `heading` (the way she faces), what she sees is told too: the camera's view round her
## (`view_round()`), in the tap scheme, which covers none of it.
static func tick(where: WhereSheIs, instances: Array[EventInstance], her: Vector2,
		running: bool, heading := Vector2.ZERO) -> bool:
	var seen: VisibleView = null
	if heading != Vector2.ZERO:
		seen = VisibleView.new()
		seen.look(view_round(her, heading), null)
	where.tell(her, Vector2.INF, seen, running, false)
	for instance in instances:
		instance.step(STEP)
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
## second at her on the way), `at`, where she stopped, and `turned`, how many corners she turned.
## A charge begun when her line ends is followed on (`TAIL`).
##
## **Once a charge is under way she turns the first corner she comes to**, round the building she
## was walking beside (`_its_corner_is_open()`: the corner at her street's end, or an alley mouth),
## as a walker with a guard behind her would, so the building stands between them; and where the
## ground ahead stops her she turns along it (`_the_way_round()`). Before he charges she keeps to
## her line, so his warning is met as on a straight walk.
##
## Also `chase_frames`, `chase_usec` and `chase_worst_usec`: how many frames a charge was under way,
## and the wall-clock microseconds those frames' ticks took in all and at most, what a probe prints
## as the chase's cost.
static func walk(t: Node, map: CityMap, group: Array[EventPlan], from: Vector2,
		to: Vector2, meter: Meter, built: Array = []) -> Dictionary:
	var made: Array = built if not built.is_empty() else build(t, map, group)
	var instances: Array[EventInstance] = made[1]
	var stage: Stage = made[0]
	var where := stage.manager.world.where_she_is()
	var start := meter.value
	# The peak is this walk's own, not what an earlier lure ran the meter up to.
	meter.peak = meter.value
	var her := from
	var heading := (to - from).normalized()
	var beside := _the_building_side(map, from, heading)
	var length := from.distance_to(to)
	var walked := 0.0
	var caught := false
	var charged := {}
	var strongest := 0.0
	var turned := 0
	var timing := {"chase_frames": 0, "chase_usec": 0, "chase_worst_usec": 0}
	while walked < length:
		if turned == 0:
			her = _on_ground(map, her, from + heading * walked)
		else:
			her = _on_ground(map, her, _ahead(map, her, heading))
		if _timed_tick(where, instances, her, heading, timing):
			caught = true
			break
		for instance in instances:
			if instance.is_chasing():
				charged[instance] = true
			strongest = maxf(strongest, instance.source().contribution_at(her))
		meter.feed(instances, her, false, false)
		walked += Tuning.WALK_SPEED * STEP
		if turned == 0 and _charging(instances) > 0 and _its_corner_is_open(map, her, beside):
			heading = beside
			turned += 1
	# A charge that has begun is not over where her line ends: she walks on at the same pace until
	# every charge has caught her or given up (`TAIL`), as she would past the end of a street, round
	# the first corner and along the ground where it stops her.
	var tail := 0
	while not caught and _charging(instances) > 0 and tail < int(TAIL / STEP):
		if turned == 0 and _its_corner_is_open(map, her, beside):
			heading = beside
			turned += 1
		var next := her + heading * Tuning.WALK_SPEED * STEP
		if not _she_fits(map, next):
			var way_round := _the_way_round(map, her, heading)
			if way_round != Vector2.ZERO:
				heading = way_round
				turned += 1
				next = her + heading * Tuning.WALK_SPEED * STEP
		her = _on_ground(map, her, next)
		if _timed_tick(where, instances, her, heading, timing):
			caught = true
			break
		meter.feed(instances, her, false, false)
		tail += 1
	stage.close()
	return {"cost": meter.peak - start, "peak": meter.peak, "end": meter.value, "caught": caught,
			"charged": charged.size(), "strongest": strongest, "at": her, "turned": turned,
			"chase_frames": timing["chase_frames"], "chase_usec": timing["chase_usec"],
			"chase_worst_usec": timing["chase_worst_usec"]}

## A step on from `her` along `heading`, or along the ground where it stops her there
## (`_the_way_round()`): her walk after she has turned off her line.
static func _ahead(map: CityMap, her: Vector2, heading: Vector2) -> Vector2:
	var next := her + heading * Tuning.WALK_SPEED * STEP
	if _she_fits(map, next):
		return next
	var way_round := _the_way_round(map, her, heading)
	return her + way_round * Tuning.WALK_SPEED * STEP

## How deep, in px, the ground beside her has to open for her to turn into it: three tiles, past
## the frontage she was walking beside, so a doorway's notch is no corner and a cross street or an
## alley mouth is.
const CORNER_DEPTH := 3.0 * Tuning.TILE_SIZE

## **The side of her line the buildings stand on**: of the two ways square to `heading` at `at`,
## the one the ground stops her body sooner along, or `Vector2.ZERO` where both run open past
## `CORNER_DEPTH` (no frontage beside her to turn round).
static func _the_building_side(map: CityMap, at: Vector2, heading: Vector2) -> Vector2:
	var nearest := Vector2.ZERO
	var nearest_gone := INF
	for side: Vector2 in [Vector2(-heading.y, heading.x), Vector2(heading.y, -heading.x)]:
		var gone := _open_along(map, at, side, CORNER_DEPTH)
		if gone < CORNER_DEPTH and gone < nearest_gone:
			nearest = side
			nearest_gone = gone
	return nearest

## Whether the ground on `beside` (`_the_building_side()`) opens at `at` at least `CORNER_DEPTH`
## deep: the building she was walking beside has ended, at a corner or an alley's mouth.
static func _its_corner_is_open(map: CityMap, at: Vector2, beside: Vector2) -> bool:
	return beside != Vector2.ZERO and _open_along(map, at, beside, CORNER_DEPTH) >= CORNER_DEPTH

## How far, in px and up to `limit`, her body fits along `way` from `at`, in `LANE_SCAN` steps.
static func _open_along(map: CityMap, at: Vector2, way: Vector2, limit: float) -> float:
	var gone := 0.0
	while gone < limit and _she_fits(map, at + way * (gone + LANE_SCAN)):
		gone += LANE_SCAN
	return gone

## `tick()` at a walk along `heading`, its wall-clock time added to `timing` (`walk()`'s
## `chase_frames`, `chase_usec`, `chase_worst_usec`) when a charge was under way as it began.
static func _timed_tick(where: WhereSheIs, instances: Array[EventInstance], her: Vector2,
		heading: Vector2, timing: Dictionary) -> bool:
	var chasing := _charging(instances) > 0
	var began := Time.get_ticks_usec()
	var caught := tick(where, instances, her, false, heading)
	if chasing:
		var took := Time.get_ticks_usec() - began
		timing["chase_frames"] = int(timing["chase_frames"]) + 1
		timing["chase_usec"] = int(timing["chase_usec"]) + took
		timing["chase_worst_usec"] = maxi(int(timing["chase_worst_usec"]), took)
	return caught

## Her reaction to a charge, in seconds, in `lure()`.
const REACTION := 0.3

## The lure, as baiting is played under the one-radius rule (inbox #788 in minty-lemur): in from `from` at a walk
## until a guard's hand goes up, then standing where she is, her speed changing at
## `Tuning.ACCELERATION` as hers does, until he charges; `REACTION` later turned and run straight
## back, until every charge has given up; then standing until each guard who charged has left his
## post for good (at most 30s); then `walk()` from there to `to`. Answers `{"lure": …, "after": …}`, each in
## `walk()`'s shape, the lure's with `nearest` as well, the closest any charging guard came to her
## in px; `after` is empty when the lure itself was caught.
static func lure(t: Node, map: CityMap, group: Array[EventPlan], from: Vector2,
		to: Vector2, meter: Meter) -> Dictionary:
	var made := build(t, map, group)
	var instances: Array[EventInstance] = made[1]
	var stage: Stage = made[0]
	var where := stage.manager.world.where_she_is()
	var start := meter.value
	var heading := (to - from).normalized()
	var her := from
	var caught := false
	var lured := {}
	var frames := 0
	# Positive is on along `heading`, toward the band.
	var speed := Tuning.WALK_SPEED
	var warned := false
	while _charging(instances) == 0 and her.distance_to(from) < from.distance_to(to) \
			and frames < int(20.0 / STEP):
		if tick(where, instances, her, false, heading):
			caught = true
			break
		meter.feed(instances, her, false, speed == 0.0)
		for instance in instances:
			warned = warned or (not instance.is_waiting() and not instance.has_lost_its_guard())
		speed = move_toward(speed, 0.0 if warned else Tuning.WALK_SPEED, Tuning.ACCELERATION * STEP)
		her += heading * speed * STEP
		if warned:
			frames += 1
	frames = 0
	var since := 0.0
	var nearest := INF
	while not caught and _charging(instances) > 0 and frames < int(20.0 / STEP):
		for instance in instances:
			if instance.is_chasing():
				lured[instance] = true
				nearest = minf(nearest, instance.global_position.distance_to(her))
		var wanted := 0.0 if since < REACTION else -Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		her += heading * speed * STEP
		var running := speed < -Tuning.WALK_SPEED
		if tick(where, instances, her, running, heading if speed >= 0.0 else -heading):
			caught = true
			break
		meter.feed(instances, her, running, false)
		since += STEP
		frames += 1
	frames = 0
	while not caught and frames < int(30.0 / STEP):
		var gone := true
		for instance: EventInstance in lured:
			gone = gone and instance.has_lost_its_guard() and not instance.is_on_its_way_out()
		if gone:
			break
		if tick(where, instances, her, false, -heading):
			caught = true
			break
		meter.feed(instances, her, false, true)
		frames += 1
	var luring := {"cost": meter.peak - start, "peak": meter.peak, "end": meter.value,
			"caught": caught, "charged": lured.size(), "strongest": 0.0, "at": her,
			"nearest": nearest}
	if caught:
		stage.close()
		return {"lure": luring, "after": {}}
	return {"lure": luring, "after": walk(t, map, group, her, to, meter, made)}

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
