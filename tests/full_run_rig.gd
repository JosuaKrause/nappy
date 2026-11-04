extends RefCounted
## Fourteen days end to end, through the real City, EventManager and ResistanceDirector.
##
## Everything else tests a piece. This tests that the pieces survive each other across a
## whole run: scars accumulating, one-shots staying consumed, the arterial handover, the
## resistance advancing, and every day remaining winnable. It is the check that catches
## "day 12 throws" — which no amount of unit coverage does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## Long enough for the slowest mobile one-shot to finish its route (the convoy takes ~17s).
const SIMULATED_SECONDS := 25.0
## How many times real time the engine runs the physics ticks of a played day (`PhysicsTicks.pass_ticks()`),
## so that a tick is a tenth of a second of game time, the step the suite always took by hand. A coarser
## step is not used: a mobile event moves by speed times the step and an arrival or a lifetime is read
## on a tick, so a different step could change what the suite sees, and nothing here shows it cannot.
## A day takes 250 ticks.
const SIMULATION_SCALE := 6.0

## Plays the run of `seed_value` (the parts of this suite are one seed each, so none runs two minutes
## serial).
func run(t, seed_value: int) -> void:
	await PhysicsTicks.settle(t)
	await _play_a_run(t, seed_value)

## One run: the city is built over a run of its own (`RunCity.with_own_run()`, freed with the city),
## and every day of it is started and played the way `main._start_day()` does, on real physics ticks.
func _play_a_run(t, seed_value: int) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	var run := city.run
	t.add_child(city)
	city.build(CityGenerator.generate(run.header.run_seed))
	# No player walks this run, so nothing would ever come within streaming reach. This suite is
	# about a run's whole chain — one-shots, successors, scars — which is a property of the
	# fourteen *plans*, so it puts every day in the world at once. See `EventManager`.
	city.events.stream_radius = INF

	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)

	var one_shots_seen := {}
	var contacts_offered := 0
	var events_that_moved := 0

	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		run.header.day = day
		# The city becomes today's city before anything is placed in it — the real day opens
		# the same way (`main._start_day()`), and this is where the day's region plan is built,
		# which is what the day-9 crossing task asks for when its mark is touched.
		run.attempt_spend.city_state.begin_day(city.map.block_plans, day)
		city.start_day(run.attempt_spend.city_state, day, run.calendar.day_rng(day, "closures"))

		city.set_act(run.calendar.current_act())
		city.events.start_day(DaySpec.for_day(day), run.calendar.day_rng(day), run.attempt_spend.consumed_one_shots)
		director.start_day(day, run.calendar.day_rng(day, "resistance"), Tuning.day_length(day))
		t.check(city.events.active_count() > 0, "seed %d day %d has events" % [seed_value, day])

		for instance in city.events.instances():
			t.check(is_instance_valid(instance),
					"seed %d day %d: every event is a live node" % [seed_value, day])
			if instance.def.kind == GameEnums.EventKind.ONE_SHOT:
				t.check(not one_shots_seen.has(instance.def.id),
						"seed %d: one-shot '%s' fires once in a run"
						% [seed_value, instance.def.id])
				one_shots_seen[instance.def.id] = day

		# The excitement field must be finite and sane wherever the player could stand.
		var at_home := city.map.home_world_position()
		var here := city.total_excitement_at(at_home)
		t.check(here >= 0.0 and here < 200.0,
				"seed %d day %d: excitement at home is a sane number (%.1f)"
				% [seed_value, day, here])

		# Let the day actually run for a while. Without this the mobile one-shots never
		# finish their routes, so the fire engine never leaves a fire and the convoy never
		# leaves a barricade — and the whole successor-and-scar chain goes untested.
		var placed := {}
		for instance in city.events.instances():
			placed[instance] = instance.global_position
		await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(SIMULATED_SECONDS, SIMULATION_SCALE),
				Callable(), SIMULATION_SCALE)
		for instance in placed.keys():
			if is_instance_valid(instance) and instance.global_position != placed[instance]:
				events_that_moved += 1

		if director.current_step():
			contacts_offered += 1
			# A task is one day: touching the mark announces today's task and activates its
			# perform half in the same moment (`ResistanceDirector._on_contact_completed()`), so
			# a player who does every errand touches the mark and then does what it says before
			# the day is banked — only the perform half grants progress, and nothing offers it
			# again at tomorrow's dawn. `current_step()` keeps naming the finished step until
			# the next `start_day()`, so the index comparison is what ends the walk.
			var offered: int = director.current_step().index
			_touch(director)
			while director.current_step() and director.current_step().index != offered:
				offered = director.current_step().index
				_touch(director)

		# The day was survivable, so bank the win and move on.
		run.calendar.finish_day(GameEnums.DayResult.WON)

	t.check(events_that_moved > 0,
			"seed %d: the physics ticks of the played days moved the events that travel (%d)"
			% [seed_value, events_that_moved])
	t.check(contacts_offered >= Tuning.RESISTANCE_GOAL,
			"seed %d offers at least %d contacts over a run (%d)"
			% [seed_value, Tuning.RESISTANCE_GOAL, contacts_offered])
	t.check(run.header.ending == GameEnums.Ending.GOOD,
			"seed %d: doing every errand and the sabotage earns the good ending" % seed_value)
	t.check(run.attempt_spend.scars.size() > 0,
			"seed %d: the run left marks on the city" % seed_value)

	director.free()
	city.free()

## Completes the step on offer the way her touch does: through the contact's own completion
## (`ContactPoint.complete_now()`), which the director hears.
func _touch(director: ResistanceDirector) -> void:
	var contact := director.contact()
	if contact:
		contact.complete_now()
