extends RefCounted
## **Nothing that arrives from off screen is ever drawn on the frame it exists.** *(Amendment 6 of
## M226, the player: "objects don't spawn \"at the edge of the screen\" they spawn *offscreen*" · "I
## don't want any pop in".)* Every place a thing arriving from off screen is created at —
## `PendingWarning.down_her_line()` (the cyclist, the loose dog), `along_her_heading()` (the day-3
## dog), `on_its_route()` (the fire engine), `in_its_lane()` (day 13's column) and
## `just_out_of_sight()` (the resistance's robber and guard) — puts everything the row can draw
## (`EventInstance.footprint_of()`: every view of its picture, its shadow, its bob, the halo's rim)
## wholly outside the camera's whole view. Asked over every bearing, cameras led every way her
## look-ahead can lead them, both input schemes (a corner the joystick's controls cover is not
## off screen for this), real cities as well as open ground, and through a portrait window's turned
## canvas.

const SEEDS: Array[int] = [4242, 90210, 1234567, 31337]
const BEARINGS := 48

func run(t) -> void:
	_test_open_ground_over_every_bearing_and_camera(t)
	_test_her_own_sidewalk_on_real_cities(t)
	_test_the_road_and_the_lane(t)
	_test_a_turned_window_shows_nothing_either(t)

## The rows placed by a bearing from her, and how.
static func _rows() -> Array[EventDef]:
	var rows: Array[EventDef] = [EventCatalogue.by_id("cyclist"), EventCatalogue.by_id("loose_dog"),
			EventManager.as_warned(EventCatalogue.by_id("charging_dog")),
			EventCatalogue.by_id("robber_giving_chase"), EventCatalogue.by_id("van_guard_giving_chase")]
	return rows

## The cameras she can be seen through, standing at the origin: on her, and led by her look-ahead
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

## Whether `row`'s footprint at `at` overlaps the camera's whole `view` (corners included).
static func _pops_in(view: VisibleView, row: EventDef, at: Vector2) -> bool:
	var box := EventInstance.footprint_of(row)
	return Rect2(at + box.position, box.size).intersects(view.view)

func _test_open_ground_over_every_bearing_and_camera(t) -> void:
	var her := Vector2(1000.0, 1000.0)
	var placed := 0
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
					placed += 1
					if _pops_in(view, row, at) and popped.size() < 3:
						popped.append("'%s' along %v, camera at %v%s" % [row.id, way,
								view.view.get_center() - her, " (joystick)" if view.joystick else ""])
	t.check(placed > 0 and popped.is_empty(),
			"on open ground, none of %d places shows anything of its row on its first frame%s"
			% [placed, "" if popped.is_empty() else ": " + "; ".join(popped)])

## Her own sidewalk on several real cities: the cyclist and the loose dog sent down her line from
## points along the arterial and the cross streets, every way along it, through every camera — moved
## sideways or further onto their ground, never back into the view.
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
						placed += 1
						if _pops_in(view, row, at) and popped.size() < 3:
							popped.append("seed %d, '%s' at %v along %v" % [seed_value, row.id, at, way])
	t.check(placed > 100 and popped.is_empty(),
			"on real cities, none of %d sidewalk places shows anything on its first frame%s"
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
				placed += 1
				if _pops_in(view, truck, at) and popped.size() < 3:
					popped.append("engine at %v with her at %v" % [at, her])
			for going: float in [1.0, -1.0]:
				var lane := PendingWarning.in_its_lane(column, her, her.x - 40.0, going, -1.0e6, 1.0e6, view)
				placed += 1
				if _pops_in(view, column, lane) and popped.size() < 3:
					popped.append("column at %v with her at %v" % [lane, her])
	t.check(placed > 0 and popped.is_empty(),
			"on the road and in the lane, none of %d places shows anything on its first frame%s"
			% [placed, "" if popped.is_empty() else ": " + "; ".join(popped)])

## The same places through a portrait window presenting the game turned a quarter: the camera turned
## by -90° and the canvas mapped back into the 1280x720 design box (`ScreenOrientation`), and every
## corner of the footprint lands outside that box.
func _test_a_turned_window_shows_nothing_either(t) -> void:
	var her := Vector2(1000.0, 1000.0)
	var zoom := ScreenOrientation.DESIGN_SIZE / (Tuning.VIEW_HALF_EXTENT * 2.0)
	var design := Rect2(Vector2.ZERO, ScreenOrientation.DESIGN_SIZE)
	var placed := 0
	var popped := 0
	for row in _rows():
		for view in _views(her):
			var turned := Transform2D(deg_to_rad(90.0), zoom, 0.0, ScreenOrientation.ROTATED_SIZE * 0.5) \
					* Transform2D(0.0, -view.view.get_center())
			for i in BEARINGS:
				var way := Vector2.RIGHT.rotated(TAU * i / BEARINGS)
				var at := PendingWarning.just_out_of_sight(PendingWarning.seen_from(view, her), row,
						her, way)
				var box := EventInstance.footprint_of(row)
				var drawn := Rect2(at + box.position, box.size)
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
	t.check(placed > 0 and popped == 0,
			"turned a quarter, none of %d places lands in the design box (%d do)" % [placed, popped])
