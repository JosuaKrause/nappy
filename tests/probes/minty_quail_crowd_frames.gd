extends RefCounted
## **Whether the crowd is drawn moving on every frame the screen draws, faster than the 30Hz tick it
## steps on**: a busy street's crowd run by the engine's own loop, in a window, and a run of
## consecutive drawn frames read back from the viewport. Not a suite, and not headless: run it by
## hand in a window, at a desktop's frame rate, in each revision's checkout:
##
##     CROWD_FRAMES_OUT=/tmp/frames "$GODOT" --path . --resolution 1280x720 --disable-vsync \
##         --max-fps 120 res://tests/tests.tscn -- probes/minty_quail_crowd_frames.gd
##
## The city of seed 4242 starts day 1 with its crowd centred on the doorstep, a camera at zoom 2
## looks at the same spot, nobody is handed to the crowd as her, and after `WARMUP_TICKS` physics
## ticks `FRAMES` consecutive drawn frames are read back (`DrawnFrame.wait()`, which draws a frame on
## demand when the window is covered). Each frame prints one `CROWD_FRAMES_JSON` line: the physics
## ticks run so far, the interpolation fraction, the followed car's node position (where its last
## tick put it) and how many of the crop's pixels (the crop saved to `strip.png`) differ from the
## frame before. A frame drawn with no tick since the last one whose pixels still differ shows the crowd drawn moving between ticks;
## where the crowd moved only on the tick, such a frame would be pixel for pixel the one before.
## It writes `strip.png`, the same crop of every frame side by side, round where the followed car
## was in the first, and
## `frame-first.png`, the first whole frame, into `CROWD_FRAMES_OUT`.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const CITY_SEED := 4242
const WARMUP_TICKS := 90
const FRAMES := 12
const ZOOM := Vector2(2.0, 2.0)
const CROP := Vector2i(240, 150)

func run(t) -> void:
	var out := OS.get_environment("CROWD_FRAMES_OUT")
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.crowd_view = ScreenCrowdView.new(t)
	city.build(CityGenerator.generate(CITY_SEED))
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 1)
	var closures := RandomNumberGenerator.new()
	closures.seed = hash("crowd-frames-closures")
	city.start_day(state, 1, closures)
	var focus := city.map.doorstep_world_position()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-frames")
	city.crowd.start_day(1, rng, focus)
	var camera := Camera2D.new()
	camera.zoom = ZOOM
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = focus
	t.add_child(camera)
	camera.make_current()
	for _tick in WARMUP_TICKS:
		await t.get_tree().physics_frame
	var car := _moving_car_nearest(city.crowd, focus)
	var window := Vector2(t.get_viewport().get_visible_rect().size)
	var images: Array[Image] = []
	var rows: Array[Dictionary] = []
	# What the frame just drawn was drawn from, noted as it finishes drawing: by the time
	# `DrawnFrame.wait()` returns, the next frame's physics ticks have already run.
	var drawn := {}
	var note := func() -> void:
		var here := car.global_position if car else focus
		drawn["physics_ticks"] = Engine.get_physics_frames()
		drawn["fraction"] = Engine.get_physics_interpolation_fraction()
		drawn["car_node"] = [here.x, here.y]
		drawn["screen"] = (here - camera.get_screen_center_position()) * ZOOM + window * 0.5
	RenderingServer.frame_post_draw.connect(note)
	for frame in FRAMES:
		var forced := await DrawnFrame.wait(t.get_tree())
		images.append(t.get_viewport().get_texture().get_image())
		var row := drawn.duplicate()
		row["frame"] = frame
		row["forced_draw"] = forced
		row["fps"] = Engine.get_frames_per_second()
		rows.append(row)
	RenderingServer.frame_post_draw.disconnect(note)
	var crops: Array[Image] = []
	var anchor: Vector2 = rows[0].screen
	# One crop for every frame, round where the car was drawn from in the first, so the car is seen
	# moving through it and the street stands still. The pixels counted below are the crop's own.
	var corner := (Vector2i(anchor) - CROP / 2).clamp(Vector2i.ZERO,
			Vector2i(images[0].get_size()) - CROP)
	for image in images:
		crops.append(image.get_region(Rect2i(corner, CROP)))
	var still_between_ticks := 0
	var moved_between_ticks := 0
	for frame in FRAMES:
		var row := rows[frame]
		var differing := _differing_pixels(crops[frame - 1], crops[frame]) if frame > 0 else 0
		var ticked: bool = frame == 0 or row.physics_ticks != rows[frame - 1].physics_ticks
		if not ticked:
			if differing > 0:
				moved_between_ticks += 1
			else:
				still_between_ticks += 1
		row.erase("screen")
		row["tick_since_last_frame"] = ticked
		row["differing_pixels"] = differing
		print("CROWD_FRAMES_JSON " + JSON.stringify(row))
	if not out.is_empty():
		images[0].save_png(out.path_join("frame-first.png"))
	print("CROWD_FRAMES_SUMMARY " + JSON.stringify({"frames": FRAMES,
		"frames_without_a_tick_that_moved": moved_between_ticks,
		"frames_without_a_tick_that_stood_still": still_between_ticks,
		"interpolated": t.get_tree().physics_interpolation}))
	if not out.is_empty():
		var strip := Image.create(CROP.x * crops.size(), CROP.y, false, crops[0].get_format())
		for i in crops.size():
			strip.blit_rect(crops[i], Rect2i(Vector2i.ZERO, CROP), Vector2i(i * CROP.x, 0))
		strip.save_png(out.path_join("strip.png"))
	camera.free()
	city.free()
	t.check(true, "ran")

func _moving_car_nearest(crowd: Crowd, at: Vector2) -> CrowdAgent:
	var best: CrowdAgent = null
	for agent in crowd.agents():
		if agent.kind != CrowdAgent.Kind.CAR or agent.speed() < 60.0:
			continue
		if best == null or agent.global_position.distance_squared_to(at) \
				< best.global_position.distance_squared_to(at):
			best = agent
	return best

func _differing_pixels(a: Image, b: Image) -> int:
	if a == null or a.get_size() != b.get_size():
		return 0
	var count := 0
	var size := a.get_size()
	for y in size.y:
		for x in size.x:
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				count += 1
	return count
