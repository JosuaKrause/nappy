extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.keeps_the_home_streets_clear()`),
## not always a day's: the placement context the events ask for after dawn
## (`WalkSiting`, made by the `SitingMaker` the events are handed) refuses the street her front door opens onto on a walk that holds
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
## city for the first case, which asks the manager through its face (`use_the_spec()`,
## `queue_a_mast()`), and builds the parts it hands `EventsAhead` (the world, streaming, spawner
## and board) the way `EventManager._init()` does for the second: `EventsAhead` is the module
## under test, the maker is a fake.
## The director is a fake that records what it is handed (`_RecordingDirector`); the siting the
## fake maker answers is a stand-in (`FakeWalkSiting`), so no siting is built over a city.

const MapCache := preload("res://tests/city_map_cache.gd")

const DAY := 1
const SEED := 4242

func run(t: TestRunner) -> void:
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_the_events_ask_the_maker_they_are_handed_for_every_siting(t)
	_test_a_walk_hands_the_director_what_its_spec_lets_it_send(t)
	_test_a_given_walk_sites_over_the_tree_it_is_handed(t)
	_test_the_escape_buildings_spec_holds_the_streets_and_sends_no_pursuer(t, MapCache.of(SEED))

func _test_the_director_reads_the_rule_off_the_walks_spec(t: TestRunner) -> void:
	var map: CityMap = MapCache.of(SEED)
	var def := EventCatalogue.by_id("burning_building")
	var holds_it := EventScheduler.row_ground(map, null, true).tiles_for(def)
	var leaves_it := EventScheduler.row_ground(map, null, false).tiles_for(def)
	t.check(holds_it != leaves_it,
			"the two rules differ on this city's ground (there was a rule to keep)")
	var manager := EventManager.new(EventSurroundings.new().in_the_city(map))
	manager.setup(RunState.new())
	var maker := FakeSitingMaker.new(FakeWalkSiting.new())
	manager.use_sitings(maker)
	var offered: Array[Vector2i] = [Vector2i(1, 1)]
	manager.use_the_spec(DaySpec.for_day(DAY))
	manager.queue_a_mast(offered)
	t.check(maker.made.size() == 1
			and (maker.made[0][2] as RowGround).tiles_for(def) == holds_it,
			"a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	manager.queue_a_mast(offered)
	t.check(maker.made.size() == 2
			and (maker.made[1][2] as RowGround).tiles_for(def) == leaves_it,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()

## **The escape building's spec splits the two settings** the day's and the escape city's spec
## keep alike: it holds the home's streets (the ground its siting is asked on keeps the street)
## and sends no poster pursuer (a torn poster there sends nobody, where a day's sends one). A
## swap of the two settings in `EventsAhead.use_the_walk_of()` fails here and nowhere else.
func _test_the_escape_buildings_spec_holds_the_streets_and_sends_no_pursuer(
		t: TestRunner, map: CityMap) -> void:
	var def := EventCatalogue.by_id("burning_building")
	var holds_it := EventScheduler.row_ground(map, null, true).tiles_for(def)
	var building := DaySpec.for_section(DaySpec.Section.BUILDING, RunConfig.FINALE_LENGTH_SECONDS)
	var asked := 0
	var pursuers := {}
	for spec: DaySpec in [DaySpec.for_day(DAY), building]:
		var manager := EventManager.new(EventSurroundings.new().in_the_city(map))
		manager.setup(RunState.new())
		var maker := FakeSitingMaker.new(FakeWalkSiting.new())
		manager.use_sitings(maker)
		var her := Node2D.new()
		t.add_child(her)
		her.global_position = map.tile_to_world(Vector2i(16, 16))
		manager.use_player(her)
		manager.use_the_spec(spec)
		var offered: Array[Vector2i] = [Vector2i(1, 1)]
		manager.queue_a_mast(offered)
		manager.send_a_pursuer()
		pursuers[spec] = manager.pending_warnings().size()
		if spec == building:
			asked = maker.made.size()
			t.check(asked == 1 and (maker.made[0][2] as RowGround).tiles_for(def) == holds_it,
					"the building's spec holds the home's streets after dawn")
		manager.use_player(null)
		her.free()
		manager.free()
	t.check(pursuers[building] == 0, "and a torn poster under it sends no pursuer (%d warnings)"
			% pursuers[building])
	t.check(pursuers.values().max() == 1 and pursuers.values().min() == 0,
			"where a day's spec does send one, so the pursuer's absence is the spec's (%s)"
			% [pursuers.values()])

## **Every siting `EventsAhead` needs is asked of the maker it is handed**, with the walk's ground:
## at the day's start when a plan is left for her walk, on a rigged route (`rig_her_route()`) and for
## a mast (`queue_a_mast()`) of a day with none. The ground is the walk's own where the walk carries
## one, and where it carries none a ground made under the home-street rule the walk was started
## under (`EventsAhead.use_the_walk_of()`). Neither the ground nor the maker shows in any siting's
## answers, so the maker is a fake that records what it was asked, handed in as the game hands the
## real one (`EventsAhead.use_sitings()`). A siting no caller asks of the maker is a siting made by
## the class itself, which this holds cannot happen. A rigged route is not asked on a
## walk that does not hold the home's streets: that walk (the escape's city) has no route bag, so
## nothing rigs it.
func _test_the_events_ask_the_maker_they_are_handed_for_every_siting(t: TestRunner) -> void:
	var map: CityMap = MapCache.of(SEED)
	var def := EventCatalogue.by_id("burning_building")
	var holds_it := EventScheduler.row_ground(map, null, true).tiles_for(def)
	var leaves_it := EventScheduler.row_ground(map, null, false).tiles_for(def)
	t.check(holds_it != leaves_it, "the two rules differ on this city's ground (there was a rule to keep)")
	var world := EventWorld.new(EventSurroundings.new().in_the_city(map))
	world.use_run(RunState.new())
	var board := WarningBoard.new(world)
	var spawner := EventSpawner.new(world, board)
	var streaming := EventStreaming.new(world, spawner, WalkEvents.new())
	var tree := FakeRouteTree.new(map)
	var walk := FakeWalkEvents.new()
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	var plans: Array[EventPlan] = [fire]
	walk.set_plans(plans)
	var siting := FakeWalkSiting.new()
	var maker := FakeSitingMaker.new(siting)
	var ahead := EventsAhead.new(world, streaming, spawner, board, walk)
	ahead.use_director(EventDirector.new(map, world.navigator()), null)
	ahead.use_sitings(maker)
	ahead.use_the_walk_of(_spec_that(true))
	ahead.start_day(DAY, tree)
	t.check(maker.made.size() == 1,
			"a day with a plan left for her walk asks the maker once at its start (%d)"
			% maker.made.size())
	if maker.made.size() == 1:
		t.check(maker.made[0][0] == DAY and maker.made[0][1] == tree,
				"for that day, over the day's tree")
		t.check((maker.made[0][2] as RowGround).tiles_for(def) == holds_it,
				"on a ground that keeps off the home street, the spec holding the home's streets")
	var rigged := ahead.rig_her_route([EventCatalogue.mast().id()], 4)
	t.check(not rigged.is_empty() and maker.made.size() == 1,
			"a rigged route asks no second siting while the day has one (%d asks, %d marbles)"
			% [maker.made.size(), rigged.size()])
	# A day with nothing left for her walk has no siting until a rig or a mast asks for one.
	walk.set_plans([] as Array[EventPlan])
	ahead.start_day(DAY, tree)
	var before := maker.made.size()
	ahead.rig_her_route([EventCatalogue.mast().id()], 4)
	t.check(maker.made.size() == before + 1,
			"a rigged route of a day with none asks the maker for one (%d asks, %d before)"
			% [maker.made.size(), before])
	t.check(maker.made.size() == before + 1
			and (maker.made.back()[2] as RowGround).tiles_for(def) == holds_it,
			"on a ground that keeps off the home street where the spec holds the home's streets")
	ahead.use_the_walk_of(_spec_that(true))
	ahead.start_day(DAY, tree)
	before = maker.made.size()
	var offered: Array[Vector2i] = [Vector2i(1, 1)]
	ahead.queue_a_mast(offered)
	t.check(maker.made.size() == before + 1,
			"a mast queued on a day with none asks the maker for one (%d asks, %d before)"
			% [maker.made.size(), before])
	# The ground each ask was given: the walk's where it carries one, else the home-street rule's.
	var carried := EventScheduler.row_ground(map, null, true)
	var carrying := _CarryingWalk.new(carried)
	var carried_asks := FakeSitingMaker.new(siting)
	var on_a_carried_walk := EventsAhead.new(world, streaming, spawner, board, carrying)
	on_a_carried_walk.use_sitings(carried_asks)
	on_a_carried_walk.use_director(EventDirector.new(map, world.navigator()), null)
	on_a_carried_walk.use_the_walk_of(_spec_that(false))
	on_a_carried_walk.queue_a_mast(offered)
	t.check(carried_asks.made.size() == 1 and carried_asks.made[0][2] == carried,
			"a walk that carries a ground has it handed, whatever the spec holds")
	var holding := _the_ground_asked_of(maker, ahead, true, offered)
	var not_holding := _the_ground_asked_of(maker, ahead, false, offered)
	t.check(holding.tiles_for(def) == holds_it,
			"a walk of a spec that holds the home's streets is handed a ground that keeps off the home street")
	t.check(not_holding.tiles_for(def) == leaves_it,
			"and one that does not hold them is handed a ground that offers it")

## **A walk placed whole sites over the tree it was placed against**
## (`EventsAhead.start_a_given_walk()`'s `tree`): a mast queued on it asks the maker for a
## siting over that very tree, never over null, which makes the maker grow one again
## (`SitingMaker.make()`); a walk handed none asks with null, and does not keep the tree of
## a walk before it.
func _test_a_given_walk_sites_over_the_tree_it_is_handed(t: TestRunner) -> void:
	var map: CityMap = MapCache.of(SEED)
	var world := EventWorld.new(EventSurroundings.new().in_the_city(map))
	world.use_run(RunState.new())
	var board := WarningBoard.new(world)
	var spawner := EventSpawner.new(world, board)
	var streaming := EventStreaming.new(world, spawner, WalkEvents.new())
	var maker := FakeSitingMaker.new(FakeWalkSiting.new())
	var ahead := EventsAhead.new(world, streaming, spawner, board, FakeWalkEvents.new())
	ahead.use_director(EventDirector.new(map, world.navigator()), null)
	ahead.use_sitings(maker)
	ahead.use_the_walk_of(_spec_that(true))
	var tree := FakeRouteTree.new(map)
	var offered: Array[Vector2i] = [Vector2i(1, 1)]
	ahead.start_a_given_walk(DAY, tree)
	ahead.queue_a_mast(offered)
	t.check(maker.made.size() == 1 and maker.made[0][1] == tree,
			"a mast queued on a walk handed a tree is sited over it (%d asks)"
			% maker.made.size())
	ahead.start_a_given_walk(DAY)
	ahead.queue_a_mast(offered)
	t.check(maker.made.size() == 2 and maker.made[1][1] == null,
			"and on the next walk, handed none, over none: the first walk's tree is not kept")

## **Both starts of a walk hand the director what its spec lets it send**
## (`DaySpec.director_sends()`), not the day's number: a recording director is handed what
## `EventsAhead.start_day()` (a day's) and `start_a_given_walk()` (a walk placed whole) pass it.
## The escape city's spec hands `NOTHING` on day 1 (the direct boot's day) and day 14 (a run's), and
## a day's hands the ordinary rows. What the director does with the value is
## `test_event_director.gd`'s.
func _test_a_walk_hands_the_director_what_its_spec_lets_it_send(t: TestRunner) -> void:
	var map: CityMap = MapCache.of(SEED)
	var escape := DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
	var world := EventWorld.new(EventSurroundings.new().in_the_city(map))
	world.use_run(RunState.new())
	var board := WarningBoard.new(world)
	var spawner := EventSpawner.new(world, board)
	var streaming := EventStreaming.new(world, spawner, WalkEvents.new())
	var ahead := EventsAhead.new(world, streaming, spawner, board, FakeWalkEvents.new())
	var director := _RecordingDirector.new(map, world.navigator())
	ahead.use_director(director, null)
	ahead.use_sitings(FakeSitingMaker.new(FakeWalkSiting.new()))
	ahead.use_the_walk_of(DaySpec.for_day(1))
	ahead.start_a_given_walk(1)
	ahead.start_day(1, null)
	var ordinary := DaySpec.DirectorSends.THE_DAYS_ROWS
	t.check(director.handed == [ordinary, ordinary],
			"both starts of an ordinary day's walk hand the ordinary rows (%s)" % [director.handed])
	director.handed.clear()
	ahead.use_the_walk_of(escape)
	for day: int in [1, Tuning.RUN_LENGTH_DAYS]:
		ahead.start_a_given_walk(day)
		ahead.start_day(day, null)
	t.check(director.handed == [DaySpec.DirectorSends.NOTHING, DaySpec.DirectorSends.NOTHING,
			DaySpec.DirectorSends.NOTHING, DaySpec.DirectorSends.NOTHING],
			"the escape city's walk hands nothing on day 1 and day 14, by either start (%s)"
			% [director.handed])

## A director that records the `sends` each `start_day()` is handed and does nothing else.
class _RecordingDirector extends EventDirector:
	var handed: Array[DaySpec.DirectorSends] = []

	## Overrides EventDirector.start_day.
	func start_day(_day: int, _plans: Array[EventPlan], _rng: RandomNumberGenerator,
			sends: DaySpec.DirectorSends, _siting: WalkSiting = null, _heat: int = 0) -> void:
		handed.append(sends)

## A walk's spec that holds the home's streets (a day's), or one that does not (the escape's).
func _spec_that(holds: bool) -> DaySpec:
	if holds:
		return DaySpec.for_day(DAY)
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)

## The ground a mast queued on a day with no siting is made over, under `holds`.
func _the_ground_asked_of(maker: FakeSitingMaker, ahead: EventsAhead, holds: bool,
		offered: Array[Vector2i]) -> RowGround:
	ahead.use_the_walk_of(_spec_that(holds))
	ahead.start_a_given_walk(DAY)
	ahead.queue_a_mast(offered)
	return maker.made.back()[2] as RowGround

## A walk that carries the ground its dawn made.
class _CarryingWalk extends FakeWalkEvents:
	var _carried: RowGround

	func _init(ground_carried: RowGround) -> void:
		_carried = ground_carried

	## Overrides WalkEvents.ground.
	func ground() -> RowGround:
		return _carried
