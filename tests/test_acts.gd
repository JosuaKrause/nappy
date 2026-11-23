extends RefCounted
## The escalation: act gating, the mechanics the later acts introduced, and the invariants
## that stop a late day from being quietly unwinnable. A row and a plan are built as they are and no
## city is: the burnt building a fire leaves is `tests/test_city_buildings.gd`'s.

const SEED := 4242
const STEP := 1.0 / 60.0

var _map: CityMap

func run(t: TestRunner) -> void:
	_map = CityGenerator.generate(SEED)
	_test_acts_are_gated_by_day(t)
	_test_a_protest_grows(t)
	_test_scars_outlive_the_day_that_made_them(t)
	_test_a_park_stays_reachable_every_day(t)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

# -------------------------------------------------------------------- gating ---

func _test_acts_are_gated_by_day(t: TestRunner) -> void:
	# The boundaries themselves are `Tuning.ACT_START_DAYS` and are not restated here — a check
	# that reads that array back would only ever fail because somebody moved an act on purpose.
	# What is worth pinning is the relationship between two tables that do not know about each
	# other: the run is exactly as long as its last act, so no day falls off the end of the acts.
	t.check(Tuning.act_for_day(Tuning.RUN_LENGTH_DAYS) == 4, "the last day is act IV")

	# Nothing from a later act may leak into an earlier day. Only a `SCRIPTED` row has an act:
	# its own first day is the first day of its act (`EventDef.own_first_day()`), the one place
	# the game reads an act, and it must not come after the day the row fires on. Every other
	# row's own first day is the day it first appears, which `available_on()` already holds
	# back, and it says no act, so there is nothing to hold for it.
	var swept := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var act := Tuning.act_for_day(day)
		for def in EventCatalogue.of_kind(GameEnums.EventKind.SCRIPTED, day):
			swept += 1
			var from_act := Tuning.act_for_day(def.own_first_day())
			t.check(from_act <= act,
					"day %d (act %d) does not offer '%s' from act %d"
					% [day, act, def.id(), from_act])
	t.check(swept > 0, "the sweep checked at least one scripted row (%d)" % swept)

# ------------------------------------------------------------------ mechanics ---

## A protest swells over its life rather than holding: the peak its row carries a pulse's length
## after its telegraph, against the same pulse three quarters of the way through its life, asked of
## the row (`EventDef.peak_through()`), which is what a live event carries once its telegraph is over.
func _test_a_protest_grows(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("protest")
	var ceiling := def.peak_through(0.0, def.lasts_for(), 1.0)
	t.check(ceiling > def.peak(), "a protest swells rather than holding")
	t.check(def.pulses_every() > 0.0, "and beats, so the ramp is read over whole pulse periods")

	# Sample across whole pulse periods so the ramp, not the pulse, is what is compared.
	var from := def.telegraphs_for() + 0.05
	var early := _peak_over(def, from, def.pulses_every())
	var late := _peak_over(def, from + def.pulses_every() + def.lasts_for() * 0.75,
			def.pulses_every())
	t.check(late > early * 1.3, "a protest is markedly worse later than when you saw it")
	t.check(late <= ceiling + 0.01, "and never exceeds its stated ceiling")

## The highest peak `def` carries over the `seconds` after it is `age` seconds old, its burst
## running from the end of its telegraph.
func _peak_over(def: EventDef, age: float, seconds: float) -> float:
	var peak := 0.0
	for i in int(round(seconds / STEP)):
		var at := age + float(i + 1) * STEP
		peak = maxf(peak, def.peak_through(at, at - def.telegraphs_for()))
	return peak

## The burnt-out shell is on the same corner on day 12 as it was the morning after the fire.
func _test_scars_outlive_the_day_that_made_them(t: TestRunner) -> void:
	var run := RunState.new()
	run.start_run(SEED)
	run.header().set_day(3)
	var where := _map.tile_to_world(Vector2i(40, 40))
	run.add_scar("burnt_shell", where)
	run.add_scar("burnt_shell", where)
	t.check(run.attempt_spend().scars().size() == 1, "the same scar is not recorded twice")

	var consumed: Array[String] = []
	var same_day := GameDawn.of(DaySpec.for_day(3), _rng(3), _map).spent(consumed) \
			.scars(run.attempt_spend().scars()).plan().placements()
	t.check(not _contains(same_day, "burnt_shell"),
			"a scar does not double up on the day it was made")

	for day: int in [4, 9, 14]:
		var later: Array[String] = []
		var planned := GameDawn.of(DaySpec.for_day(day), _rng(day), _map).spent(later) \
				.scars(run.attempt_spend().scars()).plan().placements()
		t.check(_contains(planned, "burnt_shell"),
				"the burnt-out shell is still there on day %d" % day)
		for plan in planned:
			if plan.row_id() == "burnt_shell":
				t.close_to(plan.placed_at().distance_to(where), 0.0,
						"and it is on the same corner", 1.0)

func _contains(planned: Array[EventPlan], id: String) -> bool:
	for plan in planned:
		if plan.row_id() == id:
			return true
	return false

# ----------------------------------------------------------------- invariants ---

## From act II onwards several events physically close streets, and from act IV a run can
## accumulate permanent barricades. Any combination that seals the home off from every park
## makes the day unwinnable in a way the player cannot see coming.
func _test_a_park_stays_reachable_every_day(t: TestRunner) -> void:
	# Stack the deck: pretend several convoys have already left barricades around, in rings of
	# 3, 5 and 7 tiles round the home's door (a ring is what can seal the home in; four far-off
	# ones cannot), and plan every day.
	var run := RunState.new()
	run.start_run(SEED)
	var home := _map.home_rect.position
	for radius: int in [3, 5, 7]:
		for step: Vector2i in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
				Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]:
			# The run's own writer, on day 1, which is the day a scar stands from the day after.
			run.add_scar("barricade", _map.tile_to_world(home + step * radius))

	var grid := ReachabilityGrid.build(_map)
	# Day 1 runs with no scar in effect (a scar applies from the day after its `since_day`), and
	# is the plain plan whose route to a park nothing else checks.
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		var consumed: Array[String] = []
		var blockers: Array[EventPlan] = []
		for plan in GameDawn.of(DaySpec.for_day(day), _rng(day), _map).spent(consumed) \
				.scars(run.attempt_spend().scars()).plan().placements():
			if plan.obstructs():
				blockers.append(plan)
		t.check(_a_park_is_reachable(grid, blockers),
				"day %d leaves a walkable route from home to a park" % day)

## Whether the grid still finds a way from the home to some calm tile with today's closures and
## every blocker's own obstruction circle standing (`EventScheduler.blocked_by()`): what the
## scheduler keeps true of the day it plans.
func _a_park_is_reachable(grid: ReachabilityGrid, blockers: Array[EventPlan]) -> bool:
	var blocked := EventScheduler.blocked_by(_map, blockers)
	var reached := grid.flood([_map.home_rect.position], blocked)
	for tile in _map.calm_tiles():
		if grid.reaches(tile, blocked, reached):
			return true
	return false
