class_name FakeEventManager
extends EventManager
## A stand-in for a day's events, handed to what is handed an `EventManager` (the resistance's
## happenings, `ResistanceHappenings.setup()`) in place of the real one, so the check builds no city
## and plans no day. It answers what those ask of it in the situations its suites set: a row
## spawned unplanned (`spawn_extra()`) is an instance of that row at the point and on the path asked,
## which is what the real manager hands back for a raid at her building (two `night_raid` vans and a
## pacing `police_patrol`, read off a real city once). The resistance's director asks it three more
## things in the days it stands a task on: the instances it has put in the street (`instances()`),
## ending one (`retire()`), and rigging her route's bag (`rig_her_route()`), which a day with no
## walk planned has nothing to rig.
##
## **An authored scene starts its walk on it** (`SceneRecipeRuntime.install()`,
## `start_recipe()`): it records the plans, the spec, the day, the focus, the calm areas and the
## ground it is handed, and answers those plans (`plans()`), each standing in the world
## (`EventPlan.is_in_the_world()`, `event_of()`), the calm areas (`calm_as_the_map_stands()`)
## and the owed count a rigged route is handed back (`start_recipe_route()`), which the real
## manager answers from its bag (read off a real day once). **Where it answers differently from
## the real manager:** every plan is put in the world wherever it stands, where the real
## streaming puts in only what lies within its radius, so the runtime's refusal of a plan that
## is not live at its initial position never fires here; the calm areas are an empty
## `FakeCalmAreas`, so no authored row is refused calm ground; and `spawn_warned()` is a plain
## `spawn_extra()` told it came under a warning (`EventInstance.arrive_from_its_warning()`, which
## the screen-edge badge reads), with neither the warning itself nor the warned age the real spawner
## gives. No case reaches the first two, and no case reads the age. The real manager's own logic is checked in its own suites
## (`tests/test_event_manager.gd` and the rest). A helper, not a suite: the runner loads only
## `test_*.gd`.
##
## **Never put in a world.** The parts `EventManager._init()` builds stay idle, so a call this does
## not override reaches a real part over an empty world, which a check would see as a wrong answer
## rather than a crash. A node: the suite frees it, and with it every instance it made.

## Every instance `spawn_extra()` made, freed with the manager: none is in a world either.
var _made: Array[EventInstance] = []

## A manager over the shipped catalogue's rows, the surroundings' only part the real manager's
## own parts read as they are made (the checkpoint's door guard and its warning).
func _init() -> void:
	super(Shipped.rows(), EventSurroundings.new())

## How many masts `silence_all_masts()` answers it stopped, what the real manager counts off the day's
## plans (`tests/test_masts.gd` holds that count): the blackout's suite sets it to the masts a day
## carries and reads `silenced_all` for what it was asked.
var masts_to_silence := 0
## How many times `silence_all_masts()` was asked.
var silenced_all := 0

## What `start_recipe()` was handed, and how many times it was.
var _fake_recipe_plans: Array[EventPlan] = []
var _fake_recipe_spec: DaySpec
var _fake_recipe_day := -1
var _fake_recipe_focus := Vector2.INF
var _fake_recipe_calm: CalmAreas
var _fake_recipe_ground: RowGround
var _fake_recipe_tree: RouteTree
var _fake_recipe_locations: DayLocations
var _fake_recipes_started := 0
## The live instance of each plan `start_recipe()` put in the world, by plan.
var _fake_live := {}
## What `start_recipe_route()` was handed, one entry per ask.
var _fake_routes: Array[Dictionary] = []

## An instance of `def` at `at`, on `path`, in no world.
##
## Overrides EventManager.spawn_extra.
func spawn_extra(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	_made.append(instance)
	return instance

## An instance of `def` on `path`, in no world, as the real manager creates a row whose warning ran
## before it existed (the resistance's column trucks): told it came under that warning, so the
## screen-edge badge carries on to it.
##
## Overrides EventManager.spawn_warned.
func spawn_warned(def: EventDef, path: PackedVector2Array, _pelican := false) -> EventInstance:
	var instance := spawn_extra(def, path[0], path)
	instance.arrive_from_its_warning()
	return instance

## The instances `spawn_extra()` made, the ones still standing: what the street holds, as the real
## manager's street holds the ones it spawned. Not the ones freed since.
##
## Overrides EventManager.instances.
func instances() -> Array[EventInstance]:
	var standing: Array[EventInstance] = []
	for instance in _made:
		if is_instance_valid(instance):
			standing.append(instance)
	return standing

## Ends `instance` where it stands, as the real manager's spawner does for one it spawned.
##
## Overrides EventManager.retire.
func retire(instance: EventInstance) -> void:
	if instance and is_instance_valid(instance) and not instance.is_gone():
		instance.end_now()

## Takes the recipe's plans as the walk, each standing in the world at its point on its path, and
## notes what it was handed. Nothing is planned, sited or streamed.
##
## Overrides EventManager.start_recipe.
func start_recipe(plans: Array[EventPlan], spec: DaySpec, day: int, focus: Vector2,
		calm: CalmAreas = null, ground: RowGround = null, tree: RouteTree = null,
		locations: DayLocations = null) -> void:
	_fake_recipe_plans = plans
	_fake_recipe_spec = spec
	_fake_recipe_day = day
	_fake_recipe_focus = focus
	_fake_recipe_calm = calm
	_fake_recipe_ground = ground
	_fake_recipe_tree = tree
	_fake_recipe_locations = locations
	_fake_recipes_started += 1
	for plan in plans:
		var instance := EventInstance.new()
		instance.setup(plan.row(), plan.placed_at(), plan.walks())
		_made.append(instance)
		_fake_live[plan] = instance
		plan.enter_the_world(instance.standing())

## The plans `start_recipe()` was handed.
##
## Overrides EventManager.plans.
func plans() -> Array[EventPlan]:
	return _fake_recipe_plans

## The live instance of `plan` where `start_recipe()` put it in the world, null for any other plan.
##
## Overrides EventManager.event_of.
func event_of(plan: EventPlan) -> EventInstance:
	return _fake_live.get(plan)

## No calm areas: a `FakeCalmAreas` with none set, which the scene is placed against and hands back
## to `start_recipe()`.
##
## Overrides EventManager.calm_as_the_map_stands.
func calm_as_the_map_stands() -> CalmAreas:
	return FakeCalmAreas.new()

## Notes the rigged route and answers the owed count it was handed.
##
## Overrides EventManager.start_recipe_route.
func start_recipe_route(marbles: Array, pre_bag: Array, owed: int, first_after: float) -> int:
	_fake_routes.append({"marbles": marbles, "pre_bag": pre_bag, "owed": owed,
			"first_after": first_after})
	return owed

## How many times `start_recipe()` was asked.
func recipes_started() -> int:
	return _fake_recipes_started

## The spec the last `start_recipe()` was handed: the very object the scene was installed with.
func recipe_spec() -> DaySpec:
	return _fake_recipe_spec

## The day the last `start_recipe()` was handed.
func recipe_day() -> int:
	return _fake_recipe_day

## The point the last `start_recipe()` was handed to stream round.
func recipe_focus() -> Vector2:
	return _fake_recipe_focus

## The calm areas the last `start_recipe()` was handed, null for none.
func recipe_calm() -> CalmAreas:
	return _fake_recipe_calm

## The ground the last `start_recipe()` was handed, null for none.
func recipe_ground() -> RowGround:
	return _fake_recipe_ground

## The route tree the last `start_recipe()` was handed, null for none.
func recipe_tree() -> RouteTree:
	return _fake_recipe_tree

## The locations the last `start_recipe()` was handed, null for none.
func recipe_locations() -> DayLocations:
	return _fake_recipe_locations

## What each `start_recipe_route()` was handed, in order: `marbles`, `pre_bag`, `owed`,
## `first_after`.
func recipe_routes() -> Array[Dictionary]:
	return _fake_routes

## Answers that nothing was rigged: no walk is planned here, so there is no bag whose next marbles to
## set, which is what the real manager answers for a rig that started no day.
##
## Overrides EventManager.rig_her_route.
func rig_her_route(_ids: Array[String], _size: int, _just_ahead := false) -> Array:
	return []

## Answers `masts_to_silence` and counts the ask.
##
## Overrides EventManager.silence_all_masts.
func silence_all_masts() -> int:
	silenced_all += 1
	return masts_to_silence

## Frees what `spawn_extra()` made, beside the manager's own letting go of its parts (the engine
## sends the notification to each script of the chain).
##
## Overrides EventManager._notification.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for instance in _made:
			if is_instance_valid(instance):
				instance.free()
		_made.clear()
