extends RefCounted
## **Nothing that arrives from off screen is ever drawn on the frame it exists.** *(Amendment 6 of
## M226, the player: "objects don't spawn \"at the edge of the screen\" they spawn *offscreen*" · "I
## don't want any pop in".)* Every place a thing arriving from off screen is created at —
## `PendingWarning.down_her_line()` (the cyclist, the loose dog), `along_her_heading()` (the day-3
## dog), `on_its_route()` (the fire engine), `in_its_lane()` (day 13's column) and
## `just_out_of_sight()` (the resistance's robber and guard) — puts the thing wholly outside the
## camera's whole view.
##
## **What is checked is what the instance draws, not what it was placed by.** Each place makes a real
## instance the way the game creates it there (`EventManager.spawn_warned()`, `_send_down_her_line()`,
## the trap's), told where she is, and asks it what it draws on that frame
## (`EventInstance.drawn_rect_now()`: its pictures, its shadow, and its danger caret from the
## caret's own drawing numbers and its own projection of her). A footprint (`footprint_of()`) that
## leaves anything out fails here. Asked over every bearing, cameras led every way her look-ahead can
## lead them, both input schemes (a corner the joystick's controls cover is not off screen for this),
## real cities as well as open ground, the column's lane at the main road's ends, and through a
## portrait window turned the way the game turns it.

const SEEDS: Array[int] = [4242, 90210, 1234567, 31337]
const BEARINGS := 48

func run(t) -> void:
	_test_open_ground_over_every_bearing_and_camera(t)
	_test_her_own_sidewalk_on_real_cities(t)
	_test_the_road_and_the_lane(t)
	_test_the_lane_at_the_ends_of_the_road(t)
	_test_a_turned_window_shows_nothing_either(t)

## The rows placed by a bearing from her.
static func _rows() -> Array[EventDef]:
	var rows: Array[EventDef] = [EventCatalogue.by_id("cyclist"), EventCatalogue.by_id("loose_dog"),
			EventManager.as_warned(EventCatalogue.by_id("charging_dog")),
			EventCatalogue.by_id("robber_giving_chase"), EventCatalogue.by_id("van_guard_giving_chase")]
	return rows

## The cameras she can be seen through, standing at `her`: on her, and led by her look-ahead
## (`Stroller.CAMERA_LOOK_AHEAD`, foreshortened by `Stroller.OBLIQUE_Y` vertically) in each of eight
## directions; each in both schemes.
static func _views(her: Vector2) -> Array[VisibleView]:
	var views: Array[VisibleView] = []
	var leads: Array[Vector2] = [Vector2.ZERO]
	for i in 8:
		var way := Vector2.RIGHT.rotated(TAU * i / 8.0)
		leads.append(Vector2(way.x, way.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD)
	for lead in leads:
		for joystick: bool in [false, true]:
			views.append(VisibleView.around(her + lead, joystick))
	return views

## A real instance of `row` created at `at` the way the game creates one arriving from off screen,
## heading for her at `her` along `path` (or straight at her), and told where she is. Freed by the
## caller.
static func _arrival(row: EventDef, at: Vector2, her: Vector2,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	if path.is_empty() and row.mobile and not row.pursues:
		path = PackedVector2Array([at, her + (her - at)])
	instance.setup(row, at, path)
	instance.came_under_a_warning = true
	if not row.pursues or row.arrives_chasing:
		instance.resume(EventManager.age_when_warned(row), 0.0)
	instance.player_at = her
	instance.player_running = false
	return instance

## Whether anything `instance` draws on this frame overlaps the camera's whole `view` (corners
## included).
static func _drawn_in(view: VisibleView, instance: EventInstance) -> bool:
	var rect := instance.drawn_rect_now()
	return Rect2(instance.global_position + rect.position, rect.size).intersects(view.view)

func _test_open_ground_over_every_bearing_and_camera(t) -> void:
	var her := Vector2(1000.0, 1000.0)
	var placed := 0
	var marked := 0
	var popped: Array[String] = []
	for row in _rows():
		for view in _views(her):
			for i in BEARINGS:
				var way := Vector2.RIGHT.rotated(TAU * i / BEARINGS)
				var places: Array[Vector2] = [PendingWarning.just_out_of_sight(
						PendingWarning.seen_from(view, her), row, her, way)]
				if row.comes_down_her_line():
					places.append(PendingWarning.down_her_line(null, row, her, way, view))
				if row.pursues:
					places.append(PendingWarning.along_her_heading(null, row, her, way, view))
				for at in places:
					var instance := _arrival(row, at, her)
					placed += 1
					if instance.wants_a_mark():
						marked += 1
					if _drawn_in(view, instance) and popped.size() < 3:
						popped.append("'%s' along %v, camera at %v%s" % [row.id, way,
								view.view.get_center() - her, " (joystick)" if view.joystick else ""])
					instance.free()
	t.check(placed > 0 and popped.is_empty(),
			"on open ground, nothing any of %d arrivals draws (%d with a caret) is in view on its "
			% [placed, marked] + "first frame%s" % ("" if popped.is_empty() else ": " + "; ".join(popped)))
	t.check(marked > 0, "and some of them are marked, so the caret was measured (%d)" % marked)

## Her own sidewalk on several real cities: the cyclist and the loose dog sent down her line from
## points along the arterial, every way along it, through every camera — moved sideways or further
## onto their ground, never back into the view.
func _test_her_own_sidewalk_on_real_cities(t) -> void:
	var placed := 0
	var popped: Array[String] = []
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var start := CrowdLanes.arterial_pavement(map)
		for row: EventDef in [EventCatalogue.by_id("cyclist"), EventCatalogue.by_id("loose_dog")]:
			for k in 12:
				var her := start + Vector2(0.0, float(k) * Tuning.TILE_SIZE * 7.0)
				if not map.in_bounds(map.world_to_tile(her)):
					continue
				for way: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
						Vector2(1.0, -1.0).normalized()]:
					for view in _views(her):
						var at := PendingWarning.down_her_line(map, row, her, way, view)
						if at == Vector2.INF:
							continue
						var instance := _arrival(row, at, her,
								PendingWarning.route_down_her_line(map, at, her, way))
						placed += 1
						if _drawn_in(view, instance) and popped.size() < 3:
							popped.append("seed %d, '%s' at %v along %v" % [seed_value, row.id, at, way])
						instance.free()
	t.check(placed > 100 and popped.is_empty(),
			"on real cities, nothing any of %d sidewalk arrivals draws is in view on its first frame%s"
			% [placed, "" if popped.is_empty() else ": " + "; ".join(popped)])

## The fire engine on its road, from every point up its street she may stand at, and day 13's column
## in its lane, through every camera.
func _test_the_road_and_the_lane(t) -> void:
	var truck := EventCatalogue.by_id("fire_truck")
	var column := EventManager.as_warned(EventCatalogue.by_id("military_convoy"))
	var kerb := Vector2(2000.0, 4000.0)
	var placed := 0
	var popped: Array[String] = []
	for up in range(0, 400, 16):
		var her := kerb - Vector2.DOWN * float(up) + Vector2(48.0, 0.0)
		for view in _views(her):
			var at := PendingWarning.on_its_route(truck, her, kerb, Vector2.DOWN, 4000.0, view)
			if at != Vector2.INF:
				var engine := _arrival(truck, at, her, PackedVector2Array([at, kerb]))
				placed += 1
				if _drawn_in(view, engine) and popped.size() < 3:
					popped.append("engine at %v with her at %v" % [at, her])
				engine.free()
			for going: float in [1.0, -1.0]:
				var lane := PendingWarning.in_its_lane(column, her, her.x - 40.0, going, -1.0e6, 1.0e6,
						view)
				var truck_in_lane := _arrival(column, lane, her,
						PackedVector2Array([lane, lane + Vector2(0.0, going * 4000.0)]))
				placed += 1
				if _drawn_in(view, truck_in_lane) and popped.size() < 3:
					popped.append("column at %v with her at %v" % [lane, her])
				truck_in_lane.free()
	t.check(placed > 0 and popped.is_empty(),
			"on the road and in the lane, nothing any of %d arrivals draws is in view on its first "
			% placed + "frame%s" % ("" if popped.is_empty() else ": " + "; ".join(popped)))

## **The column at the main road's ends**: the lane is held on the map (`top` to `bottom`), and
## where holding it would bring the front truck into view she is too near the road's end for it to
## come from there, so `in_its_lane()` has no place (the warning is withdrawn) rather than a place in
## view. With her a view's height or less from either end, every answer is off screen or none.
func _test_the_lane_at_the_ends_of_the_road(t) -> void:
	var column := EventManager.as_warned(EventCatalogue.by_id("military_convoy"))
	var top := 16.0
	var bottom := 4000.0
	var none := 0
	var placed := 0
	var popped: Array[String] = []
	for gap in range(0, 400, 20):
		for case: Array in [[top + float(gap), 1.0], [bottom - float(gap), -1.0]]:
			var her := Vector2(500.0, float(case[0]))
			var going: float = case[1]
			for view in _views(her):
				var lane := PendingWarning.in_its_lane(column, her, 460.0, going, top, bottom, view)
				if lane == Vector2.INF:
					none += 1
					continue
				var front := _arrival(column, lane, her)
				placed += 1
				if _drawn_in(view, front) and popped.size() < 3:
					popped.append("column at %v with her at %v" % [lane, her])
				front.free()
	t.check(none > 0 and popped.is_empty(),
			"near the road's ends, %d columns placed off screen and %d with no place, none in view%s"
			% [placed, none, "" if popped.is_empty() else ": " + "; ".join(popped)])

## The same places through a portrait window presenting the game turned, the way the game turns it:
## the camera turned by `ScreenOrientation.apply_to_camera()` (what `main._apply_orientation()`
## calls), about the middle of the box `ScreenOrientation.content_scale_size()` presents, mapped back
## into the 1280x720 design box with `ScreenOrientation.to_design_space()`; nothing an arrival draws
## lands in that box.
func _test_a_turned_window_shows_nothing_either(t) -> void:
	var her := Vector2(1000.0, 1000.0)
	var zoom := ScreenOrientation.DESIGN_SIZE / (Tuning.VIEW_HALF_EXTENT * 2.0)
	var design := Rect2(Vector2.ZERO, ScreenOrientation.DESIGN_SIZE)
	var camera := Camera2D.new()
	ScreenOrientation.apply_to_camera(camera, true)
	var presented := Vector2(ScreenOrientation.content_scale_size(true))
	var placed := 0
	var popped := 0
	for row in _rows():
		for view in _views(her):
			var turned := Transform2D(-camera.rotation, zoom, 0.0, presented * 0.5) \
					* Transform2D(0.0, -view.view.get_center())
			for i in BEARINGS:
				var way := Vector2.RIGHT.rotated(TAU * i / BEARINGS)
				var at := PendingWarning.just_out_of_sight(PendingWarning.seen_from(view, her), row,
						her, way)
				var instance := _arrival(row, at, her)
				var rect := instance.drawn_rect_now()
				instance.free()
				var drawn := Rect2(at + rect.position, rect.size)
				var corners: Array[Vector2] = []
				for c: Vector2 in [drawn.position, drawn.end, Vector2(drawn.position.x, drawn.end.y),
						Vector2(drawn.end.x, drawn.position.y)]:
					corners.append(ScreenOrientation.to_design_space(turned * c, true))
				var on_screen := Rect2(corners[0], Vector2.ZERO)
				for c in corners:
					on_screen = on_screen.expand(c)
				placed += 1
				if on_screen.intersects(design):
					popped += 1
	camera.free()
	t.check(placed > 0 and popped == 0,
			"turned the way the game turns, nothing any of %d arrivals draws lands in the design box "
			% placed + "(%d do)" % popped)
