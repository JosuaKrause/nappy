extends RefCounted
## **One source of each kind against a world that is only what this suite hands it**: the shared
## part every source keeps once (`ExcitementSource` — the ledger, the first landing, the netting),
## an event's source (`EventExcitement`) and a crowd body's (`CrowdExcitement`) each holding the
## rules that are only its own, and the door rule the world states once
## (`ExcitementSources.all_at()`).

func run(t) -> void:
	_test_the_ledger_is_a_sliding_sum_on_the_source_clock(t)
	_test_the_first_landing_is_told_once(t)
	_test_the_nets_sum_to_the_bar_rise(t)
	_test_an_event_caches_its_rate_on_its_age(t)
	_test_an_event_caret_reads_where_its_instance_says_she_is(t)
	_test_an_outranked_source_projects_nothing(t)
	_test_a_crowd_body_is_never_cached(t)
	_test_a_crowd_body_jolt_widens_its_set(t)
	_test_a_held_door_is_the_whole_answer(t)

## A base source whose clock a test sets by hand.
class Clocked extends ExcitementSource:
	var now := 0.0

	func clock() -> float:
		return now

## A set of fixed pairs that holds her alone or not, as a test says.
class Fixed extends ExcitementSources:
	var pairs: Array = []
	var alone := false

	func sources_at(_at: Vector2) -> Array:
		return pairs

	func holds_her_alone(_at: Vector2) -> bool:
		return alone

func _def(id: String, intensity: float, inner := 40.0, outer := 150.0) -> EventDef:
	var def := EventDef.new()
	def.id = id
	def.intensity = intensity
	def.inner_radius = inner
	def.outer_radius = outer
	def.telegraph_time = 0.0
	return def

func _test_the_ledger_is_a_sliding_sum_on_the_source_clock(t) -> void:
	var body := Node2D.new()
	var source := Clocked.new(body)
	source.accumulate_landed(10.0)
	source.now = 1.0
	source.accumulate_landed(5.0)
	t.close_to(source.landed(), 15.0, "everything inside the window is summed", 0.0001)
	source.now = ExcitementSource.WINDOW + 0.5
	t.close_to(source.landed(), 5.0, "the first landing has left the window on the source's clock",
			0.0001)
	t.close_to(source.landed_ever, 15.0, "and what has ever landed is never pruned", 0.0001)
	source.accumulate_landed(0.0)
	t.close_to(source.landed_ever, 15.0, "nothing lands for a share of zero", 0.0001)
	body.free()

func _test_the_first_landing_is_told_once(t) -> void:
	var body := Node2D.new()
	var source := ExcitementSource.new(body)
	var told := [0]
	source.on_first_landing = func() -> void: told[0] += 1
	source.accumulate_landed(0.0)
	t.check(told[0] == 0, "a share of nothing is not a landing")
	source.accumulate_landed(2.0)
	source.accumulate_landed(3.0)
	t.check(told[0] == 1, "the first landing is told, and only once (%d)" % told[0])
	body.free()

## The relationship the halo's colours rest on: each source's net, summed, is the bar's own rise
## while the decay is under what landed, and every net is zero together once it is not.
func _test_the_nets_sum_to_the_bar_rise(t) -> void:
	var landed := [12.0, 5.0, 3.0]
	var total := 20.0
	for decay in [4.0, 19.0]:
		var nets := 0.0
		for points: float in landed:
			nets += ExcitementSource.net_landed(points, total, decay)
		t.close_to(nets, total - decay, "the nets sum to what landed less the decay (%.0f)" % decay,
				0.0001)
	var none := 0.0
	for points: float in landed:
		none += ExcitementSource.net_landed(points, total, 25.0)
	t.check(none == 0.0, "a decay past everything landed leaves every net at zero")

func _test_an_event_caches_its_rate_on_its_age(t) -> void:
	var instance := EventInstance.new()
	instance.setup(_def("cached", 20.0), Vector2.ZERO)
	var source := instance.excitement
	var at := Vector2(60.0, 0.0)
	var first := source.contribution_at(at)
	t.check(first > 0.0 and first == instance.field_at(at, -1.0, Vector2.INF),
			"an event's rate on open ground is its field (%.2f/s)" % first)
	instance.def.intensity = 40.0
	t.check(source.contribution_at(at) == first,
			"asked again at the same age and point, the cached rate answers")
	source.invalidate_contribution()
	t.check(source.contribution_at(at) > first,
			"invalidated, it is worked out again from the field as it now stands")
	t.check(source.contribution_at(Vector2(1000.0, 0.0)) == 0.0,
			"and a point past its reach is charged nothing")
	instance.free()

func _test_an_event_caret_reads_where_its_instance_says_she_is(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(2000.0, 0.0)]))
	for _i in int(ceil(def.telegraph_time / 0.1)) + 1:
		instance.step(0.1)
	instance.player_at = instance.global_position + Vector2(def.lethal_reach() * 0.5, 0.0)
	t.check(instance.excitement.caret_strength() == 2,
			"her place told to the instance by its manager is where the caret measures her from")
	instance.player_at = instance.global_position + Vector2(0.0, def.outer_radius * 4.0)
	t.check(instance.excitement.caret_strength() == 0,
			"and the answer moves with her inside one tick, keyed on where she is")
	instance.excitement.set_player_at(instance.global_position + Vector2(10.0, 0.0))
	t.check(instance.player_at == instance.global_position + Vector2(10.0, 0.0),
			"the halo's word on where she is reaches the instance too")
	instance.free()

func _test_an_outranked_source_projects_nothing(t) -> void:
	var instance := EventInstance.new()
	var def := _def("moving", 30.0)
	def.mobile = true
	def.speed = 80.0
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(2000.0, 0.0)]))
	var her := Vector2(200.0, 0.0)
	var gross := instance.excitement.expected_gross_at(her)
	instance.excitement.outranked = true
	t.check(gross > 0.0 and instance.excitement.expected_gross_at(her) == 0.0,
			"a source outranked by another projects nothing (%.2f before)" % gross)
	instance.free()

func _test_a_crowd_body_is_never_cached(t) -> void:
	var walker := CrowdAgent.new()
	walker.kind = CrowdAgent.Kind.WALKER
	var at := Vector2(Tuning.PEDESTRIAN_INNER_RADIUS * 0.5, 0.0)
	var before := walker.excitement.contribution_at(at)
	walker.position = Vector2(-Tuning.PEDESTRIAN_OUTER_RADIUS * 3.0, 0.0)
	t.check(before > 0.0 and walker.excitement.contribution_at(at) == 0.0,
			"a body moved from outside its own frame answers from where it is, its clock unmoved")
	walker.position = Vector2.ZERO
	walker.excitement.startle(30.0, 1.0, 45.0, Tuning.CAR_HORN_OUTER_RADIUS)
	t.check(walker.excitement.contribution_at(at) > before,
			"and a startle shows on the same frame it happens")
	walker.free()

func _test_a_crowd_body_jolt_widens_its_set(t) -> void:
	var crowd := Crowd.new()
	var narrow := crowd.sources.silent_beyond()
	var car := CrowdAgent.new()
	car.excitement.heard_in = crowd.sources
	car.kind = CrowdAgent.Kind.CAR
	car.excitement.startle(30.0, 1.0, 45.0, 900.0)
	t.check(crowd.sources.silent_beyond() >= 900.0 / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
			and crowd.sources.silent_beyond() > narrow,
			"a jolt wider than any body's field widens what its crowd's sweep skips beyond")
	car.free()
	crowd.free()

func _test_a_held_door_is_the_whole_answer(t) -> void:
	var world := WorldContext.new()
	var door_body := Node2D.new()
	var street_body := Node2D.new()
	var door := Fixed.new()
	door.pairs = [[ExcitementSource.new(door_body), 7.0]]
	var street := Fixed.new()
	street.pairs = [[ExcitementSource.new(street_body), 3.0]]
	world.excitement_sources = [door, street]
	t.close_to(world.total_excitement_at(Vector2.ZERO), 10.0,
			"with nobody held, every set's pairs are summed", 0.0001)
	t.check(world.excitement_sources_at(Vector2.ZERO).size() == 2
			and world.excitement_sources_at(Vector2.ZERO)[0] == door.pairs[0],
			"in the sets' own order")
	door.alone = true
	t.close_to(world.total_excitement_at(Vector2.ZERO), 7.0,
			"inside a held door its toll is the whole answer", 0.0001)
	world.excitement_sources = [street, door]
	t.close_to(world.total_excitement_at(Vector2.ZERO), 7.0,
			"whichever order the sets are handed in", 0.0001)
	door_body.free()
	street_body.free()
	world.free()
