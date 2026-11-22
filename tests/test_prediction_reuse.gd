extends RefCounted
## Exact projection parity under same-frame writes, with counters on actual sampled work.

const Reference = preload("res://tests/fixtures/prediction_reference.gd")
const HaloRig = preload("res://tests/halo_rig.gd")

## An event's source that keeps the sensitivity the halo last told it (`set_her_motion()`), which the
## frozen reference scales its projection by as the source scales its own.
class ToldEventSource extends EventExcitement:
	var told_sensitivity := 1.0

	## Overrides ExcitementSource.set_her_motion.
	func set_her_motion(velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
			sensitivity: float = 1.0) -> void:
		told_sensitivity = sensitivity
		super(velocity, decay_rate, sensitivity)

## A crowd body's source that keeps the sensitivity the halo last told it, as `ToldEventSource`.
class ToldCrowdSource extends CrowdExcitement:
	var told_sensitivity := 1.0

	## Overrides ExcitementSource.set_her_motion.
	func set_her_motion(velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
			sensitivity: float = 1.0) -> void:
		told_sensitivity = sensitivity
		super(velocity, decay_rate, sensitivity)

## An event whose source counts the samplings it really runs.
class CountedEvent extends EventInstance:
	var sampling_runs: int:
		get:
			return (_excitement as Source).sampling_runs

	func _init() -> void:
		super()
		var rim: SourceRim = _excitement.rim()
		_excitement = Source.new(self)
		_excitement.use_rim(rim)

	class Source extends ToldEventSource:
		var sampling_runs := 0

		## Overrides ExcitementSource._sample_expected_landed.
		func _sample_expected_landed(at: Vector2, vel: Vector2) -> float:
			sampling_runs += 1
			return super(at, vel)

## A crowd body whose source counts the samplings it really runs.
class CountedCrowd extends CrowdAgent:
	var sampling_runs: int:
		get:
			return (_excitement as Source).sampling_runs

	func _init() -> void:
		super()
		var rim: SourceRim = _excitement.rim()
		_excitement = Source.new(self)
		_excitement.use_rim(rim)

	class Source extends ToldCrowdSource:
		var sampling_runs := 0

		## Overrides ExcitementSource._sample_expected_landed.
		func _sample_expected_landed(at: Vector2, vel: Vector2) -> float:
			sampling_runs += 1
			return super(at, vel)

## An event whose source projects with the frozen reference instead.
class ReferenceEvent extends EventInstance:
	func _init() -> void:
		super()
		var rim: SourceRim = _excitement.rim()
		_excitement = Source.new(self)
		_excitement.use_rim(rim)

	class Source extends ToldEventSource:
		## Overrides ExcitementSource.expected_gross_at.
		func expected_gross_at(at: Vector2) -> float:
			return Reference.event_gross(_event, at, told_sensitivity)

## A crowd body whose source projects with the frozen reference instead.
class ReferenceCrowd extends CrowdAgent:
	func _init() -> void:
		super()
		var rim: SourceRim = _excitement.rim()
		_excitement = Source.new(self)
		_excitement.use_rim(rim)

	class Source extends ToldCrowdSource:
		## Overrides ExcitementSource.expected_gross_at.
		func expected_gross_at(at: Vector2) -> float:
			return Reference.crowd_gross(_agent, at, told_sensitivity)

func run(t: TestRunner) -> void:
	_test_catalogue_and_mutations(t)
	_test_a_cored_row(t)
	_test_crowd_mutations(t)
	_test_live_net_and_skipped_work(t)
	_test_consumer_order(t)
	await _test_halo_and_removal(t)

func _same_bits(a: float, b: float) -> bool:
	return var_to_bytes(a) == var_to_bytes(b)

func _copy_definition(original: EventDef) -> EventDef:
	return _draft_of(original).build()

## A draft of `original`'s copy, to write what the copy differs in before it is built.
func _draft_of(original: EventDef) -> EventDraft:
	# Shallow, as every copy of a row is: the row's parts are values, shared by reference between a row
	# and its copies.
	var copy := original.redraft()
	# The body is shared like every part, but a check changes its shape in place, so the copy stands
	# as a shape of its own (every other thing the body says is kept).
	if original.ground_shape():
		var shape := GroundShape.new(original.ground_shape().half_length, original.ground_shape().radius)
		shape.kind = original.ground_shape().kind
		shape.half_extents = original.ground_shape().half_extents
		copy.body(original.body().reshaped(shape))
	return copy

## The rows that differ from `definition` in one setting of its field (but its core, which only a
## cored row has: `_test_a_cored_row()`), its speed (a row that moves) or its chase speed, by the setting's name, each
## made as the game makes a row: a refinement of the row's field part or a copy with its pursuit at
## another speed.
func _rows_differing_in_one_setting(definition: EventDef) -> Dictionary:
	var field := definition.field()
	var fields := {
		"peak": field.at_peak(field.peak() + 3.0),
		"inner radius": field.holding_to(lerpf(field.core_within(), field.heard_within(), 0.5)),
		"outer radius": field.reaching(field.heard_within() + 3.0),
		"falloff": field.falling_off(field.falloff() + 3.0),
		"pulse": field.pulsing_every(field.pulses_every() + 3.0),
	}
	var rows := {}
	for label: String in fields:
		var row := _draft_of(definition)
		row.field(fields[label] as FieldSpec)
		rows[label] = row.build()
	if definition.moves():
		var faster := _draft_of(definition)
		faster.route(_route_at_another_speed(definition.route(), definition.speed() + 3.0))
		rows["speed"] = faster.build()
	if definition.pursuit:
		var chasing := _draft_of(definition)
		chasing.pursuit(definition.pursuit.at_speed(definition.pursuit.speed() + 3.0))
		rows["chase speed"] = chasing.build()
	return rows

## The route `route` walks at `speed` and is otherwise the same: its kind, its length, whether it
## paces and whether it stops where it arrives.
func _route_at_another_speed(route: RouteSpec, speed: float) -> RouteSpec:
	var other := RouteSpec.at(speed, route.kind()).up_to_tiles(route.tiles())
	if route.paces_a_beat():
		other = other.pacing()
	if route.parks_where_it_arrives():
		other = other.parking_where_it_arrives()
	return other

## Hands a live event another row, as its own and its source's: what a row replaced under an event
## would be, which the game never does and a cache over the row has to survive.
func _under_a_different_row(event: CountedEvent, row: EventDef) -> void:
	event._def = row
	event.source().use_row_and_where_she_is(row, event._where)

func _event_parity(t: TestRunner, source: CountedEvent, at: Vector2, label: String) -> void:
	var expected := Reference.event_gross(source, at,
			(source.source() as ToldEventSource).told_sensitivity)
	t.check(_same_bits(source.source().expected_gross_at(at), expected), label + " matches reference")
	var runs := source.sampling_runs
	t.check(_same_bits(source.source().expected_gross_at(at), expected), label + " repeats exactly")
	if source.birds().is_empty():
		t.check(source.sampling_runs == runs, label + " repeats without sampling")

func _crowd_parity(t: TestRunner, source: CountedCrowd, at: Vector2, label: String) -> void:
	var expected := Reference.crowd_gross(source, at,
			(source.mood() as ToldCrowdSource).told_sensitivity)
	t.check(_same_bits(source.mood().expected_gross_at(at), expected), label + " matches reference")
	var runs := source.sampling_runs
	t.check(_same_bits(source.mood().expected_gross_at(at), expected), label + " repeats exactly")
	t.check(source.sampling_runs == runs, label + " repeats without sampling")

## **The core's two settings, held where they can be told apart**: on the one row that has a core
## (the leaf blower), at a point inside its inner radius (where the core's rate is the price) and at
## one between its inner radius and its reach (where the reach is). Each is varied by a second row
## with that one setting changed, handed to the same source after the row's own, and the answers
## must differ from the row's own (so the check cannot be passing on equal numbers) and match the
## reference.
func _test_a_cored_row(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("leaf_blower")
	var field := row.field()
	var inside := Vector2(-(field.core_within() * 0.5), 0.0)
	var between := Vector2(-(field.core_within() + (field.core_reach() - field.core_within()) * 0.5), 0.0)
	var where := WhereSheIs.nowhere()
	var source := CountedEvent.new()
	source.setup(_copy_definition(row), Vector2.ZERO,
		PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)]), Vector2.RIGHT,
		EventSurroundings.new().hearing(where))
	source.restore(EventSave.aged(0.0))
	# Barely moving, so the answer is the price of the point and its surroundings, not an average over
	# a whole pass (a still baby is projected as zero).
	source.source().set_her_motion(Vector2(4.0, 0.0), 6.0, 0.8)
	var variants := {
		"core rate": [field.with_a_core(field.core_rate() + 3.0, field.core_reach()), inside],
		"core reach": [field.with_a_core(field.core_rate(), field.core_reach() + 3.0), between],
	}
	for label: String in variants:
		var at: Vector2 = (variants[label] as Array)[1]
		var differing := _draft_of(row)
		differing.field((variants[label] as Array)[0] as FieldSpec)
		var other := differing.build()
		_under_a_different_row(source, row)
		_event_parity(t, source, at, "the leaf blower, its own row before a different " + label)
		var own_answer := source.source().expected_gross_at(at)
		_under_a_different_row(source, other)
		_event_parity(t, source, at, "the leaf blower, a different " + label)
		t.check(not _same_bits(source.source().expected_gross_at(at), own_answer),
				"a different " + label + " gives the leaf blower another answer at that point")
	source.free()

func _test_catalogue_and_mutations(t: TestRunner) -> void:
	# What retires an instance from outside its tick (`EventManager.retire()`).
	var retiring := EventManager.new()
	var sampled := 0
	var positive := 0
	var flock_queries := 0
	for definition: EventDef in EventCatalogue.all():
		var source_where := WhereSheIs.nowhere()
		var source := CountedEvent.new()
		source.setup(_copy_definition(definition), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)]), Vector2.RIGHT,
			EventSurroundings.new().hearing(source_where))
		if source.row().is_a_flock():
			source.flock.build()
		_event_parity(t, source, Vector2(80.0, 0.0), definition.id + " before player")
		for phase: float in [0.0, 0.7, 4.0, 9.0]:
			source.restore(EventSave.aged(phase))
			for at: Vector2 in [Vector2(-170.0, 30.0), Vector2(20.0, 30.0), Vector2(1000.0, 0.0)]:
				source.source().set_her_motion(Vector2(92.0, 0.0), 6.0, 0.8)
				_event_parity(t, source, at, definition.id + " phase/position")
				if source.source().expected_gross_at(at) > 0.0:
					positive += 1
		var at := Vector2(-170.0, 30.0)
		source.source().set_her_motion(Vector2(92.0, 0.0))
		# All writes happen without advancing age or the engine frame.
		source.position += Vector2(9.0, 4.0)
		_event_parity(t, source, at, definition.id + " source movement")
		source._heading = Vector2.DOWN
		_event_parity(t, source, at, definition.id + " source heading")
		if source.row().notice:
			source._notice_her()
		else:
			source.transition(EventInstance.Phase.WARNING)
		_event_parity(t, source, at, definition.id + " noticed")
		source.transition(EventInstance.Phase.ACTIVE)
		_event_parity(t, source, at, definition.id + " lunged")
		source.transition(EventInstance.Phase.PARKED)
		_event_parity(t, source, at, definition.id + " parked")
		source.transition(EventInstance.Phase.ACTIVE)
		source.source().set_her_motion(Vector2(43.0, 71.0))
		_event_parity(t, source, at, definition.id + " player velocity")
		source.source().set_her_motion(Vector2(43.0, 71.0), 0.0, 0.35)
		_event_parity(t, source, at, definition.id + " sensitivity")
		if source.detains_her():
			source.hold.start()
			_event_parity(t, source, at, definition.id + " chatting")
		source_where.tell(at, Vector2.INF, Rect2(), false, false)
		_event_parity(t, source, at, definition.id + " sleep")
		if source.hold:
			source.hold.stop()
		source.source().set_outranked(true)
		_event_parity(t, source, at, definition.id + " outranked")
		source.source().set_outranked(false)
		# A row can no longer be told apart from another by being changed, so each setting the
		# projection reads is held by a second row that differs in that one setting, handed to the
		# same source as its own: a cache that did not notice the other row answers the first row's
		# number, which the reference does not.
		var own_row := source.row()
		var others := _rows_differing_in_one_setting(definition)
		for label: String in others:
			# The cache holds the last answer, so the row's own is asked first: a cache that does
			# not notice the other row hands that one back.
			_under_a_different_row(source, own_row)
			_event_parity(t, source, at, definition.id + " its own row before a different " + label)
			_under_a_different_row(source, others[label] as EventDef)
			_event_parity(t, source, at, definition.id + " a different " + label)
		_under_a_different_row(source, own_row)
		_event_parity(t, source, at, definition.id + " its own row again")
		# A row of another shape is a second row, as the field's settings are: the shape is not
		# replaced under the live event.
		var reshaping := _draft_of(definition)
		reshaping.body(own_row.body().reshaped(GroundShape.segment(17.0, 12.0)))
		var reshaped_row := reshaping.build()
		_under_a_different_row(source, reshaped_row)
		_event_parity(t, source, at, definition.id + " shape replacement")
		source.ground_shape().half_length = 63.0
		_event_parity(t, source, at, definition.id + " shape length mutation")
		source.ground_shape().kind = GroundShape.Kind.RECT
		source.ground_shape().half_extents = Vector2(52.0, 8.0)
		_event_parity(t, source, at, definition.id + " shape kind/extents mutation")
		source._body._spread_vertical = not source._body._spread_vertical
		source._body._stationary_vehicle_side = not source._body._stationary_vehicle_side
		_event_parity(t, source, at, definition.id + " body axis")
		var shapeless := _draft_of(definition)
		shapeless.body(BodySpec.none())
		var shapeless_row := shapeless.build()
		_under_a_different_row(source, shapeless_row)
		_event_parity(t, source, at, definition.id + " no shape")
		# No row is replaced under a live event: its behaviours (`EventBehaviours.compose()`) and its
		# excitement source (`EventExcitement.use_row_and_where_she_is()`) answer from the row they
		# were handed as it was set up. A flock, whose birds are never cached, is asked again with
		# its birds moved.
		if not source.birds().is_empty():
			flock_queries += 1
			var runs := source.sampling_runs
			source.birds()[0].place(source.birds()[0].at() + Vector2(17.0, 4.0))
			source.birds()[0].face(Vector2.LEFT)
			source.birds()[0].speed += 10.0
			_event_parity(t, source, at, definition.id + " bird geometry")
			t.check(source.sampling_runs > runs, "flock always samples its mutable birds")
		# Silenced last: nothing un-silences a live event, and a leaving or a retired one answers 0
		# silenced or not, so the two checks after it still hold their own phases.
		source.silence()
		_event_parity(t, source, at, definition.id + " silence")
		source.transition(EventInstance.Phase.LEAVING)
		_event_parity(t, source, at, definition.id + " leaving")
		source.transition(EventInstance.Phase.ACTIVE)
		retiring.retire(source)
		_event_parity(t, source, at, definition.id + " retired")
		sampled += source.sampling_runs
		source.free()
	t.check(sampled > 100 and positive > 20, "catalogue sweep samples live positive projections")
	t.check(flock_queries > 0, "flock bypass assertions exercise constructed birds")
	retiring.free()

func _test_crowd_mutations(t: TestRunner) -> void:
	for kind: LaneMover.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var source := CountedCrowd.new()
		source.kind = kind
		source._speed = 60.0
		var at := Vector2(-160.0, 12.0)
		_crowd_parity(t, source, at, "crowd before player")
		source.mood().set_her_motion(Vector2(92.0, 0.0))
		_crowd_parity(t, source, at, "crowd player")
		for field: String in ["_speed", "_direction", "_turn_back_hold"]:
			source.set(field, float(source.get(field)) + 1.25)
			_crowd_parity(t, source, at, "crowd external " + field)
		for field: String in ["_jolt", "_jolt_for", "_jolt_intensity", "_jolt_inner", "_jolt_outer"]:
			source.mood().set(field, float(source.mood().get(field)) + 1.25)
			_crowd_parity(t, source, at, "crowd external " + field)
		# A yield and a door hold are a walker's, kept by its strategy; a car has neither.
		var walking := kind == CrowdAgent.Kind.WALKER
		if walking:
			(source.lane().strategy() as WalkerStrategy)._yield_left += 1.25
			_crowd_parity(t, source, at, "crowd external _yield_left")
		source.mood().startle(80.0, 2.0, 30.0, 170.0)
		_crowd_parity(t, source, at, "crowd new horn/bump")
		source.position += Vector2(33.0, 8.0)
		_crowd_parity(t, source, at, "crowd external displacement")
		source._vertical = not source._vertical
		_crowd_parity(t, source, at, "crowd heading")
		if walking:
			var walker := source.lane().strategy() as WalkerStrategy
			walker._yield_left = 0.0
			walker._door_state = WalkerStrategy.DoorState.INSPECTION
			_crowd_parity(t, source, at, "crowd door hold")
			walker._door_state = WalkerStrategy.DoorState.WALKING
			_crowd_parity(t, source, at, "crowd door release")
		# An about-face, the half turn of 16px radius between the two lanes of one carriageway.
		var turn := CarTurn.about_face(false, 1.0, 0, CrowdLanes.road_lane(false, 1.0), 0.0, 0.0,
				CrowdLanes.road_lane(false, -1.0), Vector2i(-1, -1))
		source.take_the_turn(turn, 0.0)
		for distance: float in [0.0, 3.0, 9.0, 15.0]:
			turn.travelled = distance
			_crowd_parity(t, source, at, "crowd changing turn tangent")
		source.drop_the_turn()
		source.mood().set_her_motion(Vector2(0.0, 92.0))
		_crowd_parity(t, source, at, "crowd player velocity")
		source.mood().set_her_motion(Vector2(0.0, 92.0), 0.0, 0.22)
		_crowd_parity(t, source, at, "crowd sensitivity")
		_crowd_parity(t, source, at + Vector2(20.0, 0.0), "crowd query position")
		source.kind = CrowdAgent.Kind.CAR if kind == CrowdAgent.Kind.WALKER else CrowdAgent.Kind.WALKER
		_crowd_parity(t, source, at, "crowd kind")
		source.free()

func _test_live_net_and_skipped_work(t: TestRunner) -> void:
	var event := CountedEvent.new()
	event.setup(_copy_definition(EventCatalogue.by_id("cafe_tables")), Vector2.ZERO)
	var crowd := CountedCrowd.new()
	crowd._speed = 0.0
	var at := Vector2(-170.0, 0.0)
	_check_live_net_and_skipped_work(t, event.source(), func() -> int: return event.sampling_runs, at)
	_check_live_net_and_skipped_work(t, crowd.mood(), func() -> int: return crowd.sampling_runs, at)
	event.free()
	crowd.free()

## One source's projection stays live under what she does and reuses its integral: `sampling_runs`
## answers how many samplings the source has really run.
func _check_live_net_and_skipped_work(t: TestRunner, source: ExcitementSource, sampling_runs: Callable,
		at: Vector2) -> void:
	var walking := Vector2(92.0, 0.0)
	source.set_her_motion(walking)
	var gross: float = source.expected_gross_at(at)
	t.check(gross > 0.0 and int(sampling_runs.call()) == 1, "initial projection really samples")
	source.set_expected_total_gross(gross * 2.0)
	source.set_her_motion(walking, 1.0)
	var net: float = source.expected_impact_at(at)
	t.check(_same_bits(net, maxf(gross - 2.5, 0.0)), "total/decay affect net immediately")
	source.set_her_motion(walking, 1.0, 0.5)
	t.check(_same_bits(source.expected_gross_at(at), gross * 0.5), "sensitivity stays live")
	t.check(int(sampling_runs.call()) == 1, "total/decay/sensitivity reuse only the integral")
	# Below approximate-comparison tolerance, but a distinct representable Vector2 value.
	source.set_her_motion(walking + Vector2(0.00001, 0.0), 1.0, 0.5)
	source.expected_gross_at(at)
	t.check(int(sampling_runs.call()) == 2, "even a tiny changed trajectory samples without a tick")

func _test_consumer_order(t: TestRunner) -> void:
	var cached_where := WhereSheIs.nowhere()
	var cached := CountedEvent.new()
	var reference_where := WhereSheIs.nowhere()
	var reference := ReferenceEvent.new()
	var car := CountedCrowd.new()
	var reference_car := ReferenceCrowd.new()
	cached.setup(_copy_definition(EventCatalogue.by_id("cyclist")), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(700.0, 0.0)]), Vector2.RIGHT,
			EventSurroundings.new().hearing(cached_where))
	reference.setup(_copy_definition(EventCatalogue.by_id("cyclist")), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(700.0, 0.0)]), Vector2.RIGHT,
			EventSurroundings.new().hearing(reference_where))
	for source: CrowdAgent in [car, reference_car]:
		source.kind = CrowdAgent.Kind.CAR
		source._speed = 80.0
	var sources: Array[ExcitementSource] = [cached.source(), reference.source(), car.mood(),
			reference_car.mood()]
	# Same source callback -> halo gross/total -> drawing order as production. The reference
	# sources use the baseline gross function even when called from existing caret methods.
	for step in 20:
		var at := Vector2(210.0 - float(step) * 4.0, 20.0)
		cached.restore(EventSave.aged(cached.age() + 0.1))
		reference.restore(EventSave.aged(cached.age()))
		car.mood().advance(0.1)
		reference_car.mood().advance(0.1)
		cached_where.tell(at)
		reference_where.tell(at)
		t.check(cached.source().caret_strength() == reference.source().caret_strength(), "pre-halo event mark parity")
		t.check(car.mood().caret_strength() == reference_car.mood().caret_strength(), "pre-halo car mark parity")
		for source in sources:
			source.set_her_motion(Vector2(-92.0, 0.0), 6.0, 0.8)
		var total := cached.source().expected_gross_at(at) + car.mood().expected_gross_at(at)
		var reference_total := reference.source().expected_gross_at(at) + reference_car.mood().expected_gross_at(at)
		t.check(_same_bits(total, reference_total), "halo total parity")
		for source in sources:
			source.set_expected_total_gross(total)
		t.check(_same_bits(cached.source().expected_impact_at(at), reference.source().expected_impact_at(at)), "event net parity")
		t.check(_same_bits(car.mood().expected_impact_at(at), reference_car.mood().expected_impact_at(at)), "car net parity")
		# The picture key's one term that reads the prediction is the caret's strength; every other
		# term reads state the two instances share by construction.
		t.check(cached.source().caret_strength() == reference.source().caret_strength(),
				"event mark parity after the halo's total")
		t.check(car.mood().caret_strength() == reference_car.mood().caret_strength(), "draw car mark parity")
		t.check(cached.source().will_be_lethal(at) == reference.source().will_be_lethal(at), "event lethal prediction parity")
		t.check(car.mood().will_be_lethal(at) == reference_car.mood().will_be_lethal(at), "car lethal prediction parity")
	for body: Node in [cached, reference, car, reference_car]:
		body.free()

## `[colour, alpha]` the halo last told a source's rim, or a transparent colour and zero when it
## holds no rim: an event builds its rim only once `ExcitementHalo` picks it and gives it back once
## faded (`EventInstance.Rim`), so a missing rim is a rim told nothing.
static func _rim_target(rim: HaloRig.ToldRim) -> Array:
	if not rim.is_held():
		return [Color(0.0, 0.0, 0.0, 0.0), 0.0]
	return [rim.colour, rim.strength]

## The two halos run on real frames, one pass each per frame. The managers' own tick is off
## (`set_physics_process(false)`): what is compared is the halo's pass, and the manager's would
## step the sources and sweep the retired ones out of the list between the checks.
func _test_halo_and_removal(t: TestRunner) -> void:
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	var managers: Array[EventManager] = []
	var halos: Array[ExcitementHalo] = []
	var sources: Array[EventInstance] = []
	var rims: Array[HaloRig.ToldRim] = []
	var player := CharacterBody2D.new()
	t.add_child(player)
	player.position = Vector2(-40.0, 0.0)
	player.velocity = Vector2(92.0, 0.0)
	var baby := Baby.new()
	for cached: bool in [true, false]:
		var manager := EventManager.new()
		t.add_child(manager)
		# After it enters the tree: entering turns on the tick of a node that defines one.
		manager.set_physics_process(false)
		managers.append(manager)
		var source: EventInstance = CountedEvent.new() if cached else ReferenceEvent.new()
		source.setup(_copy_definition(EventCatalogue.by_id("cafe_tables")), Vector2.ZERO,
				PackedVector2Array(), Vector2.RIGHT, EventSurroundings.new().drawn_from(atlas))
		source.restore(EventSave.aged(3.0))
		manager.add_child(source)
		source.set_process(false)
		manager.world.take_in(source)
		source.source().accumulate_landed(20.0)
		sources.append(source)
		rims.append(HaloRig.told(source))
		var halo := ExcitementHalo.new()
		var sets: Array[ExcitementSources] = [manager.excitement_sources()]
		halo.setup(sets, player, baby)
		halos.append(halo)
	for halo: ExcitementHalo in halos:
		t.add_child(halo)
	for tick in 3:
		# Until each halo has made one more pass, which tells each source's rim once (both are
		# picked or held on every tick here); bounded, so a halo that stops telling fails the checks
		# below rather than hanging the suite.
		var told := rims[0].told
		for frame in 100:
			await t.get_tree().process_frame
			if rims[0].told > told and rims[1].told == rims[0].told:
				break
		t.check(_same_bits(sources[0].source().player_expected_total_gross,
				sources[1].source().player_expected_total_gross), "real halo publishes identical totals")
		t.check(rims[0].is_held() == rims[1].is_held(),
				"real halo builds a rim for both sources or for neither")
		t.check(_rim_target(rims[0])[0] == _rim_target(rims[1])[0],
				"real halo selection/color agrees with baseline source")
		t.check(_same_bits(_rim_target(rims[0])[1], _rim_target(rims[1])[1]),
				"real halo strength agrees with baseline source")
		t.check(sources[0].source().caret_strength() == sources[1].source().caret_strength(),
				"post-halo caret agrees with baseline source")
		if tick == 0:
			t.check(_rim_target(rims[0])[1] > 0.0,
					"real halo comparison selects a source rather than two empty sets")
			player.velocity = Vector2(43.0, 12.0)
		if tick == 1:
			for i in managers.size():
				managers[i].retire(sources[i])
	for manager: EventManager in managers:
		manager.world.let_go_of_every_event()
	await t.get_tree().process_frame
	for halo: ExcitementHalo in halos:
		halo.free()
	for manager: EventManager in managers:
		manager.free()
	player.free()
	baby.free()
	atlas.release(&"events")