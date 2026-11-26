extends RefCounted
## The world rect a camera shows (`CameraView`): the viewport at the camera's zoom, turned with the
## camera, centred where the camera looks. A bare `Camera2D` in the runner's tree.

func run(t: TestRunner) -> void:
	var camera := Camera2D.new()
	camera.name = "ViewCamera"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.ignore_rotation = false
	camera.zoom = Vector2(2.0, 2.0)
	t.add_child(camera)
	camera.global_position = Vector2(500.0, 300.0)
	var viewport := Vector2(1280.0, 720.0)

	var upright := CameraView.shown_by(camera, viewport)
	t.check(upright.size.is_equal_approx(Vector2(640.0, 360.0)),
			"an upright camera shows the viewport at its zoom (%s)" % upright.size)
	t.check(upright.get_center().is_equal_approx(camera.get_screen_center_position()),
			"centred where the camera looks")

	camera.rotation = PI * 0.5
	var turned := CameraView.shown_by(camera, viewport)
	t.check(turned.size.is_equal_approx(Vector2(360.0, 640.0)),
			"a camera turned a quarter shows the world rect the other way round (%s)" % turned.size)
	t.check(turned.get_center().is_equal_approx(camera.get_screen_center_position()),
			"and is still centred where it looks")

	camera.rotation = PI * 0.25
	var slanted := CameraView.shown_by(camera, viewport)
	t.check(slanted.size.is_equal_approx(Vector2(1000.0, 1000.0) * sqrt(0.5)),
			"an eighth turn shows the box that holds the turned view (%s)" % slanted.size)

	camera.rotation = 0.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 700
	camera.limit_bottom = 400
	camera.global_position = Vector2(-900.0, -900.0)
	var clamped := CameraView.shown_by(camera, viewport)
	t.check(clamped.get_center().is_equal_approx(camera.get_screen_center_position())
			and clamped.get_center().distance_to(Vector2(-900.0, -900.0)) > 100.0,
			"a camera against its limits shows where the limits hold it, not where it stands (%s)"
			% clamped.get_center())
	camera.free()
