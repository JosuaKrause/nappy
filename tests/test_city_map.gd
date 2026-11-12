extends RefCounted
## A city map's copy (`CityMap.copy()`): that it is a city the generator's guarantees hold on, that
## it answers every question the map it was copied from answers, and that nothing either map is
## then handed reaches the other. And its capture (`CityMap.capture()`, `restored()`): that a map
## restored from what a map captured captures the same facts again, for a generated map, its copy
## and an authored scene's saved context.
##
## **Real generated maps, because a copy is only as lossless as the fields generation fills**: a
## hand-drawn map leaves the block plans, the zones, the regions and the landmarks empty, and an
## empty field copies trivially whether `copy()` carries it or not. This is a direct test of the city
## map, on the cities the generator builds.
##
## **Two comparisons, and the second is why the suite reads members.** The first asks both maps the
## questions the game asks them, through their methods: every tile's ground and today's record, the
## streets, the lots, the landmarks, the calm, and each block's purpose on every day of a run. The
## second compares every member each map declares, private ones included, member by member and into
## the plans, layouts and records they hold: a field that `copy()` forgets to carry is a field no
## method may happen to ask about on these seeds, and only this comparison fails on it, for a field
## the states this suite builds fill: a generated map as generated and repainted, one in the middle
## of a day with holds, seals, a body and tree pits, one in act III with a street closed and a park
## fenced, and an authored scene's map with its stretch and dawn ground. A new field empty in all
## of those compares equal by default and is not guarded. Not compared: the world a map is drawn in, its navigator and its movers' moves,
## which a copy starts without (`copy()`'s doc), the street lattice, compared by its segments, and
## the cache of tiles by type, which fills on the first ask.

const SEEDS: Array[int] = [4242, 1, 77]

## The authored scene whose city is copied, for the fields only a recipe fills.
const SCENE := "res://scene-recipes/task-07-package.json"

## What the member comparison leaves out, with `copy()`'s doc saying why for each.
const _NOT_COMPARED: Array[String] = ["world", "_navigator", "moves", "separation", "network",
		"_tiles_by_type"]

## How far apart the tiles are that `_answers()` asks one tile at a time, each way.
const _STRIDE := 3

## Every layer a mover can be stopped by, so `ground_for()` lays out the whole of today's record.
const _ALL_LAYERS := Mover.GROUND | Mover.POSTS | Mover.TODAY

func run(t: TestRunner) -> void:
	for seed_value in SEEDS:
		var original := CityGenerator.generate(seed_value)
		_test_a_copy_keeps_the_generators_guarantees(t, original, seed_value)
		_test_a_copy_answers_what_the_map_answers(t, original, seed_value)
		_test_a_copy_taken_during_a_day_carries_the_days_record(t, original, seed_value)
		_test_what_one_map_is_handed_leaves_the_other_alone(t, original, seed_value)
		_test_a_copy_taken_in_act_three_carries_the_closures_and_the_fence(t, original, seed_value)
		_test_a_restored_map_captures_what_it_was_restored_from(t, original, seed_value)
	_test_a_copy_of_an_authored_scene_map_carries_its_recipe(t)
	_test_a_saved_context_restores_and_captures_the_same(t)
	_test_a_map_with_no_calm_ground_says_none(t)

## A generated map, and its copy, capture the same facts, and the map restored from them captures
## them again: a fact `capture()` names and `restored()` drops, or reads under another name, fails
## here rather than in the draft tool that saves a scene.
func _test_a_restored_map_captures_what_it_was_restored_from(t: TestRunner, original: CityMap,
		seed_value: int) -> void:
	var facts := _comparable(original.capture())
	t.check(not (facts["block_plans"] as Dictionary).is_empty(),
			"seed %d: the capture holds the block arcs" % seed_value)
	t.check(_comparable(original.copy().capture()) == facts,
			"seed %d: the copy captures what the map captures" % seed_value)
	var restored := CityMap.restored(original.capture())
	t.check(_comparable(restored.capture()) == facts,
			"seed %d: the restored map captures what it was restored from" % seed_value)

## An authored scene's saved context restored, saved again and restored once more saves the same
## context, through the recipe file's form (`RecipeCityContext`) as well as the map's own.
func _test_a_saved_context_restores_and_captures_the_same(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var map := RecipeCityContext.restore(data["context"])
	var facts := _comparable(map.capture())
	t.check(_comparable(CityMap.restored(map.capture()).capture()) == facts,
			"the scene's restored map captures what it was restored from")
	var saved := RecipeCityContext.capture(map)
	t.check(RecipeCityContext.validate(saved).is_empty(), "the saved context passes validation")
	t.check(RecipeCityContext.capture(RecipeCityContext.restore(saved)) == saved,
			"the saved context restores and saves the same")

## A capture with each block's arc written out as its steps, so two captures compare by value
## rather than by which `BlockPlan` each holds.
func _comparable(facts: Dictionary) -> Dictionary:
	var arcs := {}
	var plans: Dictionary = facts["block_plans"]
	for block: Vector2i in plans:
		var plan: BlockPlan = plans[block]
		var steps: Array = [plan.forced_open_day()]
		for step in plan.steps_in_order():
			steps.append([step.purpose, step.from_day, step.cause])
		arcs[block] = steps
	var comparable := facts.duplicate()
	comparable["block_plans"] = arcs
	return comparable

## A map no day has marked calm ground on has nothing to count, so its summary says none.
func _test_a_map_with_no_calm_ground_says_none(t: TestRunner) -> void:
	var map := CityMap.new(Vector2i(8, 8))
	t.check(map.calm_blocks_now().is_empty() and map.calm_summary(CityState.new()) == "none",
			"a map with no calm blocks summarizes its calm ground as none")

## The copy of a generated city is one `CityGenerator.validate()` passes, every guarantee of it: the
## calm blocks, the home, the routes to the parks.
func _test_a_copy_keeps_the_generators_guarantees(t: TestRunner, original: CityMap, seed_value: int) -> void:
	var problems := CityGenerator.validation_problems(original.copy())
	t.check(problems.is_empty(), "seed %d: the copy passes every guarantee (%s)" % [seed_value, problems])

func _test_a_copy_answers_what_the_map_answers(t: TestRunner, original: CityMap, seed_value: int) -> void:
	var twin := original.copy()
	t.check(twin != original, "seed %d: the copy is another map" % seed_value)
	_check_the_same(t, original, twin, "seed %d, as generated" % seed_value)
	# And the same after a day's repaint, on each map: what the plans and layouts paint is the same.
	for day: int in [8, Tuning.RUN_LENGTH_DAYS]:
		var map := original.copy()
		var copied := map.copy()
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		var other := CityState.new()
		other.begin_day(copied.plans_by_block(), day)
		map.repaint(state)
		copied.repaint(other)
		_check_the_same(t, map, copied, "seed %d, repainted for day %d" % [seed_value, day])

## A map in the middle of a day, the day's records on it, copies with every record carried: the
## closures, the soft seals, a body, the holds, the emptied tree pits, and a handover still waiting
## for the next repaint.
func _test_a_copy_taken_during_a_day_carries_the_days_record(t: TestRunner, original: CityMap,
		seed_value: int) -> void:
	var map := original.copy()
	var street := _a_street_tile(map)
	var segment := map.street_network().segment_containing(street)
	map.hold_segment(segment.key(), HeldStreets.Why.SEAL)
	map.seal_soft_tile(street)
	var body: Array[Vector2i] = [street + Vector2i.RIGHT]
	map.obstruct_tiles(7, body)
	var pits: Array[Vector2i] = [street]
	map.set_closure_tree_pits(pits)
	var fallen: Array[Vector2i] = [street + Vector2i.LEFT]
	map.set_seal_tree_pits(fallen)
	var spent: Array[Vector2i] = [map.calm_blocks_now()[0]]
	map.set_spent_calm(spent)
	var twin := map.copy()
	_check_the_same(t, map, twin, "seed %d, during a day" % seed_value)
	# The handover is carried too: both maps' next repaint shuts the same calm.
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), 2)
	var other := CityState.new()
	other.begin_day(twin.plans_by_block(), 2)
	map.repaint(state)
	twin.repaint(other)
	_check_the_same(t, map, twin, "seed %d, the next repaint" % seed_value)
	# And a body the copy carries is the copy's to give back.
	twin.release_obstruction(7)
	t.check(not twin.is_obstructed(body[0]) and map.is_obstructed(body[0]),
			"seed %d: a body given back on the copy still stands on the map" % seed_value)

## Act III's records: a map with a street closed and one park fenced (a repaint in act III with a
## spent calm area, `fenced_park` set), and the fence handed over again for the next repaint, copies
## with the closures, the fence and its handover carried. The fence is checked by name besides the
## member comparison, so a copy that drops it fails on a check that says what.
func _test_a_copy_taken_in_act_three_carries_the_closures_and_the_fence(t: TestRunner, original: CityMap,
		seed_value: int) -> void:
	var day := 9
	var map := original.copy()
	var spent: Array[Vector2i] = [map.calm_blocks_now()[0]]
	map.set_spent_calm(spent)
	map.set_fenced_park_state(Vector2i(-1, -1), 0, Tuning.act_for_day(day))
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), day)
	map.repaint(state)
	var street := _a_street_tile(map)
	var closures: Array[RoadClosure] = [RoadClosure.new(RoadClosure.Kind.ROADWORKS,
			map.street_network().segment_containing(street))]
	map.close_streets(closures)
	map.set_fenced_park_state(map.fenced_park_block(), map.fenced_park_act, Tuning.act_for_day(day))
	t.check(map.fenced_park_block().x >= 0 and map.is_closed(street),
			"seed %d: the act III map has a fenced park and a closed street" % seed_value)
	var twin := map.copy()
	t.check(twin.fenced_park_block() == map.fenced_park_block()
			and twin.fenced_park_act == map.fenced_park_act,
			"seed %d: the copy has the same fenced park" % seed_value)
	_check_the_same(t, map, twin, "seed %d, in act III" % seed_value)
	# The handover is carried: both maps' next repaint keeps the same fence standing.
	var next := CityState.new()
	next.begin_day(map.plans_by_block(), day + 1)
	var other := CityState.new()
	other.begin_day(twin.plans_by_block(), day + 1)
	map.repaint(next)
	twin.repaint(other)
	_check_the_same(t, map, twin, "seed %d, the next repaint in act III" % seed_value)

## An authored scene's city (`RecipeCityBuilder.build()`) copies with what only a recipe fills: its
## saved dawn ground, its stretch and the stretch being active, its tree moves and context.
func _test_a_copy_of_an_authored_scene_map_carries_its_recipe(t: TestRunner) -> void:
	var data: Dictionary = SceneRecipe.load_file(SCENE).data
	var map: CityMap = RecipeCityBuilder.build(data).map
	t.check(map.stretch_active and map.has_recipe_dawn_ground(),
			"the authored map has an active stretch and saved dawn ground")
	var twin := map.copy()
	t.check(twin.stretch_active and twin.recipe_dawn_tiles == map.recipe_dawn_tiles,
			"the copy of an authored map keeps its stretch active and its dawn ground")
	_check_the_same(t, map, twin, "the authored scene map")

## Whatever the copy is handed, painted, closed or stood on leaves the map it was copied from as it
## was, and the other way round. Each map is compared with what it answered and held before (a
## snapshot of plain data, `_snapshot()`), not with another copy, which would share whatever the
## two maps wrongly shared.
func _test_what_one_map_is_handed_leaves_the_other_alone(t: TestRunner, original: CityMap,
		seed_value: int) -> void:
	var map := original.copy()
	var before := _snapshot(map)
	var twin := map.copy()
	_hand_a_day_to(twin)
	_check_alike(t, before, _snapshot(map),
			"seed %d, the map after its copy was handed a day" % seed_value)
	var other := map.copy()
	var copied := _snapshot(other)
	_hand_a_day_to(map)
	_check_alike(t, copied, _snapshot(other),
			"seed %d, the copy after the map it was taken from was handed a day" % seed_value)

# ------------------------------------------------------------------- helpers ---

## Paints, closes, holds, seals, stands a body on and replans a map, through its methods: every
## kind of write a day makes.
func _hand_a_day_to(map: CityMap) -> void:
	var street := _a_street_tile(map)
	map.set_tile(street + Vector2i.DOWN, GameEnums.TileType.BUILDING)
	map.hold_segment(map.street_network().segment_containing(street).key(), HeldStreets.Why.SEAL)
	map.seal_soft_tile(street)
	var body: Array[Vector2i] = [street + Vector2i.RIGHT]
	map.obstruct_tiles(11, body)
	var closures: Array[RoadClosure] = [RoadClosure.new(RoadClosure.Kind.ROADWORKS,
			map.street_network().segment_containing(street))]
	map.close_streets(closures)
	var pits: Array[Vector2i] = [street]
	map.set_seal_tree_pits(pits)
	var first_calm := map.calm_blocks_now()[0]
	var plan := map.plans_by_block()[first_calm] as BlockPlan
	plan.then(GameEnums.BlockPurpose.REQUISITIONED, 3, GameEnums.BlockCause.SCHEDULED)
	var spent: Array[Vector2i] = [first_calm]
	map.set_spent_calm(spent)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), Tuning.RUN_LENGTH_DAYS)
	map.repaint(state)

## The middle of the first segment's carriageway that is still a street on `map`, so a day's
## writes have a real street to land on.
func _a_street_tile(map: CityMap) -> Vector2i:
	for segment in map.street_network().segments():
		if not map.has_street(segment.key()):
			continue
		var tile := segment.tile_rect().get_center()
		if map.is_street(tile) and map.is_walkable(tile):
			return tile
	return Vector2i.ZERO

## Both comparisons of this suite's header, each a check of its own.
func _check_the_same(t: TestRunner, expected: CityMap, actual: CityMap, situation: String) -> void:
	_check_alike(t, _snapshot(expected), _snapshot(actual), situation)

## What `map` answers and what it holds, `_answers()` and `_members()`, as plain data of the
## suite's own that no later write to `map` reaches.
func _snapshot(map: CityMap) -> Array:
	return [_plain(_answers(map)), _members(map)]

## The two checks of `_check_the_same()`, on two snapshots.
func _check_alike(t: TestRunner, expected: Array, actual: Array, situation: String) -> void:
	var asked: Dictionary = expected[0]
	var answered: Dictionary = actual[0]
	var differing: Array[String] = []
	for question: String in asked:
		if asked[question] != answered.get(question):
			differing.append(question)
	t.check(differing.is_empty(), "%s: the two maps answer every question alike (differ: %s)"
			% [situation, differing])
	var held: Dictionary = expected[1]
	var copied: Dictionary = actual[1]
	var unlike: Array[String] = []
	for member: String in held:
		if held[member] != copied.get(member):
			unlike.append(member)
	t.check(unlike.is_empty() and held.size() == copied.size(),
			"%s: the two maps hold every member alike (differ: %s)" % [situation, unlike])

## What the game asks a city map, keyed by the question, each answer plain data. The ground and
## today's record are read for every tile at once (`ground_for()`, `walk_tiles()`); the questions
## asked one tile at a time are asked of every `_STRIDE`th tile each way, a sample spread over the
## whole map that keeps the suite to seconds, and the member comparison covers every tile besides.
func _answers(map: CityMap) -> Dictionary:
	var found := {}
	found["ground and today's record"] = map.ground_for(Mover.of(_ALL_LAYERS))
	found["tile types"] = map.walk_tiles()
	var streets := PackedByteArray()
	var shut := PackedByteArray()
	var held := PackedByteArray()
	var pits := PackedByteArray()
	for y in range(0, map.size_in_tiles().y, _STRIDE):
		for x in range(0, map.size_in_tiles().x, _STRIDE):
			var tile := Vector2i(x, y)
			streets.append(int(map.is_street(tile)) + 2 * int(map.is_carriageway(tile)) \
					+ 4 * int(map.is_crossing(tile)))
			shut.append(int(map.is_shut(tile)) + 2 * int(map.is_closed(tile)))
			held.append(int(map.is_held_at(tile)))
			pits.append(int(map.is_tree_pit_emptied(tile)))
	found["streets"] = streets
	found["shut and closed"] = shut
	found["held"] = held
	found["emptied tree pits"] = pits
	found["blocked segments"] = map.blocked_segments()
	var segments := []
	for segment in map.street_network().segments():
		var key := segment.key()
		segments.append([key, map.has_street(key), map.is_hard_blocker(key), map.is_held(segment),
				RegionPlanner.ground_region_of(map, segment)])
	found["segments"] = segments
	var corridors := []
	for corridor in Tuning.CITY_BLOCKS.x + 1:
		corridors.append([map.is_main_road(true, corridor), map.is_main_road(false, corridor)])
	found["main road"] = corridors
	var lots := []
	for y in Tuning.CITY_BLOCKS.y:
		for x in Tuning.CITY_BLOCKS.x:
			var block := Vector2i(x, y)
			lots.append([map.lot_rect(block), map.anchor_of(block), map.calm_lot_blocks(block),
					map.starting_purpose(block)])
	found["lots"] = lots
	var arcs := []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		var purposes := []
		for block: Vector2i in map.blocks_with_plans():
			purposes.append([block, state.purpose_of(map.plans_by_block(), block),
					state.is_forced_open(block)])
		purposes.sort()
		arcs.append(purposes)
	found["each block's purpose each day"] = arcs
	found["home"] = [map.home_world_position(), map.doorstep_world_position()]
	found["power station"] = [map.has_power_station(), map.power_station_door_position(),
			map.power_station_door_street().key() if map.has_power_station() else Vector3i.ZERO]
	found["calm tiles"] = map.calm_tiles()
	found["home to the nearest calm"] = map.home_to_nearest_calm()
	found["standable"] = map.count_standable()
	found["regions with calm"] = RegionPlanner.regions_with_calm(map)
	return found

## Every member `map` declares, by name, each as plain data (`_plain()`), less `_NOT_COMPARED`, and
## its street lattice as its segments' keys.
func _members(map: CityMap) -> Dictionary:
	var found := _plain_members(map, _NOT_COMPARED)
	var keys := []
	for segment in map.street_network().segments():
		keys.append(segment.key())
	found["network"] = keys
	return found

## `object`'s script members, each as plain data, less `skipped`.
func _plain_members(object: Object, skipped: Array[String] = []) -> Dictionary:
	var found := {}
	for property in object.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var name: String = property.name
		if name in skipped:
			continue
		found[name] = _plain(object.get(name))
	return found

## `value` with every object in it replaced by its members (`_plain_members()`), so two values
## compare equal exactly when they hold the same data, whichever objects hold it, and every array,
## dictionary and packed array in it new, so no later write to what it was read from reaches it.
## Godot shares a packed array by reference, so each packed type is copied through its own typed
## name.
func _plain(value: Variant) -> Variant:
	if value is PackedByteArray:
		return (value as PackedByteArray).duplicate()
	if value is PackedInt32Array:
		return (value as PackedInt32Array).duplicate()
	if value is PackedInt64Array:
		return (value as PackedInt64Array).duplicate()
	if value is PackedFloat32Array:
		return (value as PackedFloat32Array).duplicate()
	if value is PackedFloat64Array:
		return (value as PackedFloat64Array).duplicate()
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()
	if value is PackedVector2Array:
		return (value as PackedVector2Array).duplicate()
	if value is PackedVector3Array:
		return (value as PackedVector3Array).duplicate()
	if value is PackedVector4Array:
		return (value as PackedVector4Array).duplicate()
	if value is PackedColorArray:
		return (value as PackedColorArray).duplicate()
	if value is Object:
		return _plain_members(value as Object)
	if value is Array:
		var items := []
		for item: Variant in value:
			items.append(_plain(item))
		return items
	if value is Dictionary:
		var entries := {}
		for key: Variant in value:
			entries[key] = _plain(value[key])
		return entries
	return value
