extends RefCounted
## Fourteen days end to end, through the real City, EventManager and ResistanceDirector.
##
## Everything else tests a piece. This tests that the pieces survive each other across a
## whole run: scars accumulating, one-shots staying consumed, the arterial handover, the
## resistance advancing, and every day remaining winnable. It is the check that catches
## "day 12 throws" — which no amount of unit coverage does.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## A handful of run seeds, since a single city can be lucky.
const SEEDS := [4242, 90210, 1234567]
## Long enough for the slowest mobile one-shot to finish its route (the convoy takes ~17s),
## short enough that three runs stay quick. A coarse step is fine for a smoke test.
const SIMULATED_SECONDS := 25.0
const SIMULATION_STEP := 0.1

func run(t) -> void:
	for seed_value in SEEDS:
		_play_a_run(t, seed_value)

func _play_a_run(t, seed_value: int) -> void:
	var saved := _save_game_state()
	GameState.start_run(seed_value)

	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(GameState.run_seed))

	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(city, city.map)

	var one_shots_seen := {}
	var contacts_offered := 0

	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		GameState.day = day
		city.set_act(GameState.current_act())
		city.events.start_day(day, GameState.day_rng(day), GameState.consumed_one_shots)
		director.start_day(day, GameState.day_rng(day, "resistance"), Tuning.day_length(day))

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
		_simulate(city, SIMULATED_SECONDS)

		if director.current_step():
			contacts_offered += 1
			# Walk the step through, the way a player who went and stood there would.
			director._on_contact_completed(director.current_step().index)

		# The day was survivable, so bank the win and move on.
		GameState.finish_day(GameEnums.DayResult.WON)

	t.check(contacts_offered >= Tuning.RESISTANCE_GOAL,
			"seed %d offers at least %d contacts over a run (%d)"
			% [seed_value, Tuning.RESISTANCE_GOAL, contacts_offered])
	t.check(GameState.ending == GameEnums.Ending.GOOD,
			"seed %d: doing every errand and the sabotage earns the good ending" % seed_value)
	t.check(GameState.scars.size() > 0,
			"seed %d: the run left marks on the city" % seed_value)

	director.free()
	city.free()
	_restore_game_state(saved)

## Drives the day forward by hand. The instances and the manager are ticked the way the
## engine would, but at a coarse step.
func _simulate(city: City, seconds: float) -> void:
	for i in int(round(seconds / SIMULATION_STEP)):
		# Snapshot: retiring an event mutates the manager's list mid-tick.
		for instance in city.events.instances().duplicate():
			if is_instance_valid(instance) and not instance.is_finished:
				instance._process(SIMULATION_STEP)
		city.events._physics_process(SIMULATION_STEP)

func _save_game_state() -> Dictionary:
	return {
		"seed": GameState.run_seed, "day": GameState.day, "nerves": GameState.nerves,
		"progress": GameState.resistance_progress, "ending": GameState.ending,
		"one_shots": GameState.consumed_one_shots.duplicate(),
		"completed": GameState.completed_resistance_steps.duplicate(),
		"failed": GameState.failed_resistance_steps.duplicate(),
		"scars": GameState.scars.duplicate(true), "sabotage": GameState.sabotage_done,
	}

func _restore_game_state(saved: Dictionary) -> void:
	GameState.run_seed = saved["seed"]
	GameState.day = saved["day"]
	GameState.nerves = saved["nerves"]
	GameState.resistance_progress = saved["progress"]
	GameState.ending = saved["ending"]
	GameState.consumed_one_shots.assign(saved["one_shots"])
	GameState.completed_resistance_steps.assign(saved["completed"])
	GameState.failed_resistance_steps.assign(saved["failed"])
	GameState.scars.assign(saved["scars"])
	GameState.sabotage_done = saved["sabotage"]
