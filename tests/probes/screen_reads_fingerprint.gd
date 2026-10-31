extends RefCounted
## **What the crowd and the world read of the screen, printed one line per question**, so handing
## them those reads instead of letting them reach for the viewport and the controls can be shown to
## answer exactly what reaching answered. Not a suite: it prints rather than asserts. Run by name,
## before and after a change, and compare:
##
##     tools/test.sh probes/screen_reads_fingerprint.gd > before.txt
##     grep '^SR ' before.txt > before.sr     (and the same for after; `diff` the two)
##
## - **`SR_VV`**: `VisibleView` through a player rig and the game's own `TouchControls`, in the tap
##   scheme and in the joystick scheme on each side, flat and turned the way a portrait touch window
##   turns the game: `sees()` on a grid of points (with and without a margin), `share_of()` on a
##   grid of rectangles and `clear_of_sight()` along a few ways, asked of a view looked through the
##   rig's camera and of one the world about a point chose;
## - **`SR_CV`**: the crowd's view of the screen on a few camera states (centre, zoom, flat and
##   turned, and none at all): the drawn box, and `beyond_every_view()` over a grid of points and
##   rooms.
##
## Only the two `_` helpers below name how a view is made or handed its controls, so this file is
## the one place that changes when that does; every printed value is the same on both sides.

const POINTS_STEP := 83.0
const SHARE_BOXES: Array[Vector2] = [Vector2(24.0, 24.0), Vector2(110.0, 70.0), Vector2(300.0, 200.0)]

func run(t) -> void:
	_visible_view(t)
	_crowd_view(t)

## A view looked through `rig`, with `controls` the controls it is to read the scheme from.
static func _view_through(rig: Node2D, controls: TouchControls) -> VisibleView:
	var made := VisibleView.new()
	made.look_through(rig)
	return made

## A view of the world about `centre` that a rig chose, in the scheme `joystick` says.
static func _view_about(centre: Vector2, joystick: bool, controls: TouchControls) -> VisibleView:
	return VisibleView.around(centre, joystick)

## The crowd's view of the screen, anchored in `anchor`'s viewport.
static func _crowd_view_of(anchor: Node) -> CrowdView:
	return ScreenCrowdView.new(anchor)

static func _hex(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(PackedFloat64Array([float(value)]).to_byte_array().hex_encode())
	return " ".join(parts)

static func _rect_hex(box: Rect2) -> String:
	return _hex([box.position.x, box.position.y, box.size.x, box.size.y])

func _visible_view(t) -> void:
	var rig := Stroller.new()
	rig.set_physics_process(false)
	rig.set_process(false)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rig.add_child(camera)
	t.add_child(rig)
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	var schemes := [
		["tap", ControlsMode.Mode.TAP, ControlsMode.Side.LEFT],
		["joystick-left", ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT],
		["joystick-right", ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT],
	]
	for centre: Vector2 in [Vector2(812.0, -233.0), Vector2(-40.5, 77.25)]:
		for rotated: bool in [false, true]:
			rig.global_position = centre
			ScreenOrientation.apply_to_camera(camera, rotated)
			camera.force_update_scroll()
			for scheme in schemes:
				controls.rotated = rotated
				controls.set_mode(scheme[1], scheme[2])
				var label := "%s rotated=%s at=%s" % [scheme[0], rotated, centre]
				_print_view("through " + label, _view_through(rig, controls))
				_print_view("about " + label, _view_about(centre + Vector2(13.0, 7.0),
						scheme[1] == ControlsMode.Mode.JOYSTICK, controls))
	controls.free()
	rig.free()

func _print_view(label: String, view: VisibleView) -> void:
	print("SR_VV %s | view %s | joystick %s" % [label, _rect_hex(view.view), view.joystick])
	var origin := view.view.position
	var seen: Array[String] = []
	var y := -POINTS_STEP
	while y < view.view.size.y + POINTS_STEP:
		var row := ""
		var x := -POINTS_STEP
		while x < view.view.size.x + POINTS_STEP:
			var at := origin + Vector2(x, y)
			row += ("1" if view.sees(at) else "0") + ("1" if view.sees(at, 9.0) else "0") \
					+ ("1" if view.sees(at, -9.0) else "0")
			x += POINTS_STEP * 0.5
		seen.append(row)
		y += POINTS_STEP * 0.5
	print("SR_VV %s | sees %s" % [label, ",".join(seen)])
	var shares: Array[float] = []
	for size in SHARE_BOXES:
		var sy := -size.y
		while sy < view.view.size.y + size.y:
			var sx := -size.x
			while sx < view.view.size.x + size.x:
				shares.append(view.share_of(Rect2(origin + Vector2(sx, sy), size)))
				sx += size.x * 1.5
			sy += size.y * 1.5
	print("SR_VV %s | shares %s" % [label, _hex(shares)])
	var clears: Array[float] = []
	for start in [Vector2.ZERO, Vector2(120.0, 90.0), Vector2(-200.0, 150.0), Vector2(250.0, 140.0)]:
		for step in 16:
			var way := Vector2.RIGHT.rotated(TAU * step / 16.0)
			for box in [Rect2(), Rect2(-12.0, -30.0, 24.0, 30.0), Rect2(-60.0, -20.0, 120.0, 40.0)]:
				for least in [0.0, 30.0]:
					clears.append(view.clear_of_sight(view.view.get_center() + start, way, box, least))
	print("SR_VV %s | clear %s" % [label, _hex(clears)])

func _crowd_view(t) -> void:
	var anchor := Node.new()
	t.add_child(anchor)
	var view := _crowd_view_of(anchor)
	print("SR_CV none | box %s | beyond %s" % [_rect_hex(_drawn_box(view)), _beyond(view, Vector2(100.0, 100.0))])
	var rig := Node2D.new()
	t.add_child(rig)
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	rig.add_child(camera)
	camera.make_current()
	for centre: Vector2 in [Vector2(812.0, -233.0), Vector2(-40.5, 77.25), Vector2(3.1, 4.7)]:
		for zoom: float in [2.0, 1.0, 0.8]:
			for rotated: bool in [false, true]:
				rig.global_position = centre
				camera.zoom = Vector2(zoom, zoom)
				ScreenOrientation.apply_to_camera(camera, rotated)
				camera.force_update_scroll()
				print("SR_CV at=%s zoom=%s rotated=%s | box %s | beyond %s" % [centre, zoom, rotated,
						_rect_hex(_drawn_box(view)), _beyond(view, centre)])
	rig.free()
	anchor.free()

func _drawn_box(view: CrowdView) -> Rect2:
	DrawnView.forget()
	return view.drawn_box()

func _beyond(view: CrowdView, centre: Vector2) -> String:
	var bits := ""
	for room in [0.0, 2.0 * Tuning.TILE_SIZE]:
		for dy in range(-12, 13):
			for dx in range(-12, 13):
				var at := centre + Vector2(dx, dy) * 53.7
				bits += "1" if view.beyond_every_view(at, room, centre) else "0"
	return bits
