extends RefCounted
## The crowd's focus source while the opening shot's camera is the view (`CameraFocus`): it answers
## where that camera looks, read at each ask, and keeps the last answer once the camera is gone. The
## camera is a bare `Camera2D`; that the crowd follows whatever source it holds is
## `test_crowd_coverage.gd`'s.

func run(t: TestRunner) -> void:
	var camera := Camera2D.new()
	camera.name = "ShotCamera"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	t.add_child(camera)
	camera.global_position = Vector2(640.0, 320.0)
	var focus := CameraFocus.new(camera)
	t.check(focus.where() == camera.get_screen_center_position(),
			"the source answers where the camera looks")
	camera.global_position = Vector2(2000.0, -96.0)
	t.check(focus.where() == camera.get_screen_center_position(),
			"and where it looks after it has moved on, asked again")
	var last := focus.where()
	camera.free()
	t.check(focus.where() == last, "a freed camera is not asked: the last place it looked stands")
