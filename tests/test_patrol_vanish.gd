extends RefCounted
## A police car is never removed while she could be watching it.
##
## The player's words *(2026-10-07, azure-koala, finding 5, inbox #601: "police cars can disappear
## outright")*. Every way the manager takes a patrol car out of the world is walked here on a real
## city, a frame at a time through the manager's own steps, and each car that goes is asked whether
## it went inside her view (`VisibleView`, the one answer to "can she see it").

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0
## The patrol's body, with a margin: a box about it the view must clear of it for it not to be seen.
const CAR_BOX := Vector2(48.0, 48.0)

func run(t) -> void:
	_test_a_car_that_runs_out_of_route_leaves_out_of_her_sight(t)
	_test_an_investigating_car_leaves_out_of_her_sight(t)
	_test_an_investigating_car_whose_man_is_shaken_off_leaves_out_of_her_sight(t)
	_test_a_car_she_follows_out_of_its_street_is_not_streamed_out(t)
	_test_a_leaving_car_streamed_out_does_not_come_back(t)

func _rig(t, day: int) -> Array:
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(map)
	city.events.world.day = day
	city.events._recipe_plan = true
	# The lights are off, so a red one cannot hold a car where the probe wants it to run.
	city.events.world.signals = null
	var her := _Her.new()
	t.add_child(her)
	her.set_process(false)
	her.set_physics_process(false)
	return [city, her]

## Her, standing where the test puts her and seeing from there, carrying the baby so no pram stands
## out in front of her, and running while `running` says so: the manager's tick reads all three off
## her (`VisibleView.look_through()`, `EventManager._tell_them_where_she_is()`) and tells the events
## before it steps them.
class _Her extends Stroller:
	var running := false

	func _init() -> void:
		carrying = true
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)

	func camera_screen_center() -> Vector2:
		return global_position

	func run_excess_ratio() -> float:
		return 1.0 if running else 0.0

func _done(city: City, her: Node2D) -> void:
	her.free()
	city.free()

## A stretch of carriageway between two junction boxes on an east-west street, at least `tiles` long,
## off the home block, with a sidewalk on its north side: `[west end, east end, sidewalk point
## opposite the middle]`, all in world px, or empty. No zebra and no signal stands on it.
func _a_lane(map: CityMap, tiles := 8) -> Array:
	for y in range(2, map.size.y - 2):
		var x := 12
		while x < map.size.x - 12:
			var start := x
			while x < map.size.x - 12 and map.tile_at(Vector2i(x, y)) == GameEnums.TileType.ROAD \
					and CityMap.junction_at(Vector2i(x, y)) == Vector2i(-1, -1) \
					and map.tile_at(Vector2i(x, y - 1)) == GameEnums.TileType.SIDEWALK:
				x += 1
			if x - start >= tiles and not map.is_on_home_block(Vector2i(start, y - 1)):
				var middle := Vector2i((start + x) / 2, y - 1)
				return [map.tile_to_world(Vector2i(start, y)), map.tile_to_world(Vector2i(x - 1, y)),
						map.tile_to_world(middle)]
			x += 1
	return []

## Whether a car at `at` is anywhere in the view she has from `her`: the whole of its body and a
## margin about it, the view the camera shows with no look-ahead on top (`VisibleView.around(, null)`).
func _seen(at: Vector2, her: Vector2) -> bool:
	return VisibleView.around(her, null).sees_any(Rect2(at - CAR_BOX * 0.5, CAR_BOX))

## A real city on day `day` with a planned car of `def` on a stretch of carriageway and her at the
## sidewalk beside its middle, returned as `[city, her, plan, route]`.
func _lane_rig(t, def: EventDef) -> Array:
	var rig := _rig(t, 8)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var spot := _a_lane(city.map)
	t.check(spot.size() == 3, "found a stretch of carriageway between two junction boxes")
	var route := PackedVector2Array([spot[0], spot[1]])
	her.global_position = spot[2]
	var plan := EventScheduler.Planned.new(def, route[0], route)
	city.events.streaming._plans.append(plan)
	city.events.use_player(her)
	return [city, her, plan, route]

## One physics tick as the game runs it: the manager's own, which steps every instance, with her
## running while `running` says so.
func _frame(city: City, running := false) -> void:
	(city.events.world.player as _Her).running = running
	city.events._tick_the_events(STEP)

## Whether `car` is out of the world: finished, or handed to `queue_free()` by a retirement or a
## stream-out.
func _removed(car: EventInstance) -> bool:
	return car.is_finished or car.is_queued_for_deletion()

# ------------------------------------------------------------ the departures ---

## The ordinary patrol: it drives its route to the end and leaves the way it was going, with her
## beside the street. It is removed only once it is out of her view.
func _test_a_car_that_runs_out_of_route_leaves_out_of_her_sight(t) -> void:
	var rig := _lane_rig(t, EventCatalogue.by_id("police_patrol"))
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var plan: EventScheduler.Planned = rig[2]
	var car: EventInstance = null
	var seen_at_the_end := false
	var elapsed := 0.0
	while elapsed < 60.0:
		_frame(city)
		elapsed += STEP
		car = car if car != null else plan.live
		if car != null and _removed(car):
			seen_at_the_end = _seen(car.global_position, her.global_position)
			break
	t.check(car != null and _removed(car), "the patrol drove its route and left the world")
	t.check(not seen_at_the_end, "and was removed out of her view, never inside it")
	_done(city, her)

## The investigating car: it stops, lets its man out, takes him back in and drives on; every
## removal of it is out of her view.
func _test_an_investigating_car_leaves_out_of_her_sight(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var rig := _lane_rig(t, hot)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var plan: EventScheduler.Planned = rig[2]
	var car: EventInstance = null
	var officer: EventInstance = null
	var seen_at_the_end := false
	var elapsed := 0.0
	while elapsed < 90.0:
		_frame(city)
		elapsed += STEP
		car = car if car != null else plan.live
		if car != null and officer == null:
			officer = car.its_officer()
		if car != null and _removed(car):
			seen_at_the_end = _seen(car.global_position, her.global_position)
			break
	t.check(officer != null, "the heated patrol stopped for her and let a man out")
	t.check(car != null and _removed(car), "and the car, its man back in, drove on and left the world")
	t.check(not seen_at_the_end, "out of her view, never inside it")
	_done(city, her)

## The same car, its man shaken off instead: she runs, he gives up the chase and walks back to the
## car, which drives on once he is in. Every removal of the car is out of her view.
func _test_an_investigating_car_whose_man_is_shaken_off_leaves_out_of_her_sight(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), Tuning.RESISTANCE_GOAL)
	var rig := _lane_rig(t, hot)
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var plan: EventScheduler.Planned = rig[2]
	var car: EventInstance = null
	var officer: EventInstance = null
	var seen_at_the_end := false
	var elapsed := 0.0
	while elapsed < 120.0:
		_frame(city, officer != null and not officer.is_finished)
		elapsed += STEP
		car = car if car != null else plan.live
		if car != null and officer == null:
			officer = car.its_officer()
		if car != null and _removed(car):
			seen_at_the_end = _seen(car.global_position, her.global_position)
			break
	t.check(officer != null, "the heated patrol stopped for her and let a man out")
	t.check(officer != null and officer.gave_up, "she ran and he gave up the chase")
	t.check(car != null and _removed(car), "and the car, its man back in, drove on and left the world")
	t.check(not seen_at_the_end, "out of her view, never inside it")
	_done(city, her)

## **The vanishing the player reported.** A plan is streamed out by how far she is from its *route*
## (`Planned.distance_from()`), and a car that has run out of route carries on past its end, so a car
## she follows out of its street is far from the route while she is a few paces behind it. At 1160px
## from the route (the streaming radius and its hysteresis) it was deleted in front of her. She
## follows it 120px behind for far longer than that, and it must still be in the world; stopping,
## she lets it go, and it is removed only out of her view.
func _test_a_car_she_follows_out_of_its_street_is_not_streamed_out(t) -> void:
	var rig := _lane_rig(t, EventCatalogue.by_id("police_patrol"))
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var plan: EventScheduler.Planned = rig[2]
	var route: PackedVector2Array = rig[3]
	var reach := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	var car: EventInstance = null
	var elapsed := 0.0
	var removed_in_view := false
	var followed := 0.0
	while elapsed < 60.0:
		_frame(city)
		elapsed += STEP
		car = car if car != null else plan.live
		if car == null:
			continue
		if followed < reach + 300.0:
			if car.is_leaving:
				her.global_position.x = car.global_position.x - 120.0
				followed = her.global_position.x - route[1].x
		if _removed(car):
			removed_in_view = _seen(car.global_position, her.global_position)
			break
	t.check(followed >= reach + 300.0, "she followed it %.0fpx past its route's end, 120px behind"
			% followed)
	t.check(car != null and not removed_in_view,
			"and it was never removed while she could see it (removed %s at %.0fpx from her)"
			% [car != null and _removed(car), car.global_position.distance_to(her.global_position)
			if car != null else -1.0])
	t.check(car != null and _removed(car), "she stood, and it drove out of her view and was removed")
	_done(city, her)


## A car that is leaving and is streamed out beyond her sight is over, and its plan says so
## (`Planned.spent`): a departure that has ended is not run again. She is *teleported* away and back
## here, which is not how she moves; walking, the plan streams in only 900px from its route's end, and
## the car is rebuilt out of her view and finishes at once. So this holds the bookkeeping, and the
## second half walks her back and holds that nothing is ever inside her view.
func _test_a_leaving_car_streamed_out_does_not_come_back(t) -> void:
	var rig := _lane_rig(t, EventCatalogue.by_id("police_patrol"))
	var city: City = rig[0]
	var her: Node2D = rig[1]
	var plan: EventScheduler.Planned = rig[2]
	var home := her.global_position
	var elapsed := 0.0
	while elapsed < 30.0 and (plan.live == null or not plan.live.is_leaving):
		_frame(city)
		elapsed += STEP
	t.check(plan.live != null and plan.live.is_leaving, "the patrol ran out of route and is leaving")
	her.global_position = home + Vector2(0.0, 2400.0) # a teleport, see above
	_frame(city)
	t.check(plan.live == null, "she is far away and it is streamed out")
	t.check(plan.spent, "and its plan is spent, a departure being over once it is streamed out")
	var seen := false
	while her.global_position.y > home.y:
		her.global_position.y = maxf(her.global_position.y - Tuning.WALK_SPEED * STEP, home.y)
		_frame(city)
		for instance in city.events.instances():
			seen = seen or _seen(instance.global_position, her.global_position)
	for i in 30:
		_frame(city)
	t.check(plan.live == null and not seen,
			"walking back to its route, nothing of it is ever in her view")
	_done(city, her)
