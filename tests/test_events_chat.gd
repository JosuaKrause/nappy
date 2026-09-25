extends RefCounted
## The one row whose whole mechanic is time under compulsion rather than a field: entering
## `detain_radius` locks the player's own movement input, and what she is charged while it holds
## depends on the baby's state rather than on anything the def can see. An `EventManager` is built
## by hand -- nothing here needs a real `City` -- and its trigger (`_check_detentions()`) and its
## per-frame handoff (`_tell_them_where_she_is()`) are driven directly, the same shape
## `test_danger.gd` drives `_warn_about_the_ground_she_is_on()` in.
##
## Plus the van: `abduction` draws its own scripted victim rather than touching a real `CrowdAgent`
## (docs/TODO.md, M56) -- drawing and telemetry only, so a data-level rig can drive the whole scene
## by hand -- and `heat_response = HUNTS`, which turns the same row into a pursuer past
## `Tuning.HEAT_HUNTS_LEVEL` (docs/EVENTS.md, "The heat"), stated against the fully heated copy.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again".

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_conversation_locks_her_and_releases(t)
	_test_a_conversation_prices_by_the_babys_state(t)
	_test_a_conversation_only_starts_inside_detain_radius(t)
	_test_a_conversation_happens_once_per_instance(t)
	_test_the_take_begins_only_once_she_is_close(t)
	_test_a_completed_take_is_logged_exactly_once(t)
	_test_a_hunting_van_draws_no_victim(t)
	_test_the_obstruction_comes_down_once_it_stops_waiting(t)


func _instance(t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

# The one row whose whole mechanic is time under compulsion rather than a field: entering
# `detain_radius` locks the player's own movement input, and what she is charged while it holds
# depends on the baby's state rather than on anything the def can see. An `EventManager` is built
# by hand — nothing here needs a real `City` — and its trigger (`_check_detentions()`) and its
# per-frame handoff (`_tell_them_where_she_is()`) are driven directly, the same shape
# `test_danger.gd` drives `_warn_about_the_ground_she_is_on()` in: a per-frame method with no
# signal of its own to trigger from outside.

## A `WorldContext` whose `excitement_sources_at`/`total_excitement_at` read straight off a
## hand-built `EventManager`, the same questions `City` answers for real. Lets a real `Baby` be
## driven against the chat's own math without pulling in a whole generated city. `Baby` now sums
## `excitement_sources_at()` rather than calling `total_excitement_at()` directly, so both have to
## be forwarded or the mother's own conversation is invisible to a baby driven against this double.
class _ChatWorld extends WorldContext:
	var manager: EventManager
	func excitement_sources_at(world_position: Vector2) -> Array:
		return manager.excitement_sources_at(world_position)
	func total_excitement_at(world_position: Vector2) -> float:
		return manager.total_excitement_at(world_position)

## A manager with nothing in it but the map arithmetic `_check_detentions()`'s own telemetry line
## needs — see `TelemetryObserver._blocked_rig()` in `tests/test_telemetry.gd` for the same trick.
func _chat_manager() -> EventManager:
	var manager := EventManager.new()
	manager._map = CityMap.new()
	return manager

## A bare `Stroller`, in the tree so `_ready()` has run and its `@onready` camera lookup resolves.
func _chat_stroller(t) -> Stroller:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	return stroller

func _test_a_conversation_locks_her_and_releases(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(2000.0, 2000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller

	stroller.global_position = at
	stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(stroller.is_detained(), "entering detain_radius locks her input")
	t.check(mother.is_chatting(), "and starts the instance's one conversation")

	# Read off `velocity` rather than `global_position`: this rig has no collision shape for
	# `move_and_slide()` to test motion against, and the mechanism under test is entirely in
	# `_physics_process` deciding what `input_dir` is, which `velocity` shows directly.
	Input.action_press("move_right")
	for i in 10:
		stroller._physics_process(STEP)
	t.close_to(stroller.velocity.length(), 0.0,
			"holding a direction through the lock runs velocity out through friction, not held "
			+ "at speed", 1.0)

	for i in 280:
		stroller._physics_process(STEP)
	t.check(stroller.is_detained(), "still locked a few frames before detain_seconds is up")
	t.close_to(stroller.velocity.length(), 0.0, "and stays at rest for the whole lock", 1.0)

	for i in 25:
		stroller._physics_process(STEP)
	Input.action_release("move_right")
	t.check(not stroller.is_detained(), "and releases once detain_seconds has run")
	t.check(stroller.velocity.length() > 10.0,
			"and the same held key moves her again the instant it does")
	mother.free()
	stroller.free()
	manager.free()

func _test_a_conversation_prices_by_the_babys_state(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(3000.0, 3000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	for awake in [true, false]:
		var world := _ChatWorld.new()
		t.add_child(world)
		var stroller := Stroller.new()
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		stroller.add_child(camera)
		var baby := Baby.new()
		# Named explicitly: `Stroller`'s own `@onready var _baby := get_node_or_null("Baby")`
		# needs the child present under that exact name before `Stroller._ready()` runs, and a
		# bare `Baby.new()` cannot be relied on to default to it.
		baby.name = "Baby"
		stroller.add_child(baby)
		t.add_child(stroller)
		stroller.set_physics_process(false)
		baby.set_physics_process(false)

		var mother := _instance(t, def, at, path)
		var manager := _chat_manager()
		world.manager = manager
		manager._instances.append(mother)
		manager._player = stroller
		stroller.global_position = at

		if not awake:
			baby.force_sleep()
		var starting_excitement := baby.excitement

		manager._tell_them_where_she_is()
		manager._check_detentions()
		t.check(stroller.is_detained(), "a capture starts whether she is awake or asleep")

		for i in int(round(def.detain_seconds / STEP)) + 5:
			mother._process(STEP)
			manager._tell_them_where_she_is()
			baby._physics_process(STEP)

		if awake:
			t.close_to(baby.excitement, starting_excitement + Tuning.CHAT_EXCITEMENT,
					"an awake conversation adds %.0f points" % Tuning.CHAT_EXCITEMENT, 2.0)
			# Playtest 38, finding 4: "there is also no real fade from yellow to red (eg when
			# standing next to the other baby lady". Holding this first is what tells the ramp's own
			# shape (`ExcitementHalo.colour_for()`) apart from an attribution bug: the chat's flat
			# rate does reach `contribution_at()` inside her field and land on the mother's own
			# `landed()`, past `Tuning.EXPECTED_IMPACT_POINTS`'s own midpoint, so a dull colour on
			# screen would have been the ramp and not the meter.
			t.close_to(mother.landed(), Tuning.CHAT_EXCITEMENT,
					"and the mother's own landed() carries the same points, which is what " +
					"colour_for() reads", 2.0)
		else:
			t.close_to(baby.excitement, starting_excitement,
					"asleep, the same conversation is a pure time loss: the meter does not move",
					0.5)
			t.close_to(baby.sleepiness, 100.0, "and sleepiness stays pinned at 100 asleep", 0.01)

		mother.free()
		stroller.free()
		world.free()
		manager.free()

## `chatting_mother`'s capture reaches *past* `Tuning.TILE_SIZE` (32px), the spacing between the
## two lanes of a pavement the row used to be tucked under — see
## `EventCatalogue._chatting_mother`, "the far-lane rule is overturned". So the far lane catches
## her, and this checks both halves of that geometry: the far lane triggers, and a point just
## outside `EventDef.detain_distance()` but still inside `inner_radius` does not — the ambient
## field reaches her there and only the conversation must not. She paces, so she carries no body
## and her reach is measured from her own centre.
func _test_a_conversation_only_starts_inside_detain_radius(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(4000.0, 4000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	var far_lane := _instance(t, def, at, path)
	var far_manager := _chat_manager()
	far_manager._instances.append(far_lane)
	var far_stroller := _chat_stroller(t)
	far_manager._player = far_stroller
	far_stroller.global_position = at + Vector2(0.0, Tuning.TILE_SIZE)
	far_manager._tell_them_where_she_is()
	far_manager._check_detentions()
	t.check(far_stroller.is_detained(),
			"the far lane of a two-tile pavement now starts a conversation too")
	far_lane.free()
	far_stroller.free()
	far_manager.free()

	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller

	# Just outside the capture and well inside inner_radius: the ambient field still reaches her
	# and only the conversation must not.
	t.check(def.detain_distance() < def.inner_radius,
			"there is ground outside her capture and inside her field to stand on (%.1f < %.1f)"
			% [def.detain_distance(), def.inner_radius])
	stroller.global_position = at + Vector2(0.0, def.detain_distance() + 0.5)
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not stroller.is_detained(),
			"just outside the capture, no conversation starts")
	t.check(not mother.is_chatting() and not mother.has_chatted(),
			"and the instance is untouched by it")
	mother.free()
	stroller.free()
	manager.free()

func _test_a_conversation_happens_once_per_instance(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(5000.0, 5000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var mother := _instance(t, def, at, path)
	var manager := _chat_manager()
	manager._instances.append(mother)
	var stroller := _chat_stroller(t)
	manager._player = stroller
	stroller.global_position = at

	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(mother.is_chatting(), "the first approach starts the conversation")

	_advance(mother, def.detain_seconds + 0.1)
	t.check(mother.has_chatted() and not mother.is_chatting() and mother.is_leaving,
			"it ends, and she is spent as a detainer — see 'departs like dog_walker'")

	# The lock from the first approach was never run down by a physics tick here, so it has to be
	# cleared by hand to ask the real question: does *this* call detain her again.
	stroller._detained_for = 0.0
	manager._tell_them_where_she_is()
	manager._check_detentions()
	t.check(not stroller.is_detained(), "a second approach to the same instance never re-triggers")
	mother.free()
	stroller.free()
	manager.free()

# `abduction` draws its own scripted victim rather than touching a real `CrowdAgent` — see
# docs/TODO.md, M56. Drawing and telemetry only, so a data-level rig can drive the whole scene by
# hand: `player_at` is the same write `EventManager` makes every frame in the real game.

## The design's own sentence is that the take "only means anything where she can see it happen" —
## a van she never comes near takes nobody, and it begins the moment she does.
func _test_the_take_begins_only_once_she_is_close(t) -> void:
	var def := EventCatalogue.by_id("abduction")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(def.outer_radius + 40.0, 0.0)
	_advance(instance, 2.0)
	t.check(not instance.is_taking_a_victim(), "outside the field, nothing has started")

	instance.player_at = Vector2(def.outer_radius - 20.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_taking_a_victim(), "and it begins the frame she comes inside it")
	instance.free()

## One telemetry entry, written once — not per frame, and not before the walk actually finishes.
func _test_a_completed_take_is_logged_exactly_once(t) -> void:
	Telemetry.begin_memory_log()
	var def := EventCatalogue.by_id("abduction")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(def.outer_radius - 20.0, 0.0)
	_advance(instance, EventInstance.VICTIM_TAKEN_OVER * 0.5)
	var mid_way := 0
	for line in Telemetry.current_log().lines:
		mid_way += 1 if line.contains("taken") else 0
	t.check(mid_way == 0, "nothing is logged while the walk is still happening")

	_advance(instance, EventInstance.VICTIM_TAKEN_OVER)
	var finished := 0
	for line in Telemetry.current_log().lines:
		finished += 1 if line.contains("taken") else 0
	t.check(finished == 1, "exactly one entry once it completes (%d)" % finished)

	# Long past the completion, the count must not grow — the flag latches rather than re-firing.
	_advance(instance, 5.0)
	var later := 0
	for line in Telemetry.current_log().lines:
		later += 1 if line.contains("taken") else 0
	t.check(later == 1, "and it never logs a second time (%d)" % later)
	instance.free()
	Telemetry.end_run()

# `heat_response = HUNTS` turns the same row into a pursuer past `Tuning.HEAT_HUNTS_LEVEL` — see
# docs/EVENTS.md, "The heat". Stated against the fully heated copy, the way `tests/test_heat.gd`'s
# own pursuit tests are.

func _hunting_abduction() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("abduction"), Tuning.RESISTANCE_GOAL)

## A hunting van has other business: the moment it stops waiting, an in-progress take is
## abandoned rather than finished — no victim drawn again, taken or not, and nothing logged for a
## take that never completed.
func _test_a_hunting_van_draws_no_victim(t) -> void:
	Telemetry.begin_memory_log()
	var hot := _hunting_abduction()
	var instance := _instance(t, hot, Vector2.ZERO)
	# Inside the field but outside the trigger, so it is only waiting — the take may begin exactly
	# as it would for a cold van.
	instance.player_at = Vector2(hot.pursues_within + 20.0, 0.0)
	instance._process(STEP)
	t.check(instance.is_taking_a_victim(), "waiting, it takes a bystander exactly like a cold van")

	# Now she comes inside the trigger: it notices her and stops waiting, in the same frame.
	instance.player_at = Vector2(hot.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it turns and notices her")
	t.check(not instance.is_taking_a_victim(), "and the take it was running is abandoned")

	_advance(instance, 5.0)
	var entries := 0
	for line in Telemetry.current_log().lines:
		entries += 1 if line.contains("taken") else 0
	t.check(entries == 0, "nothing is ever logged for a take that never finished")
	instance.free()
	Telemetry.end_run()

## Anything that stands still is solid at the width it is drawn, and a hunting van is the first
## row in the catalogue where that stops being true the instant it moves. `_walkable_step`'s own
## note is why a moving pursuer may not keep one: a moving wall on a two-tile pavement pins her
## against a building.
func _test_the_obstruction_comes_down_once_it_stops_waiting(t) -> void:
	var hot := _hunting_abduction()
	var instance := _instance(t, hot, Vector2.ZERO)
	t.check(instance.is_solid(), "a hunting van still parked is solid, exactly like a cold one")

	instance.player_at = Vector2(hot.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it stops waiting")
	t.check(not instance.is_solid(), "and the body comes down the same frame")
	instance.free()
