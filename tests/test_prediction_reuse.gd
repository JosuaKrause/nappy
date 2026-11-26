extends RefCounted
## Exact projection parity under same-frame writes, with counters on actual sampled work.
##
## The sources are real events, not fakes, so that the suite stands on the event's own field: the
## projection is that field reprojected, which no fake can answer without logic of its own.
##
## **The suite writes private members of the event and the crowd body it projects from**, one
## input at a time (an event's row and its heading, and a crowd body's axis, `_direction`,
## turn-back hold and jolt fields, some through a name held in a variable), reads the event's
## `_where` (where she hears it) to hand it back, and overrides `_sample_expected_landed()` to
## count the samplings really run. No game path changes one input of a source alone, and a
## cache over the projection has to notice exactly that, so the writes are what the suite
## proves; a suite that reached only what the game reaches would never test the cache's key.
## The reference (`tests/fixtures/prediction_reference.gd`) works out its reach from the tuning
## and what the body answers publicly, so a wrong reach in the source fails the parity.

const Reference = preload("res://tests/fixtures/prediction_reference.gd")
const HaloRig = preload("res://tests/halo_rig.gd")

## The length of the straight route the sweep's events are set up on.
const ROUTE_LENGTH := 600.0

## An event's source that keeps the motion the halo last told it (`set_her_motion()`), which the
## frozen reference projects and scales by as the source does, and the total it last told
## (`set_expected_total_gross()`), which the halo's own parity is held against.
class ToldEventSource extends EventExcitement:
	var told_velocity := Vector2.ZERO
	var told_sensitivity := 1.0
	var told_total := -1.0

	## Overrides ExcitementSource.set_expected_total_gross.
	func set_expected_total_gross(total: float) -> void:
		told_total = total
		super(total)

	## Overrides ExcitementSource.set_her_motion.
	func set_her_motion(velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
			sensitivity: float = 1.0) -> void:
		told_velocity = velocity
		told_sensitivity = sensitivity
		super(velocity, decay_rate, sensitivity)

## A crowd body's source that keeps the motion the halo last told it, as `ToldEventSource`.
class ToldCrowdSource extends CrowdExcitement:
	var told_velocity := Vector2.ZERO
	var told_sensitivity := 1.0

	## Overrides ExcitementSource.set_her_motion.
	func set_her_motion(velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
			sensitivity: float = 1.0) -> void:
		told_velocity = velocity
		told_sensitivity = sensitivity
		super(velocity, decay_rate, sensitivity)

## Open ground whose street runs east-west from the line x = 0 eastward and north-south west of
## it, so an event moved across the line is stood by the other street's answers
## (`BodyStance.of()`).
class SplitStreets extends WorldMap:
	## Overrides WorldMap.corridor_offsets.
	func corridor_offsets(tile: Vector2i) -> Vector2i:
		return Vector2i(-1, 0) if tile.x >= 0 else Vector2i(0, -1)

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

	func _init(agent_kind := Kind.WALKER) -> void:
		super(agent_kind)
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
			return Reference.event_gross(_event, at, told_velocity, told_sensitivity)

## A crowd body whose source projects with the frozen reference instead.
class ReferenceCrowd extends CrowdAgent:
	func _init(agent_kind := Kind.WALKER) -> void:
		super(agent_kind)
		var rim: SourceRim = _excitement.rim()
		_excitement = Source.new(self)
		_excitement.use_rim(rim)

	class Source extends ToldCrowdSource:
		## Overrides ExcitementSource.expected_gross_at.
		func expected_gross_at(at: Vector2) -> float:
			return Reference.crowd_gross(_agent, at, told_velocity, told_sensitivity)

func run(t: TestRunner) -> void:
	_test_catalogue_and_mutations(t)
	_test_a_cored_row(t)
	_test_crowd_mutations(t)
	_test_a_crowd_body_is_projected_out_to_the_reach_its_kind_has(t)
	_test_a_body_heading_towards_her_is_projected_out_to_its_grown_reach(t)
	_test_a_startled_body_is_projected_out_to_its_jolt_reach(t)
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
	return original.redraft()

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
	if definition.pursues():
		var chasing := _draft_of(definition)
		chasing.pursuit(definition.pursuit().at_speed(definition.pursuit().speed() + 3.0))
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

## An event of a copy of `definition` set up on the route and the streets the sweep runs on, hearing
## `where`, in the tree when it is a flock, whose birds are built there as the game builds them.
func _swept_event(t: TestRunner, definition: EventDef, where: WhereSheIs) -> CountedEvent:
	var event := CountedEvent.new()
	event.setup(_copy_definition(definition), Vector2.ZERO,
		PackedVector2Array([Vector2.ZERO, Vector2(ROUTE_LENGTH, 0.0)]), Vector2.RIGHT,
		EventSurroundings.new().reading(Shipped.rows()).on(SplitStreets.new()) \
		.hearing(where))
	if event.row().is_a_flock():
		t.add_child(event)
		event.set_process(false)
	return event

## A second event of `definition` put back from `saved` and set walking as the sweep's phases left
## her, its answer at `at` asked once so the cache holds it.
func _projecting_copy(t: TestRunner, definition: EventDef, saved: EventSave,
		at: Vector2) -> CountedEvent:
	var copy := _swept_event(t, definition, WhereSheIs.nowhere())
	copy.restore(saved)
	copy.source().set_her_motion(Vector2(92.0, 0.0), 6.0, 0.8)
	_event_parity(t, copy, at, definition.id() + " before its end")
	return copy

## What the frozen reference projects from `source` at `at`.
func _reference_of(source: CountedEvent, at: Vector2) -> float:
	var told := source.source() as ToldEventSource
	return Reference.event_gross(source, at, told.told_velocity, told.told_sensitivity)

## One if what a write just made moved the reference's answer off `before`, else none.
func _count_a_move(source: CountedEvent, at: Vector2, before: float) -> int:
	return 0 if _same_bits(_reference_of(source, at), before) else 1

func _event_parity(t: TestRunner, source: CountedEvent, at: Vector2, label: String) -> void:
	var told := source.source() as ToldEventSource
	var expected := Reference.event_gross(source, at, told.told_velocity, told.told_sensitivity)
	t.check(_same_bits(source.source().expected_gross_at(at), expected), label + " matches reference")
	var runs := source.sampling_runs
	t.check(_same_bits(source.source().expected_gross_at(at), expected), label + " repeats exactly")
	if source.birds().is_empty():
		t.check(source.sampling_runs == runs, label + " repeats without sampling")

func _crowd_parity(t: TestRunner, source: CountedCrowd, at: Vector2, label: String) -> void:
	var told := source.mood() as ToldCrowdSource
	var expected := Reference.crowd_gross(source, at, told.told_velocity, told.told_sensitivity)
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
	var row := Shipped.rows().by_id("leaf_blower")
	var field := row.field()
	var inside := Vector2(-(field.core_within() * 0.5), 0.0)
	var between := Vector2(-(field.core_within() + (field.core_reach() - field.core_within()) * 0.5), 0.0)
	var where := WhereSheIs.nowhere()
	var source := CountedEvent.new()
	source.setup(_copy_definition(row), Vector2.ZERO,
		PackedVector2Array([Vector2.ZERO, Vector2(600.0, 0.0)]), Vector2.RIGHT,
		EventSurroundings.new().reading(Shipped.rows()).hearing(where))
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
	var retiring := EventManager.new(Shipped.rows(), EventSurroundings.new())
	var sampled := 0
	var positive := 0
	var flock_queries := 0
	# The rows each kind of phase write moved the answer on.
	var moved := {"noticed": 0, "lunged": 0, "silenced": 0, "leaving": 0, "retired": 0}
	for definition: EventDef in CatalogueRows.every():
		var source_where := WhereSheIs.nowhere()
		var source := _swept_event(t, definition, source_where)
		_event_parity(t, source, Vector2(80.0, 0.0), definition.id() + " before player")
		for phase: float in [0.0, 0.7, 4.0, 9.0]:
			source.restore(EventSave.aged(phase))
			for at: Vector2 in [Vector2(-170.0, 30.0), Vector2(20.0, 30.0), Vector2(1000.0, 0.0)]:
				source.source().set_her_motion(Vector2(92.0, 0.0), 6.0, 0.8)
				_event_parity(t, source, at, definition.id() + " phase/position")
				if source.source().expected_gross_at(at) > 0.0:
					positive += 1
		var projecting := source.save()
		var at := Vector2(-170.0, 30.0)
		source.source().set_her_motion(Vector2(92.0, 0.0))
		# All writes happen without advancing age or the engine frame.
		source.position += Vector2(9.0, 4.0)
		_event_parity(t, source, at, definition.id() + " source movement")
		source._heading = Vector2.DOWN
		_event_parity(t, source, at, definition.id() + " source heading")
		# What a phase change moves among the cache's terms is asked of each write by the answer
		# before it and after it, and the sweep counts the rows that answer moved on.
		var before := _reference_of(source, at)
		if source.row().waits_for_her():
			# The streaming restore of a row that had noticed her, at the age it has: it starts
			# the notice and moves to its warning.
			source.restore(EventSave.new(source.age(), source.save().travelled(), source.age()))
			_event_parity(t, source, at, definition.id() + " noticed")
			moved["noticed"] += _count_a_move(source, at, before)
			before = _reference_of(source, at)
			# Streamed back in a minute after it noticed her, which no notice in the catalogue runs.
			source.restore(EventSave.new(source.age(), source.save().travelled(),
					source.age() - 60.0))
			_event_parity(t, source, at, definition.id() + " lunged")
			moved["lunged"] += _count_a_move(source, at, before)
		source.source().set_her_motion(Vector2(43.0, 71.0))
		_event_parity(t, source, at, definition.id() + " player velocity")
		source.source().set_her_motion(Vector2(43.0, 71.0), 0.0, 0.35)
		_event_parity(t, source, at, definition.id() + " sensitivity")
		var before_the_chat: Dictionary = {}
		if source.detains_her():
			before_the_chat = source.save().state_of("EventHold")
			source.start_chat()
			_event_parity(t, source, at, definition.id() + " chatting")
		source_where.tell(at, Vector2.INF, null, false, false)
		_event_parity(t, source, at, definition.id() + " sleep")
		if source.detains_her():
			# The hold is put back as the game's own save of it made before the chat, so the
			# checks below run with no hold running and with no departure or release in the way.
			source.restore(EventSave.new(0.0, 0.0, INF, {"EventHold": before_the_chat}))
		source.source().set_outranked(true)
		_event_parity(t, source, at, definition.id() + " outranked")
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
			_event_parity(t, source, at, definition.id() + " its own row before a different " + label)
			_under_a_different_row(source, others[label] as EventDef)
			_event_parity(t, source, at, definition.id() + " a different " + label)
		_under_a_different_row(source, own_row)
		_event_parity(t, source, at, definition.id() + " its own row again")
		# A row of another shape is a second row, as the field's settings are: the shape is not
		# replaced under the live event.
		var reshaping := _draft_of(definition)
		reshaping.body(own_row.body().reshaped(GroundShape.segment(17.0, 12.0)))
		var reshaped_row := reshaping.build()
		_under_a_different_row(source, reshaped_row)
		_event_parity(t, source, at, definition.id() + " shape replacement")
		var boxed := _draft_of(definition)
		boxed.body(own_row.body().reshaped(GroundShape.rect(Vector2(52.0, 8.0))))
		_under_a_different_row(source, boxed.build())
		_event_parity(t, source, at, definition.id() + " shape kind/extents")
		# Moved across the line where the street turns, so the body and its look are handed the
		# stance the other street gives, as the game hands it (`EventInstance.move_to()`).
		source.move_to(Vector2(-300.0, 0.0) if source.global_position.x >= 0.0
				else Vector2(300.0, 0.0))
		_event_parity(t, source, at, definition.id() + " body axis")
		var shapeless := _draft_of(definition)
		shapeless.body(BodySpec.none())
		var shapeless_row := shapeless.build()
		_under_a_different_row(source, shapeless_row)
		_event_parity(t, source, at, definition.id() + " no shape")
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
			_event_parity(t, source, at, definition.id() + " bird geometry")
			t.check(source.sampling_runs > runs, "flock always samples its mutable birds")
		# The ends come last, each on an event of its own that comes back from the save the phases
		# left: this one has been moved off and had its row replaced, so it projects nothing at her,
		# and a stale answer from before an end and the fresh one would be the same 0.
		var leaver := _projecting_copy(t, definition, projecting, at)
		before = _reference_of(leaver, at)
		if definition.is_a_mast():
			# Nothing silences a row but a mast.
			leaver.silence()
			_event_parity(t, leaver, at, definition.id() + " silence")
			moved["silenced"] += _count_a_move(leaver, at, before)
		else:
			leaver.leave_for_a_completed_task()
			_event_parity(t, leaver, at, definition.id() + " leaving")
			moved["leaving"] += _count_a_move(leaver, at, before)
		var ended := _projecting_copy(t, definition, projecting, at)
		before = _reference_of(ended, at)
		retiring.retire(ended)
		_event_parity(t, ended, at, definition.id() + " retired")
		moved["retired"] += _count_a_move(ended, at, before)
		sampled += source.sampling_runs + leaver.sampling_runs + ended.sampling_runs
		ended.free()
		leaver.free()
		source.free()
	t.check(sampled > 100 and positive > 20, "catalogue sweep samples live positive projections")
	t.check(flock_queries > 0, "flock bypass assertions exercise constructed birds")
	for write: String in moved:
		t.check((moved[write] as int) > 0,
				"the %s write moved the answer on %d rows" % [write, moved[write]])
	retiring.free()

func _test_crowd_mutations(t: TestRunner) -> void:
	for kind: LaneMover.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var source := CountedCrowd.new(kind)
		# The mover's own pace, set the way its strategy sets it: eased to the wanted one in
		# one step.
		source.lane().ease_speed_toward(60.0, 1000.0)
		var at := Vector2(-160.0, 12.0)
		_crowd_parity(t, source, at, "crowd before player")
		source.mood().set_her_motion(Vector2(92.0, 0.0))
		_crowd_parity(t, source, at, "crowd player")
		source.lane().ease_speed_toward(source.speed() + 1.25, 1000.0)
		_crowd_parity(t, source, at, "crowd pace")
		for field: String in ["_direction", "_turn_back_hold"]:
			source.set(field, float(source.get(field)) + 1.25)
			_crowd_parity(t, source, at, "crowd external " + field)
		for field: String in ["_jolt", "_jolt_for", "_jolt_intensity", "_jolt_inner", "_jolt_outer"]:
			source.mood().set(field, float(source.mood().get(field)) + 1.25)
			_crowd_parity(t, source, at, "crowd external " + field)
		# A yield and a door hold are a walker's, kept by its strategy; a car has neither.
		var walking := kind == CrowdAgent.Kind.WALKER
		if walking:
			# Somebody walks into it against its own way, so it waits for a moment.
			var along := (Vector2.DOWN if source.lane().is_vertical() else Vector2.RIGHT) \
					* -source.lane().direction()
			source.lane().strategy().step_aside(along, 0.0, 1.25)
			_crowd_parity(t, source, at, "crowd yield")
		source.mood().startle(80.0, 2.0, 30.0, 170.0)
		_crowd_parity(t, source, at, "crowd new horn/bump")
		source.position += Vector2(33.0, 8.0)
		_crowd_parity(t, source, at, "crowd external displacement")
		source._vertical = not source._vertical
		_crowd_parity(t, source, at, "crowd heading")
		if walking:
			# The yield ends where the walker forgets what it was dodging; the door is entered
			# the way the crowd's tick walks it in: seen ahead, joined and waited at.
			var walker := source.lane().strategy()
			walker.forget_the_detour()
			var hut := WalkerDoorHold.new()
			hut.stand_at(source.position)
			source.lane().see_a_door_ahead(hut, 0.0)
			walker.advance_the_door_hold(0.0)
			_crowd_parity(t, source, at, "crowd door hold")
			# The hut is let go of where the walker waits (the way the game does when the hut is
			# no longer ahead), so the release moves nothing but the door's state.
			source.lane().clear_the_door_ahead()
			walker.advance_the_door_hold(0.0)
			_crowd_parity(t, source, at, "crowd door release")
		# An about-face, the half turn of 16px radius between the two lanes of one carriageway.
		var turn := CarTurn.about_face(false, 1.0, 0, CrowdLanes.road_lane(false, 1.0), 0.0, 0.0,
				CrowdLanes.road_lane(false, -1.0), Vector2i(-1, -1))
		source.take_the_turn(turn, 0.0)
		for distance: float in [0.0, 3.0, 9.0, 15.0]:
			turn.travel_on(distance - turn.distance_travelled())
			_crowd_parity(t, source, at, "crowd changing turn tangent")
		source.drop_the_turn()
		source.mood().set_her_motion(Vector2(0.0, 92.0))
		_crowd_parity(t, source, at, "crowd player velocity")
		source.mood().set_her_motion(Vector2(0.0, 92.0), 0.0, 0.22)
		_crowd_parity(t, source, at, "crowd sensitivity")
		_crowd_parity(t, source, at + Vector2(20.0, 0.0), "crowd query position")
		source.free()

## A crowd body's source projects out to the reach its kind has, worked out by the reference from
## the tuning and the body's public answers rather than asked of the source: her far enough away
## that only the end of the horizon brings her into the body's field (four fifths of its outer
## radius), where a source with a shorter reach skips a projection the reference makes.
func _test_a_crowd_body_is_projected_out_to_the_reach_its_kind_has(t: TestRunner) -> void:
	for kind: LaneMover.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var source := CountedCrowd.new(kind)
		var her := Vector2(92.0, 0.0)
		source.mood().set_her_motion(her)
		var outer := Tuning.CAR_OUTER_RADIUS if kind == CrowdAgent.Kind.CAR \
				else Tuning.PEDESTRIAN_OUTER_RADIUS
		var closing := (her - source.velocity()).length()
		var at := Vector2(-(closing * Tuning.EXPECTED_IMPACT_HORIZON + outer * 0.8), 0.0)
		var told := source.mood() as ToldCrowdSource
		t.check(Reference.crowd_gross(source, at, told.told_velocity, told.told_sensitivity) > 0.0,
			"the end of the horizon brings her into the field of kind %d" % kind)
		_crowd_parity(t, source, at, "crowd near the end of its reach, kind %d" % kind)
		source.free()

## A body heading towards her at the top of its kind's speed is projected out to the reach its
## field has dead ahead, `Field.scale()` times its outer radius: she stands midway between the
## outer radius and that grown one beyond the distance the two close in the horizon, so her end
## point lies in the forward field. The margin to each break is half the growth, `outer * (scale -
## 1) / 2` (2.6 px for a walker, 30.5 px for a car): a source reach without the growth skips a
## projection the reference makes.
func _test_a_body_heading_towards_her_is_projected_out_to_its_grown_reach(t: TestRunner) -> void:
	for kind: LaneMover.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var car := kind == CrowdAgent.Kind.CAR
		var outer := Tuning.CAR_OUTER_RADIUS if car else Tuning.PEDESTRIAN_OUTER_RADIUS
		var top_speed := Tuning.CAR_SPEED.y if car else Tuning.PEDESTRIAN_SPEED.y
		var source := CountedCrowd.new(kind)
		source.lane().ease_speed_toward(top_speed, 1000.0)
		source.mood().set_her_motion(Vector2.ZERO)
		var grown := outer * Field.scale(Field.eccentricity(top_speed))
		var at := Vector2(source.velocity().length() * Tuning.EXPECTED_IMPACT_HORIZON
				+ (outer + grown) * 0.5, 0.0)
		var told := source.mood() as ToldCrowdSource
		t.check(Reference.crowd_gross(source, at, told.told_velocity, told.told_sensitivity) > 0.0,
			"her end point lies in the forward field of kind %d" % kind)
		_crowd_parity(t, source, at, "crowd heading towards her, kind %d" % kind)
		source.free()

## A startled body is projected out to its jolt's outer radius where that reaches further than its
## kind's: it stands still and she walks towards it, her end point at four fifths of a jolt whose
## outer radius is three times the kind's. A source reach without the jolt term falls short by
## `0.8 * 3 * outer - outer * scale` (37 px for a walker, 84.5 px for a car).
func _test_a_startled_body_is_projected_out_to_its_jolt_reach(t: TestRunner) -> void:
	for kind: LaneMover.Kind in [CrowdAgent.Kind.WALKER, CrowdAgent.Kind.CAR]:
		var car := kind == CrowdAgent.Kind.CAR
		var outer := Tuning.CAR_OUTER_RADIUS if car else Tuning.PEDESTRIAN_OUTER_RADIUS
		var jolt_outer := outer * 3.0
		var source := CountedCrowd.new(kind)
		source.lane().ease_speed_toward(0.0, 1000.0)
		var her := Vector2(92.0, 0.0)
		source.mood().set_her_motion(her)
		source.mood().startle(80.0, 30.0, jolt_outer * 0.25, jolt_outer)
		var at := Vector2(-(her.length() * Tuning.EXPECTED_IMPACT_HORIZON + jolt_outer * 0.8), 0.0)
		var told := source.mood() as ToldCrowdSource
		t.check(Reference.crowd_gross(source, at, told.told_velocity, told.told_sensitivity) > 0.0,
			"her end point lies in the jolt of kind %d" % kind)
		_crowd_parity(t, source, at, "crowd startled, kind %d" % kind)
		source.free()

func _test_live_net_and_skipped_work(t: TestRunner) -> void:
	var event := CountedEvent.new()
	event.setup(_copy_definition(Shipped.rows().by_id("cafe_tables")), Vector2.ZERO)
	var crowd := CountedCrowd.new()
	crowd.lane().ease_speed_toward(0.0, 1000.0)
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
	var car := CountedCrowd.new(CrowdAgent.Kind.CAR)
	var reference_car := ReferenceCrowd.new(CrowdAgent.Kind.CAR)
	cached.setup(_copy_definition(Shipped.rows().by_id("cyclist")), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(700.0, 0.0)]), Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).hearing(cached_where))
	reference.setup(_copy_definition(Shipped.rows().by_id("cyclist")), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(700.0, 0.0)]), Vector2.RIGHT,
			EventSurroundings.new().reading(Shipped.rows()).hearing(reference_where))
	for source: CrowdAgent in [car, reference_car]:
		source.lane().ease_speed_toward(80.0, 1000.0)
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
		var manager := EventManager.new(Shipped.rows(), EventSurroundings.new())
		t.add_child(manager)
		# After it enters the tree: entering turns on the tick of a node that defines one.
		manager.set_physics_process(false)
		managers.append(manager)
		var source: EventInstance = CountedEvent.new() if cached else ReferenceEvent.new()
		source.setup(_copy_definition(Shipped.rows().by_id("cafe_tables")),
				Vector2.ZERO,
				PackedVector2Array(), Vector2.RIGHT, EventSurroundings.new() \
				.reading(Shipped.rows()).drawn_from(atlas))
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
		t.check(_same_bits((sources[0].source() as ToldEventSource).told_total,
				(sources[1].source() as ToldEventSource).told_total),
				"real halo publishes identical totals")
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
