extends RefCounted
## EventManager against a real generated City.
##
## Everything else in the event tests runs on plain data. This one builds an actual city
## and runs a day through it, because the bugs that live here are wiring bugs: an instance
## that is freed but left in the list, a successor that is spawned but never tracked. Both
## of those are invisible to a data-level test and both happened.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

var _city: City

func run(t) -> void:
	_build_city(t)
	_test_day_populates_the_manager(t)
	_test_finished_instances_are_dropped(t)
	_test_successor_replaces_its_parent(t)
	_test_excitement_sums_over_instances(t)
	_teardown()

func _build_city(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _teardown() -> void:
	_city.free()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

func _start(day: int) -> void:
	var consumed: Array[String] = []
	_city.events.start_day(day, _rng(day), consumed)

func _test_day_populates_the_manager(t) -> void:
	_start(1)
	t.check(_city.events.active_count() > 0, "starting a day puts events in the world")
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "every tracked instance is a live node")
		t.check(instance.def != null, "every tracked instance has a def")

func _test_finished_instances_are_dropped(t) -> void:
	_start(1)
	var before := _city.events.active_count()
	var victim: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.spawns_on_finish == "":
			victim = instance
			break
	t.check(victim != null, "there is an event that leaves nothing behind")

	victim._finish()
	_city.events._physics_process(0.016)
	t.check(_city.events.active_count() == before - 1, "a finished event is dropped")
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance),
				"no freed node is left in the list after a retirement")

## The bug this exists for: one event finishing and spawning one successor leaves the list
## the same LENGTH, so a size comparison concluded nothing had changed — and left a freed
## node in the array while never tracking the successor at all.
func _test_successor_replaces_its_parent(t) -> void:
	_start(3)
	var truck: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.id == "fire_truck":
			truck = instance
			break
	if not truck:
		# The fire engine is a one-shot spread over its eligible days; this seed may not
		# have rolled it. Spawn one directly rather than skip the check.
		var plan := EventScheduler.Planned.new(EventCatalogue.by_id("fire_truck"), Vector2(500, 500))
		_city.events._spawn(plan)
		truck = _city.events.instances()[_city.events.active_count() - 1]

	var before := _city.events.active_count()
	var where := truck.global_position
	truck._finish()
	_city.events._physics_process(0.016)

	t.check(_city.events.active_count() == before,
			"a one-for-one replacement keeps the count the same")
	var fire: EventInstance = null
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "no freed node survives a successor swap")
		if instance.def.id == "burning_building":
			fire = instance
	t.check(fire != null, "the fire engine leaves a fire behind it")
	if fire:
		t.close_to(fire.global_position.distance_to(where), 0.0,
				"the fire starts where the engine stopped", 1.0)

func _test_excitement_sums_over_instances(t) -> void:
	_start(5)
	var instances := _city.events.instances()
	t.check(instances.size() > 1, "day 5 has several events to sum")

	var at: Vector2 = instances[0].global_position
	var expected := 0.0
	for instance in instances:
		expected += instance.contribution_at(at)
	t.close_to(_city.events.total_excitement_at(at), expected,
			"the manager's total is the sum of the instances' contributions")

	var far := Vector2(-10000.0, -10000.0)
	t.close_to(_city.events.total_excitement_at(far), 0.0,
			"nothing reaches a point outside every radius")
