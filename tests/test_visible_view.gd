extends RefCounted
## What she can see (`VisibleView`), the one answer every "is it visible" question in the game asks
## *(feathery-lynx, inbox #581, the player: "use that everywhere where visibility is concerned -- for
## the other mode those rectangles *do* count"; "yes, everything should follow this (and treat it
## depending on the input mode)")*: the point test, its margin, where a thing is placed just out of
## sight, and that a portrait window presenting the game rotated changes none of it. What reads it —
## the badge, the placing, the sightings, a chalk mark's notice, the crews — is tested where each is.

func run(t) -> void:
	_test_a_point_under_a_covered_corner_is_out_of_sight_only_with_the_joystick(t)
	_test_the_margin_counts_past_the_edge_and_into_a_corner(t)
	_test_just_out_of_sight_is_the_edge_of_the_view_on_each_side(t)
	_test_just_out_of_sight_may_be_a_covered_corner(t)
	_test_just_out_of_sight_is_never_nearer_than_its_floor(t)
	_test_the_view_follows_the_camera_and_the_scheme(t)
	_test_a_rotated_window_shows_the_same_world_under_the_same_corners(t)
	_test_the_badge_stays_up_for_a_thing_under_a_covered_corner(t)
	_test_selected_controls_keep_the_badge_view_and_spawn_view_distinct(t)

## Whichever side the title chose, every consumer sees the painted footprint, while spawning stays
## outside the complete camera. The ground inward of the focal discs is visible.
func _test_selected_controls_keep_the_badge_view_and_spawn_view_distinct(t) -> void:
	var paused: bool = t.get_tree().paused
	t.get_tree().paused = false
	var player := Node2D.new()
	t.add_child(player)
	player.global_position = Vector2(2000.0, 2000.0)
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	controls._rig = player
	var source := _Source.new()
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.setup(source, player)
	var row := EventCatalogue.by_id("cyclist")
	var bike := EventInstance.new()
	bike.setup(row, player.global_position)
	bike.resume(row.telegraph_time, 0.0)
	source.live.append(bike)
	for rotated: bool in [false, true]:
		controls.rotated = rotated
		for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
			controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
			var other := TouchControls.FOCUS_LEFT if side == ControlsMode.Side.RIGHT \
					else TouchControls.FOCUS_RIGHT
			t.check(controls.run_button_center() == other,
					"the title's side puts Run on the opposite focus, rotated=%s" % rotated)
			source.view.look_through(player)
			for design: Vector2 in [Vector2(350.0, 620.0), Vector2(930.0, 620.0)]:
				bike.global_position = player.global_position + (design - ScreenOrientation.DESIGN_SIZE * 0.5) * 0.5
				t.check(edge._shows(bike), "ground inward of either focal disc is visible to the badge")
			for design: Vector2 in [Vector2(160.0, 650.0), Vector2(1120.0, 650.0)]:
				bike.global_position = player.global_position + (design - ScreenOrientation.DESIGN_SIZE * 0.5) * 0.5
				t.check(not edge._shows(bike), "both covered corners remain unseen on either side")
				var way := (bike.global_position - player.global_position).normalized()
				var at := PendingWarning.just_out_of_sight(
						PendingWarning.seen_from(source.view, player.global_position),
						row, player.global_position, way)
				var box := EventInstance.footprint_of(row)
				t.check(not source.view.view.intersects(Rect2(at + box.position, box.size)),
						"the same covered bearing places the whole arrival outside the camera")
		controls.set_mode(ControlsMode.Mode.TAP)
		source.view.look_through(player)
		t.check(edge._shows(bike) and controls.run_button_center() == Vector2.INF,
				"tap mode reveals the corner and removes the Run disc")
	controls.free()
	edge.free()
	source.free()
	bike.free()
	player.free()
	t.get_tree().paused = paused

## The view's centre, and points well inside each bottom corner, at its bottom middle, and in the
## middle — the middle and the bottom middle seen in both schemes, the corners only in the tap one.
func _test_a_point_under_a_covered_corner_is_out_of_sight_only_with_the_joystick(t) -> void:
	var tap := VisibleView.around(Vector2.ZERO)
	var joystick := VisibleView.around(Vector2.ZERO, true)
	var view := tap.view
	var scale := view.size / ScreenOrientation.DESIGN_SIZE
	var in_left := view.position + VisibleView.covered_left().get_center() * scale
	var in_right := view.position + VisibleView.covered_right().get_center() * scale
	for point: Vector2 in [in_left, in_right]:
		t.check(tap.sees(point) and not joystick.sees(point),
				"%v, under a corner, is in sight in the tap scheme and not in the joystick one" % point)
	for point: Vector2 in [Vector2.ZERO, Vector2(0.0, view.end.y - 2.0)]:
		t.check(tap.sees(point) and joystick.sees(point),
				"%v, between the corners or in the middle, is in sight in both" % point)
	var outside := Vector2(view.end.x + 1.0, 0.0)
	t.check(not tap.sees(outside) and not joystick.sees(outside), "past the view is out of both")
	t.check(not VisibleView.new().sees(Vector2.ZERO),
			"and a view never looked through sees nothing")

## `margin` world px count as in sight past the view's edge and into a covered corner, the badge's
## hysteresis; with none, the edge is the edge.
func _test_the_margin_counts_past_the_edge_and_into_a_corner(t) -> void:
	var joystick := VisibleView.around(Vector2.ZERO, true)
	var past := Vector2(0.0, -Tuning.VIEW_HALF_EXTENT.y - 10.0)
	t.check(not joystick.sees(past) and joystick.sees(past, 20.0),
			"10px past the top edge is out of sight, and in sight with a 20px margin")
	var scale := joystick.view.size / ScreenOrientation.DESIGN_SIZE
	var corner_top := joystick.view.position.y + VisibleView.covered_left().position.y * scale.y
	var corner_x := joystick.view.position.x + VisibleView.covered_left().get_center().x * scale.x
	var just_in := Vector2(corner_x, corner_top + 10.0)
	t.check(not joystick.sees(just_in) and joystick.sees(just_in, 20.0),
			"10px into a covered corner is out of sight, and in sight with a 20px margin")

## On the tap scheme's whole view a thing is placed where its drawn box has just left the view:
## straight up, its feet at the top edge (the box stands above them); straight down, the box's top at
## the bottom edge; across, half the box past the side.
func _test_just_out_of_sight_is_the_edge_of_the_view_on_each_side(t) -> void:
	var tap := VisibleView.around(Vector2.ZERO)
	var box := Rect2(-10.0, -30.0, 20.0, 30.0)
	var m := VisibleView.CLEAR_MARGIN
	t.close_to(tap.clear_of_sight(Vector2.ZERO, Vector2.UP, box), Tuning.VIEW_HALF_EXTENT.y + m,
			"straight up, its feet just past the top edge", 0.01)
	t.close_to(tap.clear_of_sight(Vector2.ZERO, Vector2.DOWN, box), Tuning.VIEW_HALF_EXTENT.y + 30.0 + m,
			"straight down, the top of the box just past the bottom edge", 0.01)
	t.close_to(tap.clear_of_sight(Vector2.ZERO, Vector2.RIGHT, box), Tuning.VIEW_HALF_EXTENT.x + 10.0 + m,
			"across, half the box past the side", 0.01)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2(1.0, -1.0).normalized(),
			Vector2(-2.0, 1.0).normalized()]:
		var d := tap.clear_of_sight(Vector2.ZERO, direction, box)
		var at := direction * d
		t.check(not tap.sees_any(Rect2(at + box.position, box.size)),
				"along %v the box placed %.0fpx out is wholly out of sight" % [direction, d])
		var nearer := direction * (d - VisibleView.CLEAR_MARGIN - 2.0)
		t.check(tap.sees_any(Rect2(nearer + box.position, box.size)),
				"and a couple of px nearer it is not, so it comes into sight at once")

## In the joystick scheme a way down into a bottom corner ends at the corner's edge, nearer than the
## view's own: the corner is out of sight, as the area says.
func _test_just_out_of_sight_may_be_a_covered_corner(t) -> void:
	var tap := VisibleView.around(Vector2.ZERO)
	var joystick := VisibleView.around(Vector2.ZERO, true)
	var box := Rect2(-6.0, -12.0, 12.0, 12.0)
	var way := Vector2(-1.0, 1.0).normalized()
	var with_corner := joystick.clear_of_sight(Vector2.ZERO, way, box)
	var without := tap.clear_of_sight(Vector2.ZERO, way, box)
	t.check(with_corner < without,
			"down and left, the corner is reached before the view's edge (%.0f against %.0f)"
			% [with_corner, without])
	var at := way * with_corner
	t.check(not joystick.sees_any(Rect2(at + box.position, box.size))
			and tap.sees_any(Rect2(at + box.position, box.size)),
			"and a thing placed there is under the corner: out of sight with the joystick only")
	t.close_to(joystick.clear_of_sight(Vector2.ZERO, Vector2.UP, box),
			tap.clear_of_sight(Vector2.ZERO, Vector2.UP, box),
			"straight up, away from the corners, the two schemes agree", 0.01)

## The floor holds whatever the corners allow: no direction, in either scheme, places a thing
## nearer than `Tuning.min_offscreen_boundary()` when asked for it, which is the worst case
## `EventDef.validate()` checks a row's field against.
func _test_just_out_of_sight_is_never_nearer_than_its_floor(t) -> void:
	var floor_px := Tuning.min_offscreen_boundary()
	for joystick: bool in [false, true]:
		var view := VisibleView.around(Vector2.ZERO, joystick)
		var nearest := INF
		for step in 72:
			var direction := Vector2.RIGHT.rotated(TAU * step / 72.0)
			nearest = minf(nearest, view.clear_of_sight(Vector2.ZERO, direction, Rect2(), floor_px))
		t.check(nearest + 0.001 >= floor_px,
				"%s: the nearest place over every direction is %.0fpx, at least the %.0fpx floor"
				% ["joystick" if joystick else "tap", nearest, floor_px])

## `look_through()` reads the camera on her and the scheme of the controls in her tree: a body with
## no camera is the view about her, and with no controls built the scheme is the tap one.
func _test_the_view_follows_the_camera_and_the_scheme(t) -> void:
	var body := Node2D.new()
	body.global_position = Vector2(500.0, 300.0)
	var view := VisibleView.new()
	view.look_through(body)
	t.check(view.view.get_center().is_equal_approx(body.global_position) and not view.joystick,
			"a body with no camera and no controls is the tap scheme's view about her")
	# With the game's own controls in her tree, the scheme they are in decides the corners.
	t.add_child(body)
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var joystick_view := VisibleView.new()
	joystick_view.look_through(body)
	t.check(joystick_view.joystick, "the controls in the joystick scheme turn the covered corners on")
	controls.set_mode(ControlsMode.Mode.TAP)
	joystick_view.look_through(body)
	t.check(not joystick_view.joystick, "and in the tap scheme off again, following the scheme")
	controls.free()
	body.free()

## *(PLAYTEST-71 era rotation, `ScreenOrientation`: a portrait touch window presents the game turned
## a quarter.)* The world goes through the camera, turned, and the controls through their layer,
## turned the same way, so every world point lands at the same place in the 1280x720 design box the
## controls are authored in either way — which is why `VisibleView` asks its question of the world
## box and needs no rotation of its own. Built from the camera's canvas transform at zoom 2, turned
## and not, and `ScreenOrientation.to_design_space()`, the turn `DangerEdge` draws through.
func _test_a_rotated_window_shows_the_same_world_under_the_same_corners(t) -> void:
	var centre := Vector2(812.0, -233.0)
	var zoom := ScreenOrientation.DESIGN_SIZE / (Tuning.VIEW_HALF_EXTENT * 2.0)
	var flat := Transform2D(0.0, zoom, 0.0, ScreenOrientation.DESIGN_SIZE * 0.5) \
			* Transform2D(0.0, -centre)
	# The game's own turn of the camera (`ScreenOrientation.apply_to_camera()`, what
	# `main._apply_orientation()` calls): a camera turned by r turns the view by -r, about the middle
	# of the swapped box `ScreenOrientation.content_scale_size()` presents.
	var camera := Camera2D.new()
	ScreenOrientation.apply_to_camera(camera, true)
	var presented := Vector2(ScreenOrientation.content_scale_size(true))
	var turned := Transform2D(-camera.rotation, zoom, 0.0, presented * 0.5) \
			* Transform2D(0.0, -centre)
	camera.free()
	var joystick := VisibleView.around(centre, true)
	var left := VisibleView.covered_left()
	var right := VisibleView.covered_right()
	var design_box := Rect2(Vector2.ZERO, ScreenOrientation.DESIGN_SIZE)
	var agreed := 0
	var points := 0
	for gx in range(-12, 13):
		for gy in range(-8, 9):
			var world := centre + Vector2(gx * 30.0, gy * 25.0)
			var on_flat := flat * world
			var on_turned := ScreenOrientation.to_design_space(turned * world, true)
			points += 1
			var in_sight := design_box.has_point(on_turned) and not left.has_point(on_turned) \
					and not right.has_point(on_turned)
			if on_turned.is_equal_approx(on_flat) and in_sight == joystick.sees(world):
				agreed += 1
	t.check(agreed == points,
			"every point lands at the same design-box place turned or not, and is in sight under the "
			+ "turned controls exactly when the view says it is (%d of %d)" % [agreed, points])

## A duck-typed event source for `DangerEdge.setup()` that keeps a view of its own, the way
## `EventManager` does.
class _Source extends Node:
	var live: Array[EventInstance] = []
	var view := VisibleView.new()

	func instances() -> Array[EventInstance]:
		return live

	func visible_view() -> VisibleView:
		return view

## **The badge stays up for a thing under a corner the joystick's controls cover** (dappled-swan's
## warnings-and-placement): a cyclist riding at her inside the left corner's rectangle is out of
## sight in the joystick scheme, so `DangerEdge` keeps its badge; in the tap scheme it is in sight,
## and there is none.
func _test_the_badge_stays_up_for_a_thing_under_a_covered_corner(t) -> void:
	var her := Vector2(2000.0, 2000.0)
	var corner := VisibleView.covered_left().get_center() - ScreenOrientation.DESIGN_SIZE * 0.5
	var start := her + corner * 0.5
	for joystick: bool in [true, false]:
		var source := _Source.new()
		var player := Node2D.new()
		t.add_child(player)
		player.global_position = her
		var bike := EventInstance.new()
		bike.setup(EventCatalogue.by_id("cyclist"), start, PackedVector2Array([start, her]))
		bike.resume(EventCatalogue.by_id("cyclist").telegraph_time, 0.0)
		bike.came_under_a_warning = true
		source.live.append(bike)
		source.view.look(VisibleView.around(her).view, joystick)
		var edge := DangerEdge.new()
		t.add_child(edge)
		edge.setup(source, player)
		var step := 1.0 / 60.0
		for i in 6:
			bike.player_at = her
			bike._process(step)
			edge._measure(step)
		var badged := false
		for badge in edge.announcing():
			badged = badged or badge["id"] == "cyclist"
		t.check(badged == joystick, "%s scheme: a cyclist under the left corner %s"
				% ["joystick" if joystick else "tap", "keeps its badge" if joystick else "has none"])
		edge.free()
		bike.free()
		player.free()
		source.free()
