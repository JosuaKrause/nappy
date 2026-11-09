@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The map's top-left corner must never show for a moment when a run starts — PLAYTEST-76: "when
## starting the game I can briefly see the top left of the map." The world's origin is the map's
## top-left, so any frame drawn before a camera has taken her position would show that corner
## unless something else is already current and looking at the doorstep by then.
##
## **Only a real boot of `scenes/main.tscn` reaches the frame that matters.** No hand-built rig
## gets there: the gap is between `_city.build()` and `_player` existing at all, which is inside
## `main._ready()` itself, either side of `await _warm_the_pictures()`.
##
## `t.add_child(main)` runs `_ready()` synchronously up to its first suspension, the canvas warm-up
## that holds the boot for its drawn frames, and hands control back here exactly at that point,
## which is the state a real first frame would draw from: she does not exist yet. Real frames then
## let the boot finish, however many it holds for (`tests/booted_main.gd`), and the title's button
## is pressed through the viewport. Each boot plays a run made fresh for it, parked in a sitting
## home of the test's own (`Boot.home_playing()`).
##
## **This suite boots `main` and keeps the real city, player, camera and screens, for a stated reason**:
## its subject is `main`'s own boot, the order it builds the boot camera, the city, the title and her in
## (the frame between `_city.build()` and `_player` existing), and the one thing no stand-in can hold is
## that order. The city comes from the cache of generated maps (`tests/city_map_cache.gd`) and is not
## generated for the boot. It is `main`'s composition, which `tests/test_main.gd` also holds.

const Boot := preload("res://tests/booted_main.gd")
const MapCache := preload("res://tests/city_map_cache.gd")
## The save every boot is handed, so nothing here reaches `user://save.json`.
const _SCRATCH_SAVE := "user://test_camera_start_scratch.json"

func run(t) -> void:
	await _test_a_boot_camera_stands_on_the_doorstep_before_she_exists(t)
	await _test_a_boot_camera_is_turned_for_a_portrait_phone_before_the_first_frame(t)

## The real `main.tscn` handed a scratch save, `config` and a run of its own (parked in a home the
## test frees), put in the tree and left at the boot's first suspension: the frame the boot camera
## draws.
func _start_a_boot(t, config: RunConfig) -> Array:
	var save := GameSave.new(_SCRATCH_SAVE)
	var run := RunState.new()
	var home := Boot.home_playing(t, run)
	var main: Node2D = Boot.MAIN_SCENE.instantiate()
	main.use_save(save)
	main.use_sitting_home(home)
	main.use_city_maps(MapCache.source())
	main.configure(config)
	t.add_child(main)
	return [main, save, home]

func _end_the_boot(boot: Array) -> void:
	var main: Node2D = boot[0]
	main.get_tree().paused = false
	main.free()
	(boot[1] as GameSave).free()
	(boot[2] as Node).free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_SAVE))

## Boots for real, checks the frame the bug lived on, then lets the boot finish and checks the two
## frames PLAYTEST-76's own entry named as candidates: the first with the run started, and the
## first after the title's disc is pressed.
func _test_a_boot_camera_stands_on_the_doorstep_before_she_exists(t) -> void:
	var boot := _start_a_boot(t, Boot.config([]))
	var main: Node2D = boot[0]

	# The suspended point. She is only built after the canvas warm-up returns, so no camera of
	# *hers* exists yet — confirming this is really the gap the doc above describes, not a
	# coincidence of timing. The boot camera stands in for her: the viewport's own current camera
	# should already be on the doorstep, the same ground the title screen will show.
	t.check(Boot.player(main) == null,
			"no player camera exists yet at the point the first frame would be drawn from")
	var boot_camera := main.get_viewport().get_camera_2d()
	var city := Boot.city(main)
	t.check(boot_camera != null, "a camera is already current before she exists")
	t.check(boot_camera != null and city != null and boot_camera.get_screen_center_position()
				.distance_to(city.map.doorstep_world_position()) < Tuning.TILE_SIZE,
			"and it is already looking at the doorstep rather than the world's default transform, "
			+ "which puts its own top-left corner on screen")

	await Boot.until_booted(t, main)
	var player := Boot.player(main)
	var her_position: Vector2 = player.global_position
	t.check(player.camera_screen_center().distance_to(her_position) < Tuning.TILE_SIZE,
			"on the first drawn frame with the run started, the camera is already within a tile "
			+ "of her")

	await Boot.press_title(t, main, "Tap")
	t.check(player.camera_screen_center().distance_to(player.global_position)
				< Tuning.TILE_SIZE,
			"and the same holds on the first frame after the title's disc is pressed")
	# A dawn after finishing far away must prepare home before the next process callback: she is
	# put far from home, the day is lost and its summary continued, and the home's ground is read
	# the moment the next attempt has been placed (`EventBus.day_planned`), before any frame.
	var far := Rect2(Vector2(64, 64), Tuning.VIEW_HALF_EXTENT * 2)
	city.scenery.update(far, true)
	player.reset_at(far.get_center())
	var dawns: Array[int] = []
	var at_dawn := func(_day: int) -> void:
		dawns.append(1)
		var home_view := Rect2(city.map.doorstep_world_position() - Tuning.VIEW_HALF_EXTENT,
				Tuning.VIEW_HALF_EXTENT * 2)
		for key in city.scenery_ground.keys_in(home_view):
			t.check(city.scenery_ground.chunks.has(key),
					"real day reset prepares the home viewport before its first frame")
	EventBus.day_planned.connect(at_dawn)
	EventBus.hard_fail_triggered.emit("car_strike")
	await Boot.press_continue(t, main)
	EventBus.day_planned.disconnect(at_dawn)
	t.check(dawns.size() == 1, "the lost day's continue placed the next attempt (%d)" % dawns.size())

	_end_the_boot(boot)

## PLAYTEST-140, statement 5: "when you lose with game over the title screen is sideways", and
## PLAYTEST-144's still after a held restart, "This is the screen when resetting" — both on a
## portrait phone, both right after a scene reload. The frames `_warm_the_canvas_shaders()` draws
## before she exists are the boot camera's, and they stay on screen through the rest of `_ready()`
## until the title is drawn, so the boot camera and the window's box have to be turned for the
## phone before the first of them, not only once she and the HUD exist.
##
## The window is made portrait and the boot told it is on a touch screen, which is the one shape
## that wants rotation; the box is left at the unrotated 1280x720 a first boot starts in, so both
## halves — the box and the camera — have something to correct. After a reload the box would
## already be the rotated one, which leaves only the camera wrong; the camera's assertion is that
## case.
func _test_a_boot_camera_is_turned_for_a_portrait_phone_before_the_first_frame(t) -> void:
	var window: Window = t.get_tree().root
	var saved_size := window.size
	var saved_box := window.content_scale_size
	window.size = Vector2i(ScreenOrientation.ROTATED_SIZE)
	window.content_scale_size = Vector2i(ScreenOrientation.DESIGN_SIZE)
	t.check(ScreenOrientation.wants_rotation(window.size, true),
			"the window this test boots into is one that wants rotation on a touch screen")

	var boot := _start_a_boot(t, Boot.config(["--touch"]))
	var main: Node2D = boot[0]

	# The suspended point, before her camera exists: the frame the boot camera draws.
	t.check(Boot.player(main) == null, "suspended before she exists, where the boot camera draws")
	t.check(window.content_scale_size == ScreenOrientation.content_scale_size(true),
			"the window already presents in the rotated box before the first frame")
	var boot_camera := main.get_viewport().get_camera_2d()
	t.check(boot_camera != null and not boot_camera.ignore_rotation
				and is_equal_approx(boot_camera.rotation, -deg_to_rad(90.0)),
			"and the boot camera is turned with it, so the city it shows is not drawn upright")

	await Boot.until_booted(t, main)
	t.check(Boot.touch_controls(main).rotated, "the finished boot has turned the whole presentation")
	t.check(Boot.carries_the_rotation(Boot.title(main)),
			"including the title it opens on")

	_end_the_boot(boot)
	window.size = saved_size
	window.content_scale_size = saved_box
