extends RefCounted
## The one row whose whole mechanic is time under compulsion rather than a field: entering
## `detain_radius` locks the player's own movement input, and what she is charged while it holds
## depends on the baby's state rather than on anything the def can see. An `EventManager` is built
## by hand and handed a bare map and a run of its own (`setup_world()`, the entry the escape's building
## is handed its world through) -- nothing here needs a real `City` -- and put in the tree with her:
## its own physics ticks hand every instance where she is and start the hold
## (`CheckpointController.check_detentions()`), and hers run the lock down, on real frames of one
## tick each (`PhysicsTicks`).
##
## Plus the van: `abduction` draws its own scripted victim rather than touching a real `CrowdAgent`
## (docs/TODO.md, M56) -- drawing and telemetry only, so a data-level rig can drive the whole scene
## by hand -- and `heat_response = HUNTS`, which turns the same row into a pursuer past
## `EventDef.HEAT_HUNTS_LEVEL` (docs/EVENTS.md, "The heat"), stated against the fully heated copy.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again".

const STEP := 1.0 / 60.0
## The seed of the run each test hands its manager.
const RUN_SEED := 2
## The long waits go at this many times real time (`PhysicsTicks`): each tick is that much longer.
const WAIT_SCALE := 3.0

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	await _test_a_conversation_locks_her_and_releases(t)
	await _test_a_conversation_prices_by_the_babys_state(t)
	await _test_a_conversation_only_starts_inside_detain_radius(t)
	await _test_a_conversation_happens_once_per_instance(t)
	await _test_a_mother_streamed_out_after_her_chat_does_not_come_back(t)
	_test_the_take_begins_only_once_she_is_close(t)
	_test_a_completed_take_is_logged_exactly_once(t)
	_test_a_hunting_van_draws_no_victim(t)
	_test_a_hunting_van_stays_solid_once_it_notices_her(t)


## A live event of `def`, set up as `EventSpawner.create()` sets one up: its `trace`, where one is
## given, handed in before `setup()`, which hands it on to its behaviours.
func _instance(t: TestRunner, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array(), where: WhereSheIs = null,
		trace: RunTrace = null) -> EventInstance:
	var instance := EventInstance.new()
	if trace:
		instance.trace = trace
	instance.setup(def, at, path, Vector2.RIGHT, null, null, where)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## A manager over a bare map and a run of its own, handed in as the escape's building is handed its
## world (`EventManager.setup_world()`), and in the tree: its own physics tick hands every instance
## where she is and starts the hold. Added to the tree before the stroller, so on every tick it
## runs first. `_free_manager()` frees it.
func _chat_manager(t: TestRunner) -> EventManager:
	var run := RunState.new()
	run.start_run(RUN_SEED)
	# Open ground, so no wall keeps a field from her (`ExcitementSource.contribution_at()`).
	var map := WorldMap.open_ground()
	# The world the map is drawn in, as the city and the building hand theirs: the layer a
	# spawned event is added to (`WorldMap.add_entity()`).
	var holder := WorldContext.new()
	t.add_child(holder)
	map.world = holder
	var manager := EventManager.new()
	manager.setup_world(map, run)
	t.add_child(manager)
	return manager

func _free_manager(manager: EventManager) -> void:
	var holder := manager.world.map.world
	manager.free()
	holder.free()

## Frees a rig whatever state its checks left it in: the manager first, so that no tick is left to
## act on a mother who is still mid-conversation (or a hold a failed check never let start), then
## the mother and her. A check that failed then reports as a FAIL, rather than the engine aborting
## inside a `free()` before any line prints.
func _free_the_cast(manager: EventManager, mother: EventInstance, stroller: Stroller) -> void:
	_free_manager(manager)
	if is_instance_valid(mother):
		mother.free()
	if is_instance_valid(stroller):
		stroller.free()

## A bare `Stroller`, in the tree so `_ready()` has run, its `@onready` camera lookup resolves and
## her own physics runs (the lock is run down on her tick).
func _chat_stroller(t: TestRunner) -> Stroller:
	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	stroller.add_child(camera)
	t.add_child(stroller)
	return stroller

func _test_a_conversation_locks_her_and_releases(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(2000.0, 2000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var manager := _chat_manager(t)
	var mother := manager.spawn_extra(def, at, path)
	mother.set_process(false)
	var stroller := _chat_stroller(t)
	manager.use_player(stroller)

	stroller.global_position = at
	stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(stroller.is_detained(), "entering detain_radius locks her input")
	t.check(mother.is_chatting(), "and starts the instance's one conversation")

	# Read off `velocity` rather than `global_position`: this rig has no collision shape for
	# `move_and_slide()` to test motion against, and the mechanism under test is entirely in
	# `_physics_process` deciding what `input_dir` is, which `velocity` shows directly.
	Input.action_press("move_right")
	await PhysicsTicks.pass_ticks(t, 10)
	t.close_to(stroller.velocity.length(), 0.0,
			"holding a direction through the lock runs velocity out through friction, not held "
			+ "at speed", 1.0)

	# Up to 0.2s short of the lock's end, the 11 ticks above counted.
	var spent := 11.0 / Engine.physics_ticks_per_second
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(def.detain_seconds - spent - 0.2, WAIT_SCALE),
			Callable(), WAIT_SCALE)
	t.check(stroller.is_detained(), "still locked a few frames before detain_seconds is up")
	t.close_to(stroller.velocity.length(), 0.0, "and stays at rest for the whole lock", 1.0)

	await PhysicsTicks.pass_ticks(t, 4, Callable(), WAIT_SCALE)
	Input.action_release("move_right")
	t.check(not stroller.is_detained(), "and releases once detain_seconds has run")
	t.check(stroller.velocity.length() > 10.0,
			"and the same held key moves her again the instant it does")
	_free_the_cast(manager, mother, stroller)

func _test_a_conversation_prices_by_the_babys_state(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(3000.0, 3000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	for awake: bool in [true, false]:
		# A bare world handed the hand-built manager: the same answer `City` gives for real
		# (`WorldContext.excitement_sources_at()`), with no generated city to pull in.
		var world := WorldContext.new()
		t.add_child(world)
		var manager := _chat_manager(t)
		var stroller := Stroller.new()
		var camera := Camera2D.new()
		camera.name = "Camera2D"
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		stroller.add_child(camera)
		var baby := Baby.new()
		# Named explicitly: `Stroller`'s own `@onready var _baby := get_node_or_null("Baby")`
		# needs the child present under that exact name before `Stroller._ready()` runs, and a
		# bare `Baby.new()` cannot be relied on to default to it.
		baby.name = "Baby"
		stroller.add_child(baby)
		baby.set_world(world)
		baby.use_bus(EventBus)
		t.add_child(stroller)

		var mother := manager.spawn_extra(def, at, path)
		mother.set_process(false)
		world.excitement_sources = [manager.sources]
		manager.use_player(stroller)
		stroller.global_position = at

		if not awake:
			baby.force_sleep()
		var starting_excitement := baby.excitement

		await PhysicsTicks.pass_ticks(t, 1)
		t.check(stroller.is_detained(), "a capture starts whether she is awake or asleep")

		await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(def.detain_seconds, WAIT_SCALE) + 2,
				Callable(), WAIT_SCALE)

		if awake:
			t.close_to(baby.excitement, starting_excitement + Tuning.CHAT_EXCITEMENT,
					"an awake conversation adds %.0f points" % Tuning.CHAT_EXCITEMENT, 2.0)
			# Playtest 38, finding 4: "there is also no real fade from yellow to red (eg when
			# standing next to the other baby lady". Holding this first is what tells the ramp's own
			# shape (the colour the halo tells a rim) apart from an attribution bug: the chat's flat
			# rate does reach `contribution_at()` inside her field and land on the mother's own
			# `landed()`, past `Tuning.EXPECTED_IMPACT_POINTS`'s own midpoint, so a dull colour on
			# screen would have been the ramp and not the meter.
			t.close_to(mother.excitement.landed(), Tuning.CHAT_EXCITEMENT,
					"and the mother's own landed() carries the same points, which is what " +
					"the halo's colour reads", 2.0)
		else:
			t.close_to(baby.excitement, starting_excitement,
					"asleep, the same conversation is a pure time loss: the meter does not move",
					0.5)
			t.close_to(baby.sleepiness, 100.0, "and sleepiness stays pinned at 100 asleep", 0.01)

		stroller.free()
		world.free()
		_free_manager(manager)

## `chatting_mother`'s capture reaches *past* `Tuning.TILE_SIZE` (32px), the spacing between the
## two lanes of a pavement the row used to be tucked under — see
## `EventCatalogue._chatting_mother`, "the far-lane rule is overturned". So the far lane catches
## her, and this checks both halves of that geometry: the far lane triggers, and a point just
## outside `EventDef.detain_distance()` but still inside `inner_radius` does not — the ambient
## field reaches her there and only the conversation must not. She paces, so she carries no body
## and her reach is measured from her own centre.
func _test_a_conversation_only_starts_inside_detain_radius(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(4000.0, 4000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])

	var far_manager := _chat_manager(t)
	var far_lane := far_manager.spawn_extra(def, at, path)
	far_lane.set_process(false)
	var far_stroller := _chat_stroller(t)
	far_manager.use_player(far_stroller)
	far_stroller.global_position = at + Vector2(0.0, Tuning.TILE_SIZE)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(far_stroller.is_detained(),
			"the far lane of a two-tile pavement now starts a conversation too")
	far_stroller.free()
	_free_manager(far_manager)

	var manager := _chat_manager(t)
	var mother := manager.spawn_extra(def, at, path)
	mother.set_process(false)
	var stroller := _chat_stroller(t)
	manager.use_player(stroller)

	# Just outside the capture and well inside inner_radius: the ambient field still reaches her
	# and only the conversation must not.
	t.check(def.detain_distance() < def.inner_radius,
			"there is ground outside her capture and inside her field to stand on (%.1f < %.1f)"
			% [def.detain_distance(), def.inner_radius])
	stroller.global_position = at + Vector2(0.0, def.detain_distance() + 0.5)
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(not stroller.is_detained(),
			"just outside the capture, no conversation starts")
	t.check(not mother.is_chatting() and not mother.has_chatted(),
			"and the instance is untouched by it")
	_free_the_cast(manager, mother, stroller)

func _test_a_conversation_happens_once_per_instance(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(5000.0, 5000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var manager := _chat_manager(t)
	var mother := manager.spawn_extra(def, at, path)
	mother.set_process(false)
	var stroller := _chat_stroller(t)
	manager.use_player(stroller)
	stroller.global_position = at

	await PhysicsTicks.pass_ticks(t, 1)
	t.check(mother.is_chatting(), "the first approach starts the conversation")

	# Her own ticks run the lock down; the conversation ends on the manager's, with her still
	# standing inside its reach.
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(def.detain_seconds + 0.1, WAIT_SCALE),
			Callable(), WAIT_SCALE)
	t.check(mother.has_chatted() and not mother.is_chatting() and mother.is_leaving,
			"it ends, and she is spent as a detainer — see 'departs like dog_walker'")
	t.check(not stroller.is_detained(), "and the lock from the first approach has run down")

	stroller.global_position = mother.global_position
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(not stroller.is_detained(), "a second approach to the same instance never re-triggers (the once-only rule: it is "
			+ "spent and leaving, which stops it as much as the has_chatted() gate does)")
	_free_the_cast(manager, mother, stroller)

## **No second conversation across streaming**: a conversation ends with her leaving
## (`EventInstance._be_done()`), and a plan streamed out while its instance is leaving is spent
## (`EventStreaming.stream_out()`), so walking away past the stream radius and back brings no second
## mother to stop her. Driven through the manager's own streaming on a plan the way a scene's
## recipe hands the day its plans (`EventManager.start_recipe()`), with her ticks streaming around
## her as a day's do.
func _test_a_mother_streamed_out_after_her_chat_does_not_come_back(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var at := Vector2(5000.0, 5000.0)
	var path := PackedVector2Array([at, at + Vector2(256.0, 0.0)])
	var manager := _chat_manager(t)
	var stroller := _chat_stroller(t)
	manager.use_player(stroller)
	stroller.global_position = at
	var plan := EventPlan.new(def, at, path)
	manager.start_recipe([plan] as Array[EventPlan], DaySpec.for_day(1), 1, at)
	await PhysicsTicks.pass_ticks(t, 1)
	var mother := plan.live
	t.check(mother != null, "she is streamed in where the day planned her")
	if not mother:
		stroller.free()
		_free_manager(manager)
		return
	t.check(mother.is_chatting(), "the first approach starts the conversation")
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(def.detain_seconds + 0.1, WAIT_SCALE),
			Callable(), WAIT_SCALE)
	t.check(mother.is_leaving, "it ends with her leaving")
	var far := at + Vector2(Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
			+ Tuning.OUT_OF_SIGHT + 100.0, 0.0)
	stroller.global_position = far
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(plan.live == null and plan.spent,
			"walking off past the stream radius takes her away for good (live %s, spent %s)"
			% [plan.live != null, plan.spent])
	stroller.global_position = at
	await PhysicsTicks.pass_ticks(t, 2)
	t.check(plan.live == null and not stroller.is_detained(),
			"and walking back past her place brings no second conversation")
	stroller.free()
	_free_manager(manager)

# `abduction` draws its own scripted victim rather than touching a real `CrowdAgent` — see
# docs/TODO.md, M56. Drawing and telemetry only, so a data-level rig can drive the whole scene by
# hand: `WhereSheIs.tell()` is the same call `EventManager` makes every frame in the real game.

## The design's own sentence is that the take "only means anything where she can see it happen" —
## a van she never comes near takes nobody, and it begins the moment she does.
func _test_the_take_begins_only_once_she_is_close(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("abduction")
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where)
	instance_where.tell(Vector2(def.outer_radius + 40.0, 0.0))
	_advance(instance, 2.0)
	t.check(not instance.is_taking_a_victim(), "outside the field, nothing has started")

	instance_where.tell(Vector2(def.outer_radius - 20.0, 0.0))
	instance.step(STEP)
	t.check(instance.is_taking_a_victim(), "and it begins the frame she comes inside it")
	instance.free()

## One telemetry entry, written once — not per frame, and not before the walk actually finishes.
func _test_a_completed_take_is_logged_exactly_once(t: TestRunner) -> void:
	var lines: Array[String] = []
	var def := EventCatalogue.by_id("abduction")
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where,
			RunTrace.recording(lines))
	instance_where.tell(Vector2(def.outer_radius - 20.0, 0.0))
	_advance(instance, instance.def.abduction.taken_over * 0.5)
	t.check(_takes(lines) == 0, "nothing is logged while the walk is still happening")

	_advance(instance, instance.def.abduction.taken_over)
	t.check(_takes(lines) == 1, "exactly one entry once it completes (%d)" % _takes(lines))

	# Long past the completion, the count must not grow — the flag latches rather than re-firing.
	_advance(instance, 5.0)
	t.check(_takes(lines) == 1, "and it never logs a second time (%d)" % _takes(lines))
	instance.free()

## How many of the instance's own lines are a take.
static func _takes(lines: Array[String]) -> int:
	var takes := 0
	for line in lines:
		takes += 1 if line.begins_with("taken ") else 0
	return takes

# `heat_response = HUNTS` turns the same row into a hunter on foot past `EventDef.HEAT_HUNTS_LEVEL` — see
# docs/EVENTS.md, "The heat". Stated against the fully heated copy, the way `tests/test_heat.gd`'s
# own pursuit tests are.

func _hunting_abduction() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("abduction"), Tuning.RESISTANCE_GOAL)

## A hunting van has other business: the moment it stops waiting, an in-progress take is
## abandoned rather than finished — no victim drawn again, taken or not, and nothing logged for a
## take that never completed.
func _test_a_hunting_van_draws_no_victim(t: TestRunner) -> void:
	var lines: Array[String] = []
	var hot := _hunting_abduction()
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, hot, Vector2.ZERO, PackedVector2Array(), instance_where,
			RunTrace.recording(lines))
	# Inside the field but outside the trigger, so it is only waiting — the take may begin exactly
	# as it would for a cold van.
	instance_where.tell(Vector2(hot.notice_within() + 20.0, 0.0))
	instance.step(STEP)
	t.check(instance.is_taking_a_victim(), "waiting, it takes a bystander exactly like a cold van")

	# Now she comes inside the trigger: it notices her and stops waiting, in the same frame.
	instance_where.tell(Vector2(hot.notice_within() - 10.0, 0.0))
	instance.step(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it turns and notices her")
	t.check(not instance.is_taking_a_victim(), "and the take it was running is abandoned")

	_advance(instance, 5.0)
	t.check(_takes(lines) == 0, "nothing is ever logged for a take that never finished")
	instance.free()

## Anything that stands still is solid at the width it is drawn, and a hunting van stands still:
## it hunts on foot (`EventDef.hunts` letting its men out, inbox #669 in coral-lark: "Same as the police"), letting its men
## out rather than moving, so its body stays where it is once it has noticed her too.
func _test_a_hunting_van_stays_solid_once_it_notices_her(t: TestRunner) -> void:
	var hot := _hunting_abduction()
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, hot, Vector2.ZERO, PackedVector2Array(), instance_where)
	t.check(instance.is_solid(), "a hunting van still parked is solid, exactly like a cold one")

	instance_where.tell(Vector2(hot.notice_within() - 10.0, 0.0))
	instance.step(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it stops waiting")
	t.check(instance.is_solid() and instance.officers_owed() == 2,
			"and it stays solid where it stands, owing the two men it lets out")
	instance.free()
