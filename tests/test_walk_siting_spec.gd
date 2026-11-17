extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the events ask for after dawn
## (`EventScheduler.WalkSiting`, made by the `SitingMaker` the events are handed) refuses the street her front door opens onto on a walk that holds
## the home's streets, as the dawn placement does, and offers it on a walk that does not (the escape's
## city, which sets off from the service exit). The rule is the ground's a siting is handed
## (`RowGround`): the day's own, made at dawn under the day's spec and handed on with the walk, or,
## for a walk no dawn planned, one the events make under the spec the manager was handed
## (`EventManager.start_day()`, `use_the_spec()`), never the manager's own.
##
## What a ground refuses under the rule (`RowGround.tiles_for()`) is the suites' that ask it of a
## city; `tests/test_event_manager.gd` holds that a day's walk carries the dawn's ground and that the
## siting made at the day's start asks it, and this suite holds the rule is read off the walk's spec,
## and that every siting `EventsAhead` needs (the day's, a rigged route's and a mast's) is asked of
## the maker it is handed, with the walk's ground. It builds a real `EventManager` over a generated
## city for the parts it hands `EventsAhead` (the world, streaming, spawner and board), which a
## hand-made one would only restate: `EventsAhead` is the module under test, the maker is a fake.
## **The director and the siting it answers are real**, over that map (`EventDirector`,
## `EventScheduler.WalkSiting`): the fake siting a stand-in needs (`FakeWalkSiting`) arrives with
## pull request 3b, which also makes `WalkSiting` a file of its own, and until then a siting cannot
## be built without a map; this suite then hands the fake and builds no city.

const MapCache := preload("res://tests/city_map_cache.gd")

const DAY := 1
const SEED := 4242

func run(t: TestRunner) -> void:
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_the_events_ask_the_maker_they_are_handed_for_every_siting(t)

func _test_the_director_reads_the_rule_off_the_walks_spec(t: TestRunner) -> void:
	var manager := EventManager.new()
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead.holds_the_home_streets, "a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead.holds_the_home_streets,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()

## **Every siting `EventsAhead` needs is asked of the maker it is handed**, with the walk's ground:
## at the day's start when a plan is left for her walk, on a rigged route (`rig_her_route()`) and for
## a mast (`queue_a_mast()`) of a day with none. The ground is the walk's own where the walk carries
## one, and where it carries none a ground made under the home-street rule the walk was started under
## (`holds_the_home_streets`). Neither the ground nor the maker shows in any siting's answers, so
## the maker is a fake that records what it was asked, handed in as the game hands the real one
## (`EventsAhead.use_sitings()`). A siting no caller asks of the maker is a siting made by the class
## itself, which this holds cannot happen.
func _test_the_events_ask_the_maker_they_are_handed_for_every_siting(t: TestRunner) -> void:
	var map: CityMap = MapCache.of(SEED)
	var def := EventCatalogue.by_id("burning_building")
	var holds_it := EventScheduler.row_ground(map, null, true).tiles_for(def)
	var leaves_it := EventScheduler.row_ground(map, null, false).tiles_for(def)
	t.check(holds_it != leaves_it, "the two rules differ on this city's ground (there was a rule to keep)")
	var manager := EventManager.new()
	manager.setup(map, null, null, RunState.new())
	var tree := FakeRouteTree.new(map)
	var walk := FakeWalkEvents.new()
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	var plans: Array[EventPlan] = [fire]
	walk.set_plans(plans)
	var siting := EventScheduler.WalkSiting.new(DAY, map, tree, walk, EventScheduler.Verdicts.new(),
			GamePlanBuilder.over(map), EventScheduler.row_ground(map))
	var maker := FakeSitingMaker.new(siting)
	var ahead := EventsAhead.new(manager.world, manager.streaming, manager.spawner,
			manager.warnings, walk)
	ahead.use_director(EventDirector.new(map, manager.world.navigator()), null)
	ahead.use_sitings(maker)
	ahead.holds_the_home_streets = true
	ahead.start_day(DAY, tree)
	t.check(maker.made.size() == 1,
			"a day with a plan left for her walk asks the maker once at its start (%d)"
			% maker.made.size())
	if maker.made.size() == 1:
		t.check(maker.made[0][0] == DAY and maker.made[0][1] == tree,
				"for that day, over the day's tree")
		t.check((maker.made[0][2] as RowGround).tiles_for(def) == holds_it,
				"on a ground that keeps off the home street, the spec holding the home's streets")
	var rigged := ahead.rig_her_route([EventCatalogue.mast().id], 4)
	t.check(not rigged.is_empty() and maker.made.size() == 1,
			"a rigged route asks no second siting while the day has one (%d asks, %d marbles)"
			% [maker.made.size(), rigged.size()])
	# A day with nothing left for her walk has no siting until a rig or a mast asks for one.
	walk.set_plans([] as Array[EventPlan])
	ahead.start_day(DAY, tree)
	var before := maker.made.size()
	ahead.rig_her_route([EventCatalogue.mast().id], 4)
	t.check(maker.made.size() == before + 1,
			"a rigged route of a day with none asks the maker for one (%d asks, %d before)"
			% [maker.made.size(), before])
	t.check(maker.made.size() == before + 1
			and (maker.made.back()[2] as RowGround).tiles_for(def) == holds_it,
			"on a ground that keeps off the home street where the spec holds the home's streets")
	ahead.holds_the_home_streets = false
	ahead.start_day(DAY, tree)
	before = maker.made.size()
	ahead.rig_her_route([EventCatalogue.mast().id], 4)
	t.check(maker.made.size() == before + 1
			and (maker.made.back()[2] as RowGround).tiles_for(def) == leaves_it,
			"and on one that offers it where the spec does not")
	ahead.holds_the_home_streets = true
	ahead.start_day(DAY, tree)
	before = maker.made.size()
	var offered: Array[Vector2i] = [Vector2i(1, 1)]
	var rng := RandomNumberGenerator.new()
	ahead.queue_a_mast(offered, rng)
	t.check(maker.made.size() == before + 1,
			"a mast queued on a day with none asks the maker for one (%d asks, %d before)"
			% [maker.made.size(), before])
	# The ground each ask was given: the walk's where it carries one, else the home-street rule's.
	var carried := EventScheduler.row_ground(map, null, true)
	var carrying := _CarryingWalk.new(carried)
	var carried_asks := FakeSitingMaker.new(siting)
	var on_a_carried_walk := EventsAhead.new(manager.world, manager.streaming, manager.spawner,
			manager.warnings, carrying)
	on_a_carried_walk.use_sitings(carried_asks)
	on_a_carried_walk.use_director(EventDirector.new(map, manager.world.navigator()), null)
	on_a_carried_walk.holds_the_home_streets = false
	on_a_carried_walk.queue_a_mast(offered, rng)
	t.check(carried_asks.made.size() == 1 and carried_asks.made[0][2] == carried,
			"a walk that carries a ground has it handed, whatever the spec holds")
	var holding := _the_ground_asked_of(maker, ahead, true, offered, rng)
	var not_holding := _the_ground_asked_of(maker, ahead, false, offered, rng)
	t.check(holding.tiles_for(def) == holds_it,
			"a walk of a spec that holds the home's streets is handed a ground that keeps off the home street")
	t.check(not_holding.tiles_for(def) == leaves_it,
			"and one that does not hold them is handed a ground that offers it")
	manager.free()

## The ground a mast queued on a day with no siting is made over, under `holds`.
func _the_ground_asked_of(maker: FakeSitingMaker, ahead: EventsAhead, holds: bool,
		offered: Array[Vector2i], rng: RandomNumberGenerator) -> RowGround:
	ahead.holds_the_home_streets = holds
	ahead.start_a_given_walk(DAY)
	ahead.queue_a_mast(offered, rng)
	return maker.made.back()[2] as RowGround

## A walk that carries the ground its dawn made.
class _CarryingWalk extends FakeWalkEvents:
	var _carried: RowGround

	func _init(ground_carried: RowGround) -> void:
		_carried = ground_carried

	## Overrides WalkEvents.ground.
	func ground() -> RowGround:
		return _carried
