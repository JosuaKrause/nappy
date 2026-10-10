extends RefCounted
## Measurement probe for M213, "the robber stands at the far end of the mark's own alley", and for
## brisk-wombat's "a robber appears out of nowhere": prints numbers, asserts nothing, so it lives
## under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m213_far_end.gd
##
## **The walk.** Every `ALLEY` tile of six cities stands in for a mark. She walks in from the
## alley's near end (`ResistanceDirector._alley_ends()`), starting one and a half tiles outside its
## mouth, up to 34px short of the mark on its near side — inside `ContactPoint.REACH` (36px), so the
## mark is read — and back out the way she came, in 8px steps. A bare `alley_robbery` stands where
## a draw put him; the walk counts as reaching the mark when he is still `is_waiting()` at the end.
## Four draws on the same marks: the whole circle of the 62-176px band around the mark (no far-end
## rule at all), the same band with the bearing leaning toward the far end, and the director's own
## `_draw_guard_position_near_far_mouth()`.
##
## **The screen.** She stands on every `ALLEY` tile in turn; the screen is 640x360 world px
## around her, unrotated (`Tuning.VIEW_HALF_EXTENT`); the director relocates the mark to
## `_nearest_alley_within()` and draws its guard exactly as `_maybe_set_a_trap()` does for a
## relocation. Counted: a relocated mark whose picture, or whose guard's body, shows on that
## screen, and a relocation that leaves the mark unguarded.
##
## **The task guard.** Day 13 of the same six cities, on a real `City` — the roadblock, the one task
## guarded where it waits (`ResistanceDirector.keeps_a_waiting_guard()`): she stands on the day's
## mark and reads it, and the guard the task stands at its own contact (`_task_guard`) is counted
## when none is placed and when his body shows on her screen.

const STEP := 1.0 / 60.0
const SEEDS: Array[int] = [4242, 90210, 2295276695, 314159, 271828, 555555]
const TOUCH_SHORT := 34.0

const CITY_SCENE := preload("res://scenes/world/city.tscn")

func run(t) -> void:
	_reachability(t)
	_on_screen(t)
	_task_guards(t)

## The guard the guarded task (day 13's roadblock) stands at its contact, placed the instant she
## reads the mark: how often none is placed, and how often he shows on her screen.
func _task_guards(t) -> void:
	var saved := GameState.completed_resistance_steps.duplicate()
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	var placed := 0
	var unguarded := 0
	var seen := 0
	for seed_value in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in [13]:
			GameState.completed_resistance_alley_tiles = []
			var done: Array[int] = []
			done.assign(range(1, 2 * (day - 6) + 1))
			GameState.completed_resistance_steps = done
			var state := CityState.new()
			GameState.city_state = state
			state.begin_day(city.map.block_plans, day)
			city.start_day(state, day, _rng(seed_value, day, "closures"))
			city.events.start_day(day, _rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())
			var director := ResistanceDirector.new()
			t.add_child(director)
			director.set_process(false)
			director.setup(city, city.map)
			director.start_day(day, _rng(seed_value, day, "resistance"), 300.0)
			var mark := director.current_step()
			if mark == null or not mark.is_pickup:
				director.free()
				continue
			var her := director.contact_position()
			var player := Stroller.new()
			var camera := Camera2D.new()
			camera.name = "Camera2D"
			player.add_child(camera)
			t.add_child(player)
			player.set_physics_process(false)
			player.global_position = her
			var screen := func(p: Vector2) -> bool:
				return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
						and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y
			director.set_sight(screen, screen)
			director._on_contact_completed(mark.index)
			placed += 1
			var guard: EventInstance = director._task_guard
			if guard == null:
				unguarded += 1
				print("[m213] seed %d day %d: task unguarded, task %.0fpx from her"
						% [seed_value, day, her.distance_to(director.contact_position())])
			elif _shows(guard.global_position + Vector2(0.0, -24.0), her, 20.0, 24.0):
				seen += 1
			player.free()
			director.free()
		city.free()
	GameState.completed_resistance_steps = saved
	GameState.completed_resistance_alley_tiles = saved_tiles
	print("[m213] guarded tasks %d: unguarded %d, guard body on screen %d" % [placed, unguarded,
			seen])
	t.check(true, "probe ran")

func _rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

func _reachability(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var names := ["whole circle", "leaning bearing", "far end"]
	var asleep := {"through": [0, 0, 0], "passage": [0, 0, 0]}
	var counted := {"through": 0, "passage": 0}
	var unguarded := {"through": [0, 0, 0], "passage": [0, 0, 0]}
	var too_close := [0, 0, 0]
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rngs: Array[RandomNumberGenerator] = []
		for i in 3:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("m213-probe:%d:%d" % [seed_value, i])
			rngs.append(rng)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			var ends := director._alley_ends(mark)
			if ends.is_empty():
				continue
			var kind := "through" if _in_a_through_alley(map, tile) else "passage"
			counted[kind] += 1
			var near: Vector2 = ends[0]
			var far: Vector2 = ends[1]
			var axis := (far - near).normalized() if far.distance_to(near) > 0.5 else Vector2.DOWN
			var outside := near - axis * 48.0
			var touch := mark - axis * TOUCH_SHORT
			for i in 3:
				var guard_at := Vector2.INF
				match i:
					0:
						guard_at = director._draw_guard_position(rngs[i], mark, Vector2.INF,
								min_distance, max_distance)
					1:
						guard_at = director._draw_guard_position(rngs[i], mark, far,
								min_distance, max_distance)
					2:
						guard_at = director._draw_guard_position_near_far_mouth(rngs[i], mark,
								far, min_distance, max_distance, [], Vector2.INF, 0.0, false)
				if guard_at == Vector2.INF:
					unguarded[kind][i] += 1
					continue
				if guard_at.distance_to(mark) < min_distance - 0.5:
					too_close[i] += 1
				if _stays_asleep(robbery, guard_at, [outside, touch, outside]):
					asleep[kind][i] += 1
		director.free()
	for kind in ["through", "passage"]:
		for i in 3:
			print("[m213] %-8s %-16s asleep %4d of %4d (%.0f%%), unguarded %d" % [kind, names[i],
					asleep[kind][i], counted[kind],
					100.0 * asleep[kind][i] / maxf(1.0, counted[kind]), unguarded[kind][i]])
	for i in 3:
		var total: int = asleep["through"][i] + asleep["passage"][i]
		var all: int = counted["through"] + counted["passage"]
		print("[m213] all      %-16s asleep %4d of %4d (%.0f%%), inside 62px of the mark %d"
				% [names[i], total, all, 100.0 * total / maxf(1.0, all), too_close[i]])
	t.check(true, "probe ran")

func _on_screen(t) -> void:
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	GameState.completed_resistance_alley_tiles = []
	var marks_seen := 0
	var guards_seen := 0
	var guards_centre_seen := 0
	var unguarded := 0
	var relocations := 0
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		director._day = 6
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("m213-screen:%d" % seed_value)
		director._rng = rng
		var robbery := EventCatalogue.by_id("alley_robbery")
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			var her := map.tile_to_world(tile)
			var screen := func(p: Vector2) -> bool:
				return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
						and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y
			director.set_sight(screen, screen)
			var mark := director._nearest_alley_within(her)
			if mark == Vector2.INF:
				continue
			relocations += 1
			if _shows(mark, her, 16.0, 16.0):
				marks_seen += 1
			var guard_at := director._guard_position(rng, mark, true, her, true)
			if guard_at == Vector2.INF:
				unguarded += 1
				continue
			if _shows(guard_at, her, 0.0, 0.0):
				guards_centre_seen += 1
			# His body: about 20px either side of his feet and 48px above them.
			if _shows(guard_at + Vector2(0.0, -24.0), her, 20.0, 24.0):
				guards_seen += 1
			var _unused := robbery
		director.free()
	GameState.completed_resistance_alley_tiles = saved_tiles
	print("[m213] relocations %d: mark picture on screen %d, guard centre on screen %d, guard body on screen %d, unguarded %d"
			% [relocations, marks_seen, guards_centre_seen, guards_seen, unguarded])
	t.check(true, "probe ran")

## Whether a box `half_w` by `half_h` around `at` overlaps the unrotated screen around `her`.
func _shows(at: Vector2, her: Vector2, half_w: float, half_h: float) -> bool:
	return absf(at.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x + half_w \
			and absf(at.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y + half_h

func _in_a_through_alley(map: CityMap, tile: Vector2i) -> bool:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			return true
	return false

func _stays_asleep(robbery: EventDef, guard_at: Vector2, legs: Array[Vector2]) -> bool:
	var robber := EventInstance.new()
	robber.setup(robbery, guard_at)
	var woke := false
	for leg in legs.size() - 1:
		var from: Vector2 = legs[leg]
		var to: Vector2 = legs[leg + 1]
		var steps := ceili(from.distance_to(to) / 8.0)
		for s in steps + 1:
			robber.player_at = from.lerp(to, float(s) / float(maxi(steps, 1)))
			robber._process(STEP)
			if not robber.is_waiting():
				woke = true
	robber.free()
	return not woke
