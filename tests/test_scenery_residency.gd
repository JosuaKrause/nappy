@warning_ignore_start("untyped_declaration", "unsafe_property_access", "unsafe_method_access")
extends RefCounted
## Residency is presentation only: coverage, hysteresis, reconstruction, stable identity and RNG.
## The three ground modes schedule the same lazy, nearby preparation; the rest of the suite runs
## in the default.
##
## **A combined suite, for a stated reason**: the guarantee is residency over a whole city. What
## `SceneryResidency` keeps resident is a decision about every consumer the city registers with it
## at once (its ground chunks, its buildings' windows and roofs, its water, its props), and the
## claims are about what a view's movement does to all of them together: coverage with no
## duplicate owner, identity and collision kept across eviction, the city clock shared by new
## chunks, no global RNG consumed. A stand-in for each consumer would only restate what the
## residency hands them, so the real city, built from a cached map, is the thing observed. What each
## consumer does with its own residency (a roof's units, a water surface's clock) is its own
## suite's (`tests/test_scenery_animation.gd`, `tests/test_ground_floor.gd`).
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY := preload("res://scenes/world/city.tscn")
const GroundCells := preload("res://tests/ground_cells.gd")
const RecordingRoofDrawer := preload("res://tests/recording_roof_drawer.gd")
const RoofReads := preload("res://tests/roof_reads.gd")

## The recording drawer each building was handed, building to drawer: what a building drew is read
## off its own, since a building's roof is placed by its own rolls and drawn through
## `Building.roof_drawer`, as the city hands it.
var _drawers := {}

func run(t: TestRunner) -> void:
	for seed_value in [4242, 3265820891]:
		await _test_all_mode(t, seed_value)
		await _test_all_mode_budget(t, seed_value)
		await _test_one_mode(t, seed_value)
		await _test_frame_record(t, seed_value)
		await _test_pending(t, seed_value)
		await _test_residency_follows_the_view(t, seed_value)
		await _test_roof_phase(t, seed_value)

func _view(at: Vector2) -> Rect2:
	return Rect2(at - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2)

## A city built over a run of its own from `seed_value`, every building
## handed a recording roof drawer. Every test builds its own, so none reads what another left.
func _city_for(t: TestRunner, seed_value: int) -> City:
	var city: City = RunCity.with_own_run(CITY, seed_value)
	t.add_child(city)
	city.build(MapCache.of(seed_value))
	_record_the_roofs(city)
	return city

func _free(city: City) -> void:
	_drawers.clear()
	city.free()

func _test_residency_follows_the_view(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	var map := city.map
	var run := city.run
	var home := _view(map.doorstep_world_position())
	var initial := GroundCells.used_cells(city.scenery_ground).size()
	t.check(initial > 0 and initial < map.size.x * map.size.y / 8,
			"boot prepares a nonempty neighborhood, not the entire map")
	_check_coverage(t, city, home)
	var unloaded := 0
	for building in city.buildings():
		if not building.scenery_resident:
			unloaded += 1
			t.check(not building.is_processing(), "unprepared roofs run no animation callbacks")
			t.check(_drawer_of(building).standing().is_empty() and _lit_windows(building) == 0,
					"a distant building has no window/roof preparation")
			t.check(_collision_shape(building) != null and building.shape != null,
					"a distant building keeps its complete collision")
	t.check(unloaded > city.buildings().size() / 2, "most buildings are unprepared at home")
	var lit_in_view := 0
	for resident in city.buildings():
		if resident.scenery_resident:
			lit_in_view += _lit_windows(resident)
	t.check(lit_in_view > 0, "the prepared buildings show lit windows, so an unprepared one showing"
			+ " none says something")
	var building := _a_building_with_a_roof(city)
	var identity := building.get_instance_id()
	var collision := _collision_shape(building)
	var target := _view(building.scenery_bounds().get_center())
	city.scenery.update(target, true)
	# Lived in and powered, so the pictures say which windows the roll lit.
	building.condition = Building.Condition.LIVED_IN
	building.powered = true
	var windows := _window_pictures(building)
	t.check(_lit_windows(building) > 0, "the building watched has lit windows to compare")
	var roof := _drawer_of(building).drawn()
	t.check(not roof.is_empty(), "a prepared building draws a roof")
	t.check(_drawer_of(building).layout().map(_cell_and_picture) == RoofReads.units_of(building).map(_cell_and_picture),
			"the roof a prepared building tells its drawer to draw is the roof that stands in the layer")
	var layers: Array[Building.RoofObject] = []
	for entry in _drawer_of(building).standing():
		layers.append(entry.object)
	var cells := GroundCells.used_cells(city.scenery_ground)
	var chunk_ids := _chunk_ids(city.scenery_ground)
	# Moving the boundary repeatedly by a tile never crosses the wider eviction boundary.
	city.scenery.update(Rect2(target.position + Vector2(32, 0), target.size), true)
	var resident_ids := _chunk_ids(city.scenery_ground)
	for i in 12:
		city.scenery.update(Rect2(target.position + Vector2(32 if i % 2 else 0, 0), target.size), true)
	t.check(_chunk_ids(city.scenery_ground) == resident_ids,
			"repeated load-boundary reversals inside retention cause no allocation or eviction")
	for key: Vector2i in chunk_ids:
		t.check(city.scenery_ground.chunks[key].get_instance_id() == chunk_ids[key],
				"retained chunks preserve their actual allocation")
	var far := _view(map.world_size() - Vector2(100, 100))
	city.scenery.update(far, true)
	t.check(not building.scenery_resident, "leaving the retention boundary evicts the building")
	for layer in layers:
		t.check(not is_instance_valid(layer), "eviction frees roof nodes and their texture references")
	t.check(resident_ids.values().any(func(id: int) -> bool: return not is_instance_valid(instance_from_id(id))),
			"leaving retention frees actual ground chunks")
	for tile in cells:
		if not far.grow(SceneryResidency.RETAIN_MARGIN).intersects(
				SceneryGround.bounds(SceneryGround.key_for(tile))):
			t.check(GroundCells.source_id(city.scenery_ground, tile) == -1, "distant cells have no resident owner")
	building.day = 12
	building.condition = Building.Condition.BOARDED
	building.powered = false
	building.neighbor_window_col = 2
	building.posters = {1: {"kind": 1, "tear": 0, "under": -1, "under_tear": 0, "side": 1}}
	seed(91234)
	var expected_rng := randi()
	seed(91234)
	city.scenery.update(target, true)
	t.check(randi() == expected_rng, "scenery reconstruction consumes no global gameplay RNG")
	t.check(building.get_instance_id() == identity and _collision_shape(building) == collision,
			"residency preserves building identity and its collision resource")
	building.condition = Building.Condition.LIVED_IN
	building.powered = true
	t.check(_window_pictures(building) == windows and _drawer_of(building).drawn() == roof,
			"returning artwork reconstructs the same seeded window and furniture layout")
	building.condition = Building.Condition.BOARDED
	building.powered = false
	_check_roof_ownership(t, city)
	for cycle in 3:
		city.scenery.update(far, true)
		await _run_the_city_clock(t, city, Building.VENT_FRAME_INTERVAL * 1.25)
		city.scenery.update(target, true)
		_check_roof_ownership(t, city)
	t.check(building.day == 12 and building.condition == Building.Condition.BOARDED \
			and not building.powered and building.neighbor_window_col == 2 \
			and building.posters.has(1), "changes while unloaded survive reconstruction")
	_check_coverage(t, city, target)
	var state := CityState.new()
	state.begin_day(map.block_plans, 8)
	city.start_day(state, 8, run.calendar.day_rng(8, "closures"))
	city.scenery.update(far, true)
	_check_coverage(t, city, far)
	city.scenery.update(home, true)
	_check_coverage(t, city, home)
	t.check(building.get_instance_id() == identity and _collision_shape(building) == collision,
			"dawn and relocation do not replace persistent building collision")
	# Clock belongs to the city, so a newly entered shoreline resumes its neighbors' phase.
	await _run_the_city_clock(t, city, 3.75)
	var shore := _view(Vector2(map.world_size().x * 0.5, map.world_size().y + 100))
	city.scenery.update(shore, true)
	var water_count := 0
	for chunk: TileMapLayer in city.scenery_ground.chunks.values():
		for child in chunk.get_children():
			if child is SceneryWater:
				water_count += 1
				t.check(child.elapsed == city.scenery_ground.elapsed and not child.is_processing(),
						"new water chunks share one pausable city phase")
	t.check(water_count > 1, "the phase check covers multiple water chunks")
	_free(city)

func _test_roof_phase(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	var observed := 0
	for building in city.buildings():
		if building.district != GameEnums.BlockPurpose.INDUSTRIAL:
			continue
		var view := _view(building.scenery_bounds().get_center())
		city.scenery.update(view, true)
		if _rotors_of(building).is_empty():
			continue
		for cycle in 3:
			var old_rotors := _rotors_of(building)
			var old_objects := _objects_of(building)
			city.scenery.update(_view(Vector2(-10000, -10000)), true)
			t.check(not building.scenery_resident, "the actual fan owner crosses the eviction boundary")
			for rotor in old_rotors:
				t.check(not is_instance_valid(rotor), "eviction frees the actual moving rotor owner")
			for object in old_objects:
				t.check(not is_instance_valid(object), "eviction frees the actual fan housing owner")
			await _run_the_city_clock(t, city, Building.VENT_FRAME_INTERVAL * 1.25)
			city.scenery.update(view, true)
			t.check(not _rotors_of(building).is_empty(), "returning fan owner reconstructs actual rotors")
			var expected_phase := int(city.scenery_ground.elapsed / Building.VENT_FRAME_INTERVAL) % 2 == 1
			for rotor in _rotors_of(building):
				observed += 1
				t.check(rotor.frame_b == expected_phase,
						"reentered fan rotors resume the shared city clock's phase")
			_check_roof_ownership(t, city)
		break
	t.check(observed > 0, "phase reconstruction checks actual generated city fan rotors")
	_free(city)

func _check_roof_ownership(t: TestRunner, city: City) -> void:
	var owned := {}
	var count := 0
	# The layer the city hands every building to stand its roof art in.
	var entities: Node2D = city.buildings()[0].roof_object_parent
	for building in city.buildings():
		if not building.scenery_resident:
			t.check(_objects_of(building).is_empty() and _rotors_of(building).is_empty(),
					"unloaded buildings retain no external roof objects or rotor textures")
		for object in _objects_of(building):
			owned[object] = true
			t.check(object.get_parent() == entities,
					"resident roof art is rebuilt in the city's y-sorted entity layer")
	for child in entities.get_children():
		if child is Building.RoofObject:
			count += 1
			t.check(owned.has(child), "every entity roof object has a live resident building owner")
	t.check(count > 0 and count == owned.size(), "the ownership check covers actual roof objects")

## Hands every building a recording drawer that also stands each unit through the real one, and
## prepares again the buildings that were prepared at the build, so what each draws from here on is
## recorded. The city handed the real drawer to every building; this is the same member, handed
## again.
func _record_the_roofs(city: City) -> void:
	_drawers.clear()
	for building in city.buildings():
		var drawer := RecordingRoofDrawer.new()
		drawer.real = RoofDrawer.new(city.atlas)
		building.roof_drawer = drawer
		_drawers[building] = drawer
		if building.scenery_resident:
			building.set_scenery_resident(false)
			building.set_scenery_resident(true)

## The first prepared building whose roof draws units, so what it draws is something to compare.
func _a_building_with_a_roof(city: City) -> Building:
	for building in city.buildings():
		if building.scenery_resident and not _drawer_of(building).standing().is_empty():
			return building
	return city.buildings()[0]

## One roof unit as its cell and its picture, the shape two reads of a roof are compared in.
func _cell_and_picture(unit: Dictionary) -> Array:
	return [unit.cell, unit.texture]

func _drawer_of(building: Building) -> RecordingRoofDrawer:
	return _drawers[building]

## The roof objects the building has standing: its draws whose object it has not freed.
func _objects_of(building: Building) -> Array[Building.RoofObject]:
	var objects: Array[Building.RoofObject] = []
	for entry in _drawer_of(building).standing():
		objects.append(entry.object)
	return objects

## The turning rotors the building's standing roof objects carry (the vent housings').
func _rotors_of(building: Building) -> Array[SceneryLayer]:
	var rotors: Array[SceneryLayer] = []
	for object in _objects_of(building):
		if object.rotor != null:
			rotors.append(object.rotor)
	return rotors

## The picture each wall cell's window shows, row-major: the style and which cells are lit in one list.
func _window_pictures(building: Building) -> Array[StringName]:
	var pictures: Array[StringName] = []
	for index in building.columns() * building.wall_tiles():
		pictures.append(building.window_texture(index))
	return pictures

## How many of the building's wall cells show a lit window.
func _lit_windows(building: Building) -> int:
	var lit := [Building.WINDOW_LIT, Building.WINDOW_SHUTTERED_LIT, Building.WINDOW_TALL_LIT]
	var count := 0
	for picture in _window_pictures(building):
		count += int(picture in lit)
	return count

## The physics shape the building keeps for its complete collision, found among its children.
func _collision_shape(building: Building) -> Shape2D:
	for child in building.get_children():
		if child is CollisionShape2D:
			return (child as CollisionShape2D).shape
	return null

## Lets real process frames pass until the city's ground clock has run `seconds` more, under a high
## `Engine.time_scale` so few frames do it. The residency's own per-frame maintenance is paused for
## the stretch, so the view the caller chose is the view it finds again; a clock that stops short fails.
func _run_the_city_clock(t: TestRunner, city: City, seconds: float) -> void:
	var ground := city.scenery_ground
	var until := ground.elapsed + seconds
	var clock := Engine.time_scale
	city.scenery.set_process(false)
	Engine.time_scale = 1000.0
	var frames := 0
	while ground.elapsed < until and frames < 600:
		await city.get_tree().process_frame
		frames += 1
	Engine.time_scale = clock
	city.scenery.set_process(true)
	t.check(ground.elapsed >= until,
			"the city's clock ran its %.2f s within 600 frames (it reached %.2f of %.2f)"
			% [seconds, ground.elapsed, until])

## Lets `count` process frames pass. The caller sits at the start of a frame, before that frame's
## `_process`, whenever it has just awaited one, so each await here is exactly one `_process` of
## every node.
func _frames(city: City, count := 1) -> void:
	for i in count:
		await city.get_tree().process_frame

## The view the city looks at from her doorstep, which is the one a run with no camera keeps: the
## doorstep and the half extent of a screen round it (`Tuning.VIEW_HALF_EXTENT`).
func _home_view(city: City) -> Rect2:
	return Rect2(city.map.doorstep_world_position() - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0)

## Switches an emptied ground to `mode` and prepares the home view again in it.
func _use_mode(city: City, mode: SceneryGround.Mode) -> void:
	city.scenery_ground.clear()
	city.scenery_ground.mode = mode
	city.scenery.update(_home_view(city), true)

## Releases up to `count` regions between the guard and the load boundary of `view`, so the next
## ordinary update has to prepare them: the residency's own view must already be `view`.
func _ring_keys(city: City, view: Rect2, count: int) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for candidate in city.scenery_ground.keys_in(view.grow(SceneryResidency.LOAD_MARGIN)):
		if view.grow(SceneryResidency.GUARD_MARGIN).intersects(SceneryGround.bounds(candidate)):
			continue
		if city.scenery_ground.chunks.has(candidate):
			city.scenery_ground.release(candidate)
		keys.append(candidate)
		if keys.size() == count:
			break
	return keys

## What ALL and ONE build: the region as one layer, so one renderer quadrant and one water surface.
func _all_prepared(ground: SceneryGround, keys: Array[Vector2i]) -> bool:
	return keys.all(func(key: Vector2i) -> bool: return ground.chunks.has(key))

func _check_whole_layout(t: TestRunner, city: City, key: Vector2i) -> void:
	var layer: TileMapLayer = city.scenery_ground.chunks[key]
	var surfaces := 0
	for child in layer.get_children():
		surfaces += int(child is SceneryWater)
	t.check(layer.rendering_quadrant_size >= SceneryGround.CHUNK_TILES and surfaces <= 1,
			"a whole-region mode builds one renderer quadrant and at most one water surface")

func _test_all_mode(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	_use_mode(city, SceneryGround.Mode.ALL)
	var ground := city.scenery_ground
	var view := _home_view(city)
	var keys := _ring_keys(city, view, 3)
	t.check(keys.size() == 3, "the mode-1 check has three actual load-ring regions to prepare")
	# The soft budget is wall-clock time, and three whole regions take about that long on their
	# own, so under it the third region spills into the next frame whenever the machine is a
	# little slow (a cold start, another process on the cores). What this check is about is the
	# mode — a region is prepared whole, never stepped — so the update runs with room for all
	# three; the budget's own spill-over is `_test_all_mode_budget`'s, which a one-microsecond
	# budget makes countable without timing anything.
	city.scenery.budget_usec = 1_000_000_000
	var prepared := ground.chunks.keys()
	city.scenery.update(view)
	city.scenery.budget_usec = SceneryResidency.BUDGET_USEC
	var all_whole := true
	for key in keys:
		all_whole = all_whole and ground.chunks.has(key)
	t.check(all_whole and _added(ground, prepared) == keys.size(),
			"mode 1 prepares every needed region whole in the update that needs it")
	# Nothing waiting: a real frame passes and the residency's own maintenance, which runs an
	# update whenever work waits, prepares nothing more.
	var after := ground.chunks.keys()
	await _frames(city)
	t.check(ground.pending.is_empty() and _added(ground, after) == 0,
			"mode 1 leaves nothing partly built and nothing waiting")
	for key in keys:
		_check_chunk(t, city, key)
		_check_whole_layout(t, city, key)
	_free(city)

## Mode 1 keeps the soft budget, and what does not fit is budgeted again in each following
## frame rather than prepared all at once in the next. *(2026-10-03: "if we keep the 2ms budget then
## it also should apply to the next frame and so on".)* A budget one microsecond long makes every
## update one job, so the spill-over is countable without timing anything.
func _test_all_mode_budget(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	_use_mode(city, SceneryGround.Mode.ALL)
	var ground := city.scenery_ground
	var scenery := city.scenery
	var view := _home_view(city)
	var keys := _ring_keys(city, view, 5)
	t.check(keys.size() == 5, "the budget check has five actual load-ring regions to prepare")
	scenery.budget_usec = 1
	var counts: Array[int] = []
	await _frames(city)
	# The first update is the one that finds the ring; the residency's own per-frame maintenance
	# then keeps going while work waits, one real frame at a time.
	var prepared := ground.chunks.keys()
	scenery.update(view)
	counts.append(_added(ground, prepared))
	for frame in keys.size() + 1:
		prepared = ground.chunks.keys()
		await _frames(city)
		if _added(ground, prepared) == 0:
			break
		counts.append(_added(ground, prepared))
	scenery.budget_usec = SceneryResidency.BUDGET_USEC
	var all_whole := true
	for key in keys:
		all_whole = all_whole and ground.chunks.has(key)
	prepared = ground.chunks.keys()
	await _frames(city)
	t.check(all_whole and _added(ground, prepared) == 0, "every spilled region is prepared in the end")
	t.check(counts.size() == keys.size() and counts.all(func(n: int) -> bool: return n == 1),
			"each frame's update prepares only what its own budget allows, frame after frame "
			+ "(regions per update: %s)" % [counts])
	_free(city)

func _test_one_mode(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	_use_mode(city, SceneryGround.Mode.ONE)
	var ground := city.scenery_ground
	var scenery := city.scenery
	var view := _home_view(city)
	var keys := _ring_keys(city, view, 3)
	t.check(keys.size() == 3, "the mode-2 check has three actual load-ring regions to prepare")
	# A real frame since the ground was emptied, so the process frame is a new one.
	await _frames(city)
	var prepared := ground.chunks.keys()
	scenery.update(view)
	t.check(_added(ground, prepared) == 1 and ground.pending.is_empty()
			and not _all_prepared(ground, keys),
			"mode 2 prepares one whole region in a frame and the others wait, none half built")
	scenery.update(view)
	t.check(_added(ground, prepared) == 1,
			"repeating an update in the same process frame prepares no second region")
	for frame in keys.size() - 1:
		# The update above ran before this frame's own `_process`, in the same process frame, so
		# the fence holds that one back: the first region to follow comes a frame later.
		await _frames(city, 2 if frame == 0 else 1)
		t.check(_added(ground, prepared) == frame + 2,
				"each following frame prepares exactly one more waiting region")
	var all_whole := true
	for key in keys:
		all_whole = all_whole and ground.chunks.has(key)
		_check_chunk(t, city, key)
		_check_whole_layout(t, city, key)
	prepared = ground.chunks.keys()
	await _frames(city)
	t.check(all_whole and _added(ground, prepared) == 0, "every waiting region is prepared in turn")
	# A guard preparation spends the frame: the ring region waits rather than making it two.
	var waiting := _ring_keys(city, view, 1)
	var close := SceneryGround.key_for(city.map.world_to_tile(view.get_center()))
	ground.release(close)
	await _frames(city)
	prepared = ground.chunks.keys()
	scenery.update(view)
	t.check(ground.chunks.has(close), "a region about to come into view is prepared at once by the guard")
	t.check(_added(ground, prepared) == 1 and not ground.chunks.has(waiting[0]),
			"a frame that needed the guard prepares no second, ordinary region")
	await _frames(city, 2)
	t.check(ground.chunks.has(waiting[0]), "the waiting region follows in the next frame")
	# A relocation prepares its whole destination before it is seen, in every mode.
	var away := Rect2(view.position + Vector2(SceneryResidency.LOAD_MARGIN * 3, 0), view.size)
	scenery.update(away)
	var covered := true
	for key in ground.keys_in(away.grow(SceneryResidency.LOAD_MARGIN)):
		covered = covered and ground.chunks.has(key)
	t.check(covered, "a relocation in mode 2 prepares the whole destination before returning")
	_free(city)

## Under the frame record the scenery queue's update is charged to `scenery`, counts the jobs it
## ran by kind and the guard's preparations apart, and keeps what it spent past its budget.
func _test_frame_record(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	_use_mode(city, SceneryGround.Mode.ALL)
	var scenery := city.scenery
	var view := _home_view(city)
	var keys := _ring_keys(city, view, 2)
	var close := SceneryGround.key_for(city.map.world_to_tile(view.get_center()))
	city.scenery_ground.release(close)
	var record := FrameRecord.new()
	var ledger := FrameLedger.new(4)
	record.start(ledger)
	scenery.timing = record
	ledger.process_start(Time.get_ticks_usec())
	scenery.budget_usec = 1
	scenery.update(view)
	scenery.budget_usec = SceneryResidency.BUDGET_USEC
	# The frame is kept, then the next one begins: the ledger hands a kept frame out as a row.
	ledger.keep = true
	ledger.process_end(Time.get_ticks_usec())
	record.stop()
	scenery.timing = FrameTiming.new()
	ledger.process_start(Time.get_ticks_usec())
	var rows := ledger.rows()
	t.check(keys.size() == 2, "the record check has two actual load-ring regions to prepare")
	t.check(rows.size() == 1, "the kept frame is one row of the ledger")
	var row: PackedInt64Array = rows[0] if rows.size() == 1 else PackedInt64Array()
	row.resize(FrameLedger.WIDTH)
	var counter := func(which: int) -> int: return row[FrameLedger.FIRST_COUNTER + which]
	t.check(counter.call(FrameLedger.GUARD_PREPARATIONS) >= 1,
			"the guard's synchronous preparation is counted apart")
	t.check(counter.call(FrameLedger.JOBS_GROUND) == 1,
			"a one-microsecond budget lets the queue run its one job, counted as ground")
	t.check(counter.call(FrameLedger.SCENERY_UPDATES) == 1
			and counter.call(FrameLedger.SCENERY_OVER_BUDGET) > 0,
			"the update says how far past its budget it ran")
	var scenery_usec := row[FrameLedger.FIRST_BUCKET + FrameRecord.SCENERY]
	t.check(scenery_usec > 0 and scenery_usec >= counter.call(FrameLedger.SCENERY_OVER_BUDGET),
			"the update's time is charged to scenery, and covers its spill-over")
	scenery.update(view)
	_free(city)

func _test_pending(t: TestRunner, seed_value: int) -> void:
	var city := _city_for(t, seed_value)
	_use_mode(city, SceneryGround.Mode.STEPPED)
	var ground := city.scenery_ground
	var key := SceneryGround.key_for(city.map.size - Vector2i(8, 8))
	if ground.chunks.has(key):
		ground.release(key)
	var used := GroundCells.used_cells(ground).size()
	t.check(not ground.prepare_step(key), "one step leaves a ground region unfinished")
	var layer: TileMapLayer = ground.pending[key].layer
	var identity := layer.get_instance_id()
	t.check(not ground.chunks.has(key) and GroundCells.used_cells(ground).size() == used,
			"unfinished ground is excluded from every resident-cell query")
	t.check(layer.is_visible_in_tree(), "off-screen preparation keeps renderer commands alive")
	ground.prepare_step(key)
	t.check(ground.pending[key].layer.get_instance_id() == identity,
			"resuming preparation keeps one owner for the unfinished region")
	# The residency cancels a job whose region leaves the retention ring; cancelling frees the
	# unfinished layer rather than publishing its cells.
	ground.cancel(key)
	t.check(not ground.pending.has(key) and not is_instance_valid(layer),
			"cancelling an unfinished region frees its state rather than publishing stale cells")
	ground.prepare_step(key)
	ground.prepare(key)
	t.check(ground.chunks.has(key) and not ground.pending.has(key),
			"synchronous guard completion promotes the existing pending owner")
	_check_chunk(t, city, key)
	ground.release(key)
	ground.prepare_step(key)
	layer = ground.pending[key].layer
	ground.repaint()
	t.check(ground.pending.is_empty() and not is_instance_valid(layer),
			"route-tint repaint discards pending jobs with old ground inputs")
	ground.prepare_step(key)
	layer = ground.pending[key].layer
	city.scenery.update(_home_view(city), true)
	t.check(not ground.pending.has(key) and not is_instance_valid(layer),
			"out-of-range movement cancels and frees unfinished regions")
	# Choose an actual load-ring region and remove it so ordinary maintenance must step it.
	var view := _home_view(city)
	for candidate in ground.keys_in(view.grow(SceneryResidency.LOAD_MARGIN)):
		if view.grow(SceneryResidency.GUARD_MARGIN).intersects(SceneryGround.bounds(candidate)):
			continue
		if ground.chunks.has(candidate):
			ground.release(candidate)
		key = candidate
		break
	city.scenery.update(view)
	t.check(ground.pending.has(key), "ordinary approach starts a stepped job")
	if ground.pending.has(key):
		var progress: int = ground.pending[key].step
		var pending_id: int = ground.pending[key].layer.get_instance_id()
		city.scenery.update(view)
		t.check(ground.pending[key].step == progress,
				"repeated updates in one process frame cannot drain the ground job")
		var away := view
		# Put this candidate between the load and retention boundaries, while preserving size.
		away.position.x = SceneryGround.bounds(key).end.x + SceneryResidency.LOAD_MARGIN + 1
		city.scenery.view = away
		city.scenery.update(away)
		t.check(ground.pending.has(key) and ground.pending[key].step == progress \
				and ground.pending[key].layer.get_instance_id() == pending_id,
				"unfinished regions pause with the same allocation inside the retention ring")
		city.scenery.view = view
		ground.cancel(key)
		city.scenery.update(view)
		t.check(not ground.pending.has(key) and not ground.chunks.has(key),
				"canceling a job cannot bypass its region's process-frame step fence")
	city.scenery.update(Rect2(SceneryGround.bounds(key).get_center() - view.size / 2,
			view.size), true)
	t.check(not ground.pending.has(key) and ground.chunks.has(key),
			"camera relocation completes pending destination ground before returning")
	_check_chunk(t, city, key)
	ground.release(key)
	ground.prepare_step(key)
	layer = ground.pending[key].layer
	ground.configure(city.map, city.scenery_ground_source, ground.tile_set)
	t.check(ground.pending.is_empty() and not is_instance_valid(layer),
			"day/reset configuration discards every unfinished allocation")
	city.scenery.update(_home_view(city), true)
	_free(city)

## The instance id of each resident ground region's layer, by region key: what the ground has
## actually allocated, so a region freed and laid again shows a different id.
func _chunk_ids(ground: SceneryGround) -> Dictionary:
	var ids := {}
	for key: Vector2i in ground.chunks:
		ids[key] = ground.chunks[key].get_instance_id()
	return ids

## How many regions the ground gained since `before` (its resident keys then), or -1000 when it also
## lost one, so an eviction in the same update cannot hide a missing or extra preparation.
func _added(ground: SceneryGround, before: Array) -> int:
	if not before.all(func(key: Vector2i) -> bool: return ground.chunks.has(key)):
		return -1000
	return ground.chunks.size() - before.size()

func _check_chunk(t: TestRunner, city: City, key: Vector2i) -> void:
	for y in range(key.y * SceneryGround.CHUNK_TILES, (key.y + 1) * SceneryGround.CHUNK_TILES):
		for x in range(key.x * SceneryGround.CHUNK_TILES, (key.x + 1) * SceneryGround.CHUNK_TILES):
			var tile := Vector2i(x, y)
			var source := city.scenery_ground_source(tile)
			if source == GroundTiles.WATER:
				t.check(GroundWater.at(city.scenery_ground, tile), "completed region preserves separate water cells")
			else:
				t.check(GroundCells.source_id(city.scenery_ground, tile) == source,
						"completed region matches the current independent source lookup")
				if source >= 0:
					t.check(GroundCells.atlas_coords(city.scenery_ground, tile) == GroundLayers.atlas_coords_for(
							source, city.map.seed_used, tile, city.scenery_ground.tile_set),
							"completed region preserves seeded atlas selection")

func _check_coverage(t: TestRunner, city: City, view: Rect2) -> void:
	var lo := Vector2i((view.position / Tuning.TILE_SIZE).floor())
	var hi := Vector2i((view.end / Tuning.TILE_SIZE).ceil())
	var wrong := 0
	var checked := 0
	for y in range(lo.y, hi.y):
		for x in range(lo.x, hi.x):
			var tile := Vector2i(x, y)
			var source := city.scenery_ground_source(tile)
			if source == GroundTiles.WATER:
				wrong += int(not GroundWater.at(city.scenery_ground, tile))
			elif source >= 0:
				wrong += int(GroundCells.source_id(city.scenery_ground, tile) != source)
				checked += 1
	t.check(checked > 0 and wrong == 0, "visible ground has its current source without gaps")
	for building in city.buildings():
		if building.scenery_bounds().intersects(view):
			t.check(building.scenery_resident, "every intersecting building is prepared")
