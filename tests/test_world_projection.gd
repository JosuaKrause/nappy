extends RefCounted
## Geometric proof that the 3D presentation agrees with the live logical camera.
##
## These checks use a real Camera3D in a real 1280x720 SubViewport. They deliberately do not
## construct a player or a City: the adapter reads the camera transform, and the visual layer must
## not become a second simulation just to prove its projection.

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const EPSILON := 0.08

func run(t) -> void:
	_test_ground_scale(t)
	_test_camera_tracks_center_zoom_and_corners(t)
	_test_rotated_presentation(t)
	_test_inverse_tap_picking(t)

func _test_ground_scale(t) -> void:
	var logical_points := [Vector2.ZERO, Vector2(32.0, 32.0), Vector2(320.0, 160.0)]
	for logical_position_px: Vector2 in logical_points:
		var world_position := WorldProjection.logical_to_world(logical_position_px)
		var round_trip := WorldProjection.world_to_logical(world_position)
		t.close_to(round_trip.x, logical_position_px.x,
			"ground x round-trips through model units")
		t.close_to(round_trip.y, logical_position_px.y,
			"ground y round-trips through the 65-degree compensation")
	var one_tile := WorldProjection.logical_to_world(Vector2(32.0, 32.0))
	t.close_to(one_tile.x, 1.0, "one logical tile is one model unit on x")
	t.close_to(one_tile.z * sin(WorldProjection.PITCH_RADIANS), 1.0,
		"one logical tile is one projected model unit on z")

func _test_camera_tracks_center_zoom_and_corners(t) -> void:
	var viewport := _make_viewport(t)
	var camera := _make_camera(viewport)
	var canvas := _canvas(Vector2(640.0, 360.0), 2.0)
	WorldProjection.sync_camera(camera, canvas, false, DESIGN_SIZE)
	t.close_to(camera.size, 11.25, "zoom two uses the design height as orthographic size")
	_assert_projected_points(t, camera, canvas, false,
		[Vector2(640.0, 360.0), Vector2(320.0, 180.0), Vector2(960.0, 540.0), Vector2(448.0, 288.0)])

	canvas = _canvas(Vector2(928.0, 512.0), 1.35)
	WorldProjection.sync_camera(camera, canvas, false, DESIGN_SIZE)
	t.close_to(camera.size, DESIGN_SIZE.y / (1.35 * 32.0),
		"camera size follows the live canvas zoom")
	_assert_projected_points(t, camera, canvas, false,
		[Vector2(928.0, 512.0), Vector2(608.0, 332.0), Vector2(1248.0, 692.0)])
	viewport.free()

func _test_rotated_presentation(t) -> void:
	var viewport := _make_viewport(t)
	var camera := _make_camera(viewport)
	var design_canvas := _canvas(Vector2(760.0, 440.0), 1.8)
	var presented_canvas := ScreenOrientation.rotation_transform() * design_canvas
	WorldProjection.sync_camera(camera, presented_canvas, true, DESIGN_SIZE)
	_assert_projected_points(t, camera, presented_canvas, true,
		[Vector2(760.0, 440.0), Vector2(120.0, 80.0), Vector2(1180.0, 640.0)])
	viewport.free()

func _test_inverse_tap_picking(t) -> void:
	var canvas := _canvas(Vector2(802.0, 415.0), 2.0)
	for rotated in [false, true]:
		var actual_canvas := ScreenOrientation.rotation_transform() * canvas if rotated else canvas
		for logical_position_px: Vector2 in [Vector2(802.0, 415.0), Vector2(610.0, 295.0), Vector2(1010.0, 590.0)]:
			var design_position_px := WorldProjection.logical_to_design(logical_position_px,
				actual_canvas, rotated, DESIGN_SIZE)
			var picked_logical_px := WorldProjection.design_to_logical(design_position_px,
				actual_canvas, rotated, DESIGN_SIZE)
			t.close_to(picked_logical_px.x, logical_position_px.x,
				"tap x survives presentation unrotation")
			t.close_to(picked_logical_px.y, logical_position_px.y,
				"tap y survives presentation unrotation")

func _assert_projected_points(t, camera: Camera3D, canvas: Transform2D, rotated: bool,
		logical_points_px: Array[Vector2]) -> void:
	for logical_position_px: Vector2 in logical_points_px:
		var expected_design_px := WorldProjection.logical_to_design(logical_position_px,
			canvas, rotated, DESIGN_SIZE)
		var projected_screen_px := camera.unproject_position(
			WorldProjection.logical_to_world(logical_position_px))
		t.close_to(projected_screen_px.x, expected_design_px.x,
			"Camera3D x agrees with the logical canvas transform", EPSILON)
		t.close_to(projected_screen_px.y, expected_design_px.y,
			"Camera3D y agrees with the logical canvas transform", EPSILON)

func _canvas(center_logical_px: Vector2, zoom: float) -> Transform2D:
	var transform := Transform2D.IDENTITY.scaled(Vector2.ONE * zoom)
	transform.origin = DESIGN_SIZE * 0.5 - center_logical_px * zoom
	return transform

func _make_viewport(t) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "ProjectionViewport"
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.world_3d = World3D.new()
	t.add_child(viewport)
	return viewport

func _make_camera(viewport: SubViewport) -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "ProjectionCamera"
	viewport.add_child(camera)
	camera.current = true
	return camera
