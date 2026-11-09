extends RefCounted
## **Every stretch scene, played through: nothing in its crowd appears or vanishes where she can see
## it, and she sees the event its rigged bag sends** *(the player's rule, PR #597; polite-dolphin,
## inbox #555: "right now it's just empty", "that's not a good test")*. Each scene under
## `scene-recipes/` with a stretch scope is played in its own headless process, scripted, to its end;
## the runtime records a walker or car that left or entered within reach of either view
## (`SceneRecipeRuntime._watch_the_crowd()`, the manifest's `seen_to_jump`), and every observation the
## recipe asks, its `appeared` of the route event and its `crowd` among them, must hold.
##
## **Plays each scene in its own headless `main` process: the guarantee is about what she sees of the crowd
## across the whole game's composition** (the runtime's watch, the crowd, the director's bag), so it is combined
## by design and has no module to split to.

func run(t) -> void:
	var played := 0
	for filename in DirAccess.get_files_at("res://scene-recipes"):
		if not filename.ends_with(".json"):
			continue
		var path := "res://scene-recipes/" + filename
		var data: Dictionary = SceneRecipe.load_file(path).data
		if data.get("extent", {}).get("scope") != "stretch":
			continue
		await _force_recycles(t, path, data, filename)
		var manifest_path := "user://stretch_crowd_%d_%s" % [OS.get_process_id(), filename]
		var output: Array = []
		var status := OS.execute(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--fixed-fps", "60",
			"--quit-after", str(ceili(float(data.playback.duration) * 60.0) + 600),
			"--", "--recipe", path, "--recipe-mode", "scripted", "--no-save", "--no-telemetry",
			"--recipe-manifest", ProjectSettings.globalize_path(manifest_path)]), output, true)
		var parser := JSON.new()
		var read := FileAccess.get_file_as_string(manifest_path)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(manifest_path))
		if parser.parse(read) != OK or not parser.data is Dictionary:
			t.check(false, "%s wrote a manifest: %s" % [filename, "\n".join(output)])
			continue
		var manifest: Dictionary = parser.data
		var unmet: Array = (manifest.get("observations", []) as Array).filter(
				func(record: Dictionary) -> bool: return not record.passed)
		var engine_failed := "\n".join(output).contains("ERROR:")
		t.check(status == 0 and not engine_failed and manifest.get("playback_complete", false) and unmet.is_empty(),
				"%s plays to its end with every observation met: %s\n%s" % [filename, unmet,
					"\n".join(output) if status != 0 else str(manifest.get("playback_error", ""))])
		var jumps: Array = manifest.get("seen_to_jump", [])
		t.check(jumps.is_empty(), "%s: nobody appears or vanishes in her view: %s" % [filename, jumps])
		t.check(manifest.get("in_the_void", []).is_empty(),
				"%s: no waiting body is left outside authored ground" % filename)
		var asks_an_event := (data.playback.observations as Array).any(
				func(check: Dictionary) -> bool: return check.condition == "appeared")
		t.check(asks_an_event, "%s asks that she sees a route event" % filename)
		played += 1
	t.check(played >= 10, "every stretch scene is played (%d)" % played)

## Short authored walks need not naturally exhaust a street, so the scene is played here with a body
## of each kind set walking off every end of the stretch, with a real camera for the view boundary at
## her camera's zoom, on the crowd's own physics frames. Then, for each stretch end in turn, the
## camera looks straight at it, and then from beside it on either side, just far enough that the end's
## middle is out of view (`CrowdView.beyond_every_view()`, the question the crowd asks) while ground a
## pixel nearer, its near lanes, is in it. A body that walks off an end it can be seen at turns round
## where it stands: it is not moved, and nothing in the crowd's drawing is reset. A body that walks
## off one it cannot be seen at is entered again at an end, and no entry may stand in the view it was
## made under, by the crowd's rule and by the real view (`_out_of_the_real_view()`), nor off the
## authored street. The end in view is what dropping the in-view ends keeps out, and the near lanes
## are what checking the final placement keeps out.
func _force_recycles(t, path: String, data: Dictionary, label: String) -> void:
	var loaded := SceneRecipeRuntime.load_recipe(path, PackedStringArray())
	if not loaded.errors.is_empty():
		t.check(false, "%s loads for forced crowd entries" % label)
		return
	var map: CityMap = loaded.map
	var run := RunState.new()
	run.start_run(STRETCH_SEED)
	var city := RunCity.in_run(CITY_SCENE, run)
	var view := ScreenCrowdView.new(t)
	city.crowd_view = view
	t.add_child(city)
	city.build(map)
	var state := CityState.new()
	state.begin_day(city.map.block_plans, 1)
	city.start_recipe_day(state, 1, run.calendar.day_rng())
	var camera := Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.zoom = Vector2.ONE * HER_ZOOM
	t.add_child(camera)
	camera.make_current()
	var crowd := city.crowd
	crowd.start_day(1, run.calendar.day_rng(1, "crowd"), map.world_size() * 0.5, false)
	crowd.use_stretch()
	var ends := crowd.field().ends_of_the_stretch()
	var watch := {"stays": true, "ends_seen": true, "safe": true, "entries": 0, "placed": 0,
			"in_view": 0, "unsafe": [] as Array[String]}
	for end: Dictionary in ends:
		var middle := _middle_of(end)
		var across := Vector2.RIGHT if end.vertical else Vector2.DOWN
		# The least distance across at which the camera no longer sees the end's middle, by the
		# crowd's own rule, so whatever that rule's view and room are, the lanes a pixel nearer the
		# camera are in view.
		_look_at(camera, middle)
		var aside := 0.0
		while aside < 4096.0 and not view.beyond_every_view(middle + across * aside,
				CrowdAgent.ENTRY_PICTURE_ROOM, middle):
			aside += 1.0
		for looking: Vector2 in [middle, middle + across * aside, middle - across * aside]:
			_look_at(camera, looking)
			crowd.set_focus(looking)
			watch.ends_seen = watch.ends_seen and aside < 4096.0 and (looking != middle
					or not view.beyond_every_view(middle, CrowdAgent.ENTRY_PICTURE_ROOM, looking))
			await _walk_every_end_off(crowd, camera, view, ends, looking, label, watch)
	t.check(watch.placed > 0, "%s: bodies are set walking off its ends (%d)" % [label, watch.placed])
	t.check(watch.in_view > 0, "%s: some of them walk off an end in view (%d)" % [label, watch.in_view])
	t.check(watch.stays, "%s: a body walking off an end in view turns round, it does not jump" % label)
	t.check(watch.ends_seen, "%s: the camera on a stretch end has that end in view" % label)
	t.check(watch.entries > 0 and watch.safe,
			("%s: %d entries, each made with an end or its near lanes in view, stay on "
			+ "authored street out of that view: %s") % [label, watch.entries, watch.unsafe])
	camera.free()
	city.free()

## A walker and a car set walking off each end of the stretch, with the camera where it is, and the
## crowd's own physics frames let pass; then the crowd emptied. Every landing of a body (the frame its
## drawing is reset, `_Landings`) is judged and added to `watch`.
func _walk_every_end_off(crowd: Crowd, camera: Camera2D, view: CrowdView, ends: Array[Dictionary],
		looking: Vector2, label: String, watch: Dictionary) -> void:
	var bodies: Array[Dictionary] = []
	for end: Dictionary in ends:
		var outward := -float(end.direction)
		var heading := Vector2(0.0, outward) if end.vertical else Vector2(outward, 0.0)
		var along := (float(end.along) + 0.5) * Tuning.TILE_SIZE
		var lanes := [["car", CrowdAgent.Kind.CAR, [CrowdLanes.road_lane(end.vertical, outward)],
				Tuning.CAR_SPEED.x], ["walker", CrowdAgent.Kind.WALKER,
				CrowdLanes.SIDEWALK_OFFSETS, Tuning.PEDESTRIAN_SPEED.x]]
		for lane_of: Array in lanes:
			for lane: int in lane_of[2]:
				var centre := CrowdLanes.lane_centre(end.corridor, lane) \
						if lane_of[1] == CrowdAgent.Kind.CAR else \
						CrowdLanes.walker_lane_centre(end.corridor, lane, CrowdLanes.SIDEWALK_OFFSETS)
				var at := Vector2(centre, along) if end.vertical else Vector2(along, centre)
				var placed := crowd.add_recipe_actor("%s-%d" % [lane_of[0], bodies.size()],
						lane_of[1], at, heading, lane_of[3], hash("stretch:%s:%d" % [label, bodies.size()]))
				if placed.error != "":
					continue
				var body: CrowdAgent = placed.actor
				bodies.append({"agent": body, "from": body.position,
						"seen": not view.beyond_every_view(body.position,
								CrowdAgent.ENTRY_PICTURE_ROOM, looking)})
				break
	# Marked once all are placed: placing a body resets every drawing in the crowd.
	for body: Dictionary in bodies:
		body.landings = _Landings.new()
		body.agent.add_child(body.landings)
	watch.placed += bodies.size()
	await _let_the_physics_run(crowd, 0.5)
	for body: Dictionary in bodies:
		var landings: _Landings = body.landings
		if body.seen:
			watch.in_view += 1
			# In her view the end is a wall: the body turns where it stands, which resets nothing.
			watch.stays = watch.stays and landings.at.is_empty()
		for landed: Vector2 in landings.at:
			if landed.distance_to(body.from) > Tuning.TILE_SIZE:
				watch.entries += 1
			var tile := crowd.field().map.world_to_tile(landed)
			var safe := crowd.field().map.in_stretch(tile) and crowd.field().map.is_street(tile) \
					and _out_of_the_real_view(camera, landed)
			watch.safe = watch.safe and safe
			if not safe and watch.unsafe.size() < 4:
				watch.unsafe.append("%s landed at %s, camera on %s" % [body.agent.name, landed, looking])
	crowd.clear()
	await crowd.get_tree().physics_frame

## How much faster than real time the stretch of real physics ticks runs (`Engine.time_scale`,
## restored by `PhysicsTicks`), so a few seconds of the crowd's own tick do not take a few seconds
## of the suite. Each tick is then that many times as long, and the wait is counted in ticks.
const FAST_SCALE := 8.0

func _let_the_physics_run(crowd: Crowd, seconds: float) -> void:
	await PhysicsTicks.pass_ticks(crowd, PhysicsTicks.ticks_for(seconds, FAST_SCALE), Callable(),
			FAST_SCALE)

## Where a body's drawing was reset to, each time: the one thing the crowd does to it when it enters
## the stretch again, and does not do to one that turns round.
class _Landings extends Node:
	var at: Array[Vector2] = []

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
			at.append((get_parent() as Node2D).global_position)

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STRETCH_SEED := 4242

## Her camera's zoom (`scenes/player/stroller.tscn`), so the view the entries keep out of is the
## size it is in play.
const HER_ZOOM := 2.0

## The middle of a stretch end's street, at the end's own tile along it: where
## `CrowdAgent._enter_at_a_stretch_end()` asks whether the end is in view.
func _middle_of(end: Dictionary) -> Vector2:
	var along := (float(end.along) + 0.5) * Tuning.TILE_SIZE
	var across := (float(end.corridor) * CityMap.period() + Tuning.STREET_WIDTH * 0.5) \
			* Tuning.TILE_SIZE
	return Vector2(across, along) if end.vertical else Vector2(along, across)

## Whether a body at `at`, `CrowdAgent.ENTRY_PICTURE_ROOM` either side, lies wholly outside the
## world the camera shows: the 1280x720 design box at its zoom, centred where it looks, which is
## the world in both presentations (a portrait touch screen turns the same box a quarter). Asked
## beside the crowd's own rule, which it does not depend on, so a rule that shrinks below the real
## view fails here rather than agreeing with itself.
func _out_of_the_real_view(camera: Camera2D, at: Vector2) -> bool:
	var size := ScreenOrientation.DESIGN_SIZE / camera.zoom
	var view := Rect2(camera.get_screen_center_position() - size * 0.5, size)
	var body := Rect2(at, Vector2.ZERO).grow(CrowdAgent.ENTRY_PICTURE_ROOM)
	return not view.intersects(body)

func _look_at(camera: Camera2D, at: Vector2) -> void:
	camera.position = at
	camera.reset_physics_interpolation()
	camera.reset_smoothing()
	camera.force_update_scroll()
