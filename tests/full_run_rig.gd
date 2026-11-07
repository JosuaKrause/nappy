extends RefCounted
## Fourteen days end to end, through the real City, EventManager and ResistanceDirector, each day
## started by the real DayDirector.
##
## Everything else tests a piece. This tests that the pieces survive each other across a
## whole run: scars accumulating, one-shots staying consumed, the arterial handover, the
## resistance advancing, the calm areas she used shut and every day's crowd, with the day's gates,
## street trees and fenced park run through (a throw there fails the run; nothing reads them back),
## and every day remaining winnable. It is the check that catches "day 12 throws" — which no amount
## of unit coverage does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## Long enough for the slowest mobile one-shot to finish its route (the convoy takes ~17s).
const SIMULATED_SECONDS := 25.0
## How many times real time the engine runs the physics ticks of a played day (`PhysicsTicks.pass_ticks()`),
## so that a tick is a tenth of a second of game time, the step the suite always took by hand. A coarser
## step is not used: a mobile event moves by speed times the step and an arrival or a lifetime is read
## on a tick, so a different step could change what the suite sees, and nothing here shows it cannot.
## A day takes 250 ticks.
const SIMULATION_SCALE := 6.0
## How many times faster than the project's rate the engine takes those ticks (`PhysicsTicks.pass_ticks_faster()`):
## each tick steps the game as long as before, only sooner in real time. Held near 4 because a tick of a played
## day costs the CPU several milliseconds.
const TICK_FACTOR := 4

## Plays the run of `seed_value` (the parts of this suite are one seed each, so none runs two minutes
## serial).
func run(t, seed_value: int) -> void:
	await PhysicsTicks.settle(t)
	await _play_a_run(t, seed_value)

## One run: the city is built over a run of its own (`RunCity.with_own_run()`), and every day of it
## is started the way the game starts one, through `DayDirector.start_day()` handed the pieces `main`
## hands it (the city, its events, the resistance, her, the baby and the day's clock), and played on
## real physics ticks.
func _play_a_run(t, seed_value: int) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	var run := city.run
	t.add_child(city)
	city.build(CityGenerator.generate(run.header.run_seed))
	# No player walks this run, so nothing would ever come within streaming reach. This suite is
	# about a run's whole chain — one-shots, successors, scars — which is a property of the
	# fourteen *plans*, so it puts every day in the world at once. See `EventManager`.
	city.events.stream_radius = INF

	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city.map, city.run, city.events, city.streets(), city.fronts(), city, null,
			city.spawn_siting)

	# Her, in the tree as the scene has her, so the baby takes the stroller she rides in from her
	# parent; and the day's clock, set up the way `main` sets it up, so falling asleep on calm ground
	# is remembered where the game remembers it (`DayController._remember_the_calm_she_found()`).
	# Neither walks nor ticks: nobody steers her, `main` is what ticks the clock, and the baby's
	# meters are not this suite's question — she settles when the rig says she does (`_settle()`).
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	var baby := Baby.new()
	baby.name = "Baby"
	player.add_child(baby)
	t.add_child(player)
	player.set_physics_process(false)
	baby.set_physics_process(false)
	var clock := DayController.new()
	t.add_child(clock)
	clock.setup(city.map, player, run)

	var config := RunConfig.parse(PackedStringArray(), "", true)
	var days := DayDirector.new(run.calendar, run.facts, run.attempt_spend, config)
	days.use_the_world(city, city.events, resistance, player, baby, clock)

	var one_shots_seen := {}
	var contacts_offered := 0
	var events_that_moved := 0
	var days_with_a_used_area_shut := 0
	var days_with_a_crowd := 0

	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(run.header.day == day,
				"seed %d: the calendar is on day %d (%d)" % [seed_value, day, run.header.day])
		days.start_day(DaySpec.for_day(day, config.day_length_for(day)))
		# Every area off today's tree is one she used earlier this act, the fenced park included —
		# it is chosen from the areas handed over as used, so it holds no exemption here; a wiring
		# that shut the wrong area fails on the day it does. Whether any day shuts one at all is
		# counted apart and checked once the run is over.
		var used := run.calendar.settled_this_act()
		for block: Vector2i in city.map.shut_calm:
			t.check(used.has(block),
					"seed %d day %d: calm area %s off the tree is one she used this act %s"
					% [seed_value, day, block, used])
		if not city.map.shut_calm.is_empty():
			days_with_a_used_area_shut += 1
		if city.crowd.agent_count() > 0:
			days_with_a_crowd += 1
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
		var here := 0.0
		for pair in city.excitement_sources_at(at_home):
			here += pair[1]
		t.check(here >= 0.0 and here < 200.0,
				"seed %d day %d: excitement at home is a sane number (%.1f)"
				% [seed_value, day, here])

		# Let the day actually run for a while. Without this the mobile one-shots never
		# finish their routes, so the fire engine never leaves a fire and the convoy never
		# leaves a barricade — and the whole successor-and-scar chain goes untested.
		var placed := {}
		for instance in city.events.instances():
			placed[instance] = instance.global_position
		await PhysicsTicks.pass_ticks_faster(t, PhysicsTicks.ticks_for(SIMULATED_SECONDS, SIMULATION_SCALE),
				TICK_FACTOR, Callable(), SIMULATION_SCALE)
		for instance in placed.keys():
			if is_instance_valid(instance) and instance.global_position != placed[instance]:
				events_that_moved += 1

		if resistance.current_step():
			contacts_offered += 1
			# A task is one day: touching the mark announces today's task and activates its
			# perform half in the same moment (`ResistanceDirector._on_contact_completed()`), so
			# a player who does every errand touches the mark and then does what it says before
			# the day is banked — only the perform half grants progress, and nothing offers it
			# again at tomorrow's dawn. `current_step()` keeps naming the finished step until
			# the next `start_day()`, so the index comparison is what ends the walk.
			var offered: int = resistance.current_step().index
			_touch(resistance)
			while resistance.current_step() and resistance.current_step().index != offered:
				offered = resistance.current_step().index
				_touch(resistance)

		# A won day is one she settled on: on calm ground, through the baby's own falling asleep,
		# which the clock hears and remembers (`RunCalendar.remember_where_she_settled()`) and the
		# events hear too (the return patrols owed). What she used is what the next day of the act
		# reads back through `DayDirector.start_day()` (`CityMap.set_spent_calm()`).
		_settle(city, run, player, baby)
		t.check(clock.is_running(), "seed %d day %d: the day is still under way when she settles"
				% [seed_value, day])
		t.check(run.settled.settled_in.has(day),
				"seed %d day %d: the calm she settled on is remembered" % [seed_value, day])

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
	t.check(days_with_a_used_area_shut > 0,
			"seed %d: some day takes a calm area she used off its route tree (%d days)"
			% [seed_value, days_with_a_used_area_shut])
	t.check(days_with_a_crowd == Tuning.RUN_LENGTH_DAYS,
			"seed %d: every day has its crowd (%d days)" % [seed_value, days_with_a_crowd])

	clock.free()
	player.free()
	resistance.free()
	city.free()

## Completes the step on offer the way her touch does: through the contact's own completion
## (`ContactPoint.complete_now()`), which the director hears.
func _touch(resistance: ResistanceDirector) -> void:
	var contact := resistance.contact()
	if contact:
		contact.complete_now()

## Settles her on today's calm ground the way a won day does: she stands on the calm ground
## (`CalmSpot.of()`) of the nearest calm area to home that she has not used this act and that today's
## tree has not taken off, and the baby falls asleep there (`Baby.force_sleep()`, which announces it
## as falling asleep does).
func _settle(city: City, run: RunState, player: Stroller, baby: Baby) -> void:
	var map := city.map
	var used := run.calendar.settled_this_act()
	var home := map.home_world_position()
	var best := Vector2.INF
	for block: Vector2i in map.calm_blocks:
		var anchor := map.anchor_of(block)
		if used.has(anchor) or map.shut_calm.has(anchor) or anchor == map.fenced_park:
			continue
		var spot := CalmSpot.of(map, block)
		if spot != Vector2.INF and spot.distance_to(home) < best.distance_to(home):
			best = spot
	if best != Vector2.INF:
		player.global_position = best
	baby.force_sleep()
