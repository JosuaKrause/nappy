extends RefCounted
## Exact projection parity under same-frame writes, with counters on actual sampled work.

const Reference = preload("res://tests/fixtures/prediction_reference.gd")

class CountedEvent extends EventInstance:
	var sampling_runs := 0

	func _sample_expected_landed(at: Vector2, vel: Vector2, intensity: float) -> float:
		sampling_runs += 1
		return super._sample_expected_landed(at, vel, intensity)

class CountedCrowd extends CrowdAgent:
	var sampling_runs := 0

	func _sample_expected_landed(at: Vector2, vel: Vector2) -> float:
		sampling_runs += 1
		return super._sample_expected_landed(at, vel)

class ReferenceEvent extends EventInstance:
	func expected_gross_at(at: Vector2) -> float:
		return Reference.event_gross(self, at)

class ReferenceCrowd extends CrowdAgent:
	func expected_gross_at(at: Vector2) -> float:
		return Reference.crowd_gross(self, at)

func run(t) -> void:
	_test_catalogue_and_mutations(t)
	_test_crowd_mutations(t)
	_test_live_net_and_skipped_work(t)
	_test_consumer_order(t)
	_test_halo_and_removal(t)

func _same_bits(a: float, b: float) -> bool:
	return var_to_bytes(a) == var_to_bytes(b)

func _copy_definition(original: EventDef) -> EventDef:
	var copy := original.duplicate(true) as EventDef
	# RefCounted geometry is not a stored Resource property, so duplicate() omits it.
	if original.shape:
		copy.shape = GroundShape.new(original.shape.half_length, original.shape.radius)
		copy.shape.kind = original.shape.kind
		copy.shape.half_extents = original.shape.half_extents
	copy.solid_parts = original.solid_parts
	return copy

func _event_parity(t, source: CountedEvent, at: Vector2, label: String) -> void:
	var expected := Reference.event_gross(source, at)
	t.check(_same_bits(source.expected_gross_at(at), expected), label + " matches reference")
	var runs := source.sampling_runs
	t.check(_same_bits(source.expected_gross_at(at), expected), label + " repeats exactly")
	if source._flock.is_empty():
		t.check(source.sampling_runs == runs, label + " repeats without sampling")

func _crowd_parity(t, source: CountedCrowd, at: Vector2, label: String) -> void:
	var expected := Reference.crowd_gross(source, at)
	t.check(_same_bits(source.expected_gross_at(at), expected), label + " matches reference")
	var runs := source.sampling_runs
	t.check(_same_bits(source.expected_gross_at(at), expected), label + " repeats exactly")
	t.check(source.sampling_runs == runs, label + " repeats without sampling")

func _test_catalogue_and_mutations(t) -> void:
	var sampled := 0
	var positive := 0
	var flock_queries := 0
	for definition: EventDef in EventCatalogue.all():
		var source := CountedEvent.new()
		source.setup(_copy_definition(definition), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)]))
		if source.def.flock_size > 0:
			source._build_the_flock()
		_event_parity(t, source, Vector2(80.0, 0.0), definition.id + " before player")
		for phase: float in [0.0, 0.7, 4.0, 9.0]:
			source.age = phase
			for at: Vector2 in [Vector2(-170.0, 30.0), Vector2(20.0, 30.0), Vector2(1000.0, 0.0)]:
				source.set_player_at(at, Vector2(92.0, 0.0), 6.0, 0.8)
				_event_parity(t, source, at, definition.id + " phase/position")
				if source.expected_gross_at(at) > 0.0:
					positive += 1
		var at := Vector2(-170.0, 30.0)
		source.set_player_at(at, Vector2(92.0, 0.0))
		# All writes happen without advancing age or the engine frame.
		source.position += Vector2(9.0, 4.0)
		_event_parity(t, source, at, definition.id + " source movement")
		source._heading = Vector2.DOWN
		_event_parity(t, source, at, definition.id + " source heading")
		source._noticed_at = source.age
		_event_parity(t, source, at, definition.id + " noticed")
		source._lunged = true
		_event_parity(t, source, at, definition.id + " lunged")
		source.is_parked = true
		_event_parity(t, source, at, definition.id + " parked")
		source.is_parked = false
		source.player_velocity = Vector2(43.0, 71.0)
		_event_parity(t, source, at, definition.id + " player velocity")
		source.player_sensitivity = 0.35
		_event_parity(t, source, at, definition.id + " sensitivity")
		source.silenced = true
		_event_parity(t, source, at, definition.id + " silence")
		source.silenced = false
		if source.def.detain_seconds > 0.0:
			source._chat_seconds_left = 1.0
			_event_parity(t, source, at, definition.id + " chatting")
		source.baby_awake = false
		_event_parity(t, source, at, definition.id + " sleep")
		source._chat_seconds_left = 0.0
		source.outranked_by_a_stronger_barrier = true
		_event_parity(t, source, at, definition.id + " outranked")
		source.outranked_by_a_stronger_barrier = false
		for field: String in ["intensity", "inner_radius", "outer_radius", "core_intensity",
				"core_radius", "falloff_power", "pulse_period", "speed", "pursue_speed"]:
			source.def.set(field, float(source.def.get(field)) + 3.0)
			_event_parity(t, source, at, definition.id + " mutable " + field)
		source.def.shape = GroundShape.segment(17.0, 12.0)
		_event_parity(t, source, at, definition.id + " shape replacement")
		source.def.shape.half_length = 63.0
		_event_parity(t, source, at, definition.id + " shape length mutation")
		source.def.shape.kind = GroundShape.Kind.RECT
		source.def.shape.half_extents = Vector2(52.0, 8.0)
		_event_parity(t, source, at, definition.id + " shape kind/extents mutation")
		source._spread_vertical = not source._spread_vertical
		source._stationary_vehicle_side = not source._stationary_vehicle_side
		_event_parity(t, source, at, definition.id + " body axis")
		source.def.shape = null
		_event_parity(t, source, at, definition.id + " no shape")
		source.def = _copy_definition(definition)
		_event_parity(t, source, at, definition.id + " definition replacement")
		if not source._flock.is_empty():
			flock_queries += 1
			var runs := source.sampling_runs
			source._flock[0].at += Vector2(17.0, 4.0)
			source._flock[0].heading = Vector2.LEFT
			source._flock[0].speed += 10.0
			_event_parity(t, source, at, definition.id + " bird geometry")
			t.check(source.sampling_runs > runs, "flock always samples its mutable birds")
		source.is_leaving = true
		_event_parity(t, source, at, definition.id + " leaving")
		source.is_leaving = false
		source._finish()
		_event_parity(t, source, at, definition.id + " retired")
		sampled += source.sampling_runs
		source.free()
	t.check(sampled > 100 and positive > 20, "catalogue sweep samples live positive projections")
	t.check(flock_queries > 0, "flock bypass assertions exercise constructed birds")

func _test_crowd_mutations(t) -> void:
	for kind: int in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var source := CountedCrowd.new()
		source.kind = kind
		source._speed = 60.0
		var at := Vector2(-160.0, 12.0)
		_crowd_parity(t, source, at, "crowd before player")
		source.set_player_at(at, Vector2(92.0, 0.0))
		_crowd_parity(t, source, at, "crowd player")
		for field: String in ["_speed", "_direction", "_yield_left", "_turn_back_hold",
				"_jolt", "_jolt_for", "_jolt_intensity", "_jolt_inner", "_jolt_outer"]:
			source.set(field, float(source.get(field)) + 1.25)
			_crowd_parity(t, source, at, "crowd external " + field)
		source.startle(80.0, 2.0, 30.0, 170.0)
		_crowd_parity(t, source, at, "crowd new horn/bump")
		source.position += Vector2(33.0, 8.0)
		_crowd_parity(t, source, at, "crowd external displacement")
		source._vertical = not source._vertical
		_crowd_parity(t, source, at, "crowd heading")
		source._yield_left = 0.0
		source._door_state = CrowdAgent.DoorState.INSPECTION
		_crowd_parity(t, source, at, "crowd door hold")
		source._door_state = CrowdAgent.DoorState.WALKING
		_crowd_parity(t, source, at, "crowd door release")
		var turn := CarTurn.new()
		turn.radius = 16.0
		turn.sweep = PI
		source._turn = turn
		source._turn_run_up = 0.0
		for distance: float in [0.0, 3.0, 9.0, 15.0]:
			turn.travelled = distance
			_crowd_parity(t, source, at, "crowd changing turn tangent")
		source._turn = null
		source.player_velocity = Vector2(0.0, 92.0)
		_crowd_parity(t, source, at, "crowd player velocity")
		source.player_sensitivity = 0.22
		_crowd_parity(t, source, at, "crowd sensitivity")
		_crowd_parity(t, source, at + Vector2(20.0, 0.0), "crowd query position")
		source.kind = CrowdAgent.Kind.CAR if kind == CrowdAgent.Kind.WALKER else CrowdAgent.Kind.WALKER
		_crowd_parity(t, source, at, "crowd kind")
		source.free()

func _test_live_net_and_skipped_work(t) -> void:
	var event := CountedEvent.new()
	event.setup(_copy_definition(EventCatalogue.by_id("cafe_tables")), Vector2.ZERO)
	var crowd := CountedCrowd.new()
	crowd._speed = 0.0
	var at := Vector2(-170.0, 0.0)
	for source in [event, crowd]:
		source.set_player_at(at, Vector2(92.0, 0.0))
		var gross: float = source.expected_gross_at(at)
		t.check(gross > 0.0 and source.sampling_runs == 1, "initial projection really samples")
		source.set_expected_total_gross(gross * 2.0)
		source.player_decay_rate = 1.0
		var net: float = source.expected_impact_at(at)
		t.check(_same_bits(net, maxf(gross - 2.5, 0.0)), "total/decay affect net immediately")
		source.player_sensitivity = 0.5
		t.check(_same_bits(source.expected_gross_at(at), gross * 0.5), "sensitivity stays live")
		t.check(source.sampling_runs == 1, "total/decay/sensitivity reuse only the integral")
		# Below approximate-comparison tolerance, but a distinct representable Vector2 value.
		source.player_velocity += Vector2(0.00001, 0.0)
		source.expected_gross_at(at)
		t.check(source.sampling_runs == 2, "even a tiny changed trajectory samples without a tick")
	event.free()
	crowd.free()

func _test_consumer_order(t) -> void:
	var cached := CountedEvent.new()
	var reference := ReferenceEvent.new()
	var car := CountedCrowd.new()
	var reference_car := ReferenceCrowd.new()
	for source: EventInstance in [cached, reference]:
		source.setup(_copy_definition(EventCatalogue.by_id("cyclist")), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(700.0, 0.0)]))
	for source: CrowdAgent in [car, reference_car]:
		source.kind = CrowdAgent.Kind.CAR
		source._speed = 80.0
	# Same source callback -> halo gross/total -> drawing order as production. The reference
	# sources use the baseline gross function even when called from existing caret methods.
	for step in 20:
		var at := Vector2(210.0 - float(step) * 4.0, 20.0)
		cached.age += 0.1
		reference.age = cached.age
		car._clock += 0.1
		reference_car._clock = car._clock
		cached.player_at = at
		reference.player_at = at
		t.check(cached._caret_strength() == reference._caret_strength(), "pre-halo event mark parity")
		t.check(car._caret_strength() == reference_car._caret_strength(), "pre-halo car mark parity")
		for source in [cached, reference, car, reference_car]:
			source.set_player_at(at, Vector2(-92.0, 0.0), 6.0, 0.8)
		var total := cached.expected_gross_at(at) + car.expected_gross_at(at)
		var reference_total := reference.expected_gross_at(at) + reference_car.expected_gross_at(at)
		t.check(_same_bits(total, reference_total), "halo total parity")
		for source in [cached, reference, car, reference_car]:
			source.set_expected_total_gross(total)
		t.check(_same_bits(cached.expected_impact_at(at), reference.expected_impact_at(at)), "event net parity")
		t.check(_same_bits(car.expected_impact_at(at), reference_car.expected_impact_at(at)), "car net parity")
		t.check(cached._picture_key() == reference._picture_key(), "redraw/caret key parity")
		t.check(car._caret_strength() == reference_car._caret_strength(), "draw car mark parity")
		t.check(cached.will_be_lethal(at) == reference.will_be_lethal(at), "event lethal prediction parity")
		t.check(car.will_be_lethal(at) == reference_car.will_be_lethal(at), "car lethal prediction parity")
	for source in [cached, reference, car, reference_car]:
		source.free()

func _test_halo_and_removal(t) -> void:
	var managers: Array[EventManager] = []
	var halos: Array[ExcitementHalo] = []
	var sources: Array[EventInstance] = []
	var player := CharacterBody2D.new()
	t.add_child(player)
	player.position = Vector2(-40.0, 0.0)
	player.velocity = Vector2(92.0, 0.0)
	var baby := Baby.new()
	for cached: bool in [true, false]:
		var manager := EventManager.new()
		t.add_child(manager)
		managers.append(manager)
		var source: EventInstance = CountedEvent.new() if cached else ReferenceEvent.new()
		source.setup(_copy_definition(EventCatalogue.by_id("cafe_tables")), Vector2.ZERO)
		source.age = 3.0
		manager.add_child(source)
		source.set_process(false)
		manager._instances.append(source)
		source.accumulate_landed(20.0)
		sources.append(source)
		var halo := ExcitementHalo.new()
		t.add_child(halo)
		halo.setup(manager, null, player, baby)
		halos.append(halo)
	for tick in 3:
		for halo: ExcitementHalo in halos:
			halo._process(0.1)
		t.check(_same_bits(sources[0].player_expected_total_gross,
				sources[1].player_expected_total_gross), "real halo publishes identical totals")
		t.check(sources[0]._halo._target_colour == sources[1]._halo._target_colour,
				"real halo selection/color agrees with baseline source")
		t.check(_same_bits(sources[0]._halo._target_alpha, sources[1]._halo._target_alpha),
				"real halo strength agrees with baseline source")
		t.check(sources[0]._caret_strength() == sources[1]._caret_strength(),
				"post-halo caret agrees with baseline source")
		if tick == 0:
			t.check(sources[0]._halo._target_alpha > 0.0,
					"real halo comparison selects a source rather than two empty sets")
			player.velocity = Vector2(43.0, 12.0)
		if tick == 1:
			for i in managers.size():
				managers[i].retire(sources[i])
	# Removal changes the candidate set immediately; no source-global cache outlives it.
	for manager: EventManager in managers:
		manager._instances.clear()
	for halo: ExcitementHalo in halos:
		halo._process(0.1)
		t.check(halo._candidates.is_empty(), "removed source absent from real halo pass")
		halo.free()
	for manager: EventManager in managers:
		manager.free()
	player.free()
	baby.free()
