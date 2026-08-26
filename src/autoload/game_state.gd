extends Node
## Owns the state of a run: the seed, the calendar, nerves and resistance progress.
##
## Determinism contract (docs/ARCHITECTURE.md): nothing gameplay-relevant may call the
## global `randi()`. Layout comes from `city_rng()`, a day's events from `day_rng()`.

var run_seed: int = 0
var day: int = 1
var nerves: int = Tuning.STARTING_NERVES
var resistance_progress: int = 0
var ending: GameEnums.Ending = GameEnums.Ending.NONE

## One-shot event ids already consumed this run, so they never fire twice.
var consumed_one_shots: Array[String] = []
## Resistance steps completed, and steps failed beyond recovery.
var completed_resistance_steps: Array[int] = []
var failed_resistance_steps: Array[int] = []

## Permanent marks a one-off event left on the city: `{ id, position, since_day }`.
## The burnt-out building from day 3 is still on that corner on day 12, cordoned off and
## never repaired — the city remembers, which is most of how the escalation is told.
var scars: Array[Dictionary] = []

## Where each block currently is along its arc. Run-scoped, like everything else here: the
## arcs themselves belong to the CityMap and never change, this is only how far along them
## the run has got. See docs/CITY.md, "Block purposes".
var city_state := CityState.new()

## Whether the day-14 sabotage actually went through. Reaching RESISTANCE_GOAL earns the
## chance at the good ending; this is doing it.
var sabotage_done := false

# ------------------------------------------------------------------ lifecycle ---

## Begin a fresh run. Pass a seed to reproduce a previous city, or omit for a new one.
func start_run(seed_value: int = 0) -> void:
	run_seed = seed_value if seed_value != 0 else _new_seed()
	day = 1
	nerves = Tuning.STARTING_NERVES
	resistance_progress = 0
	ending = GameEnums.Ending.NONE
	consumed_one_shots.clear()
	completed_resistance_steps.clear()
	failed_resistance_steps.clear()
	scars.clear()
	city_state.reset()
	sabotage_done = false
	print("[GameState] run started, seed=%d" % run_seed)

## Record the outcome of the day and advance the calendar. Returns true if the run continues.
func finish_day(result: GameEnums.DayResult) -> bool:
	EventBus.day_ended.emit(result)
	if result != GameEnums.DayResult.WON:
		nerves -= 1
		EventBus.nerves_changed.emit(nerves)
		if nerves <= 0:
			_end_run(GameEnums.Ending.BAD)
			return false
	if day >= Tuning.RUN_LENGTH_DAYS:
		_end_run(GameEnums.Ending.GOOD if earned_good_ending() else GameEnums.Ending.NEUTRAL)
		return false
	day += 1
	return true

func _end_run(which: GameEnums.Ending) -> void:
	ending = which
	EventBus.run_ended.emit(which)

## Records a permanent mark, ignoring duplicates from the same spot.
func add_scar(id: String, position: Vector2) -> void:
	for scar in scars:
		if scar["id"] == id and scar["position"].distance_to(position) < 1.0:
			return
	scars.append({"id": id, "position": position, "since_day": day})

# ------------------------------------------------------------------ queries ---

func current_act() -> int:
	return Tuning.act_for_day(day)

func is_final_day() -> bool:
	return day >= Tuning.RUN_LENGTH_DAYS

func has_joined_resistance() -> bool:
	return resistance_progress > 0

## Reaching the goal is the qualification; the sabotage is the act. Both are required, so
## a player who does the legwork and then skips the last night gets the neutral ending.
func earned_good_ending() -> bool:
	return resistance_progress >= Tuning.RESISTANCE_GOAL and sabotage_done

## Whether the final sabotage is on offer at all.
func sabotage_available() -> bool:
	return resistance_progress >= Tuning.RESISTANCE_GOAL

# --------------------------------------------------------------- resistance ---

func complete_resistance_step(step: int) -> void:
	if step in completed_resistance_steps:
		return
	completed_resistance_steps.append(step)
	resistance_progress += 1
	EventBus.resistance_step_completed.emit(step)
	EventBus.resistance_progress_changed.emit(resistance_progress)

## A timed step that expired. The contact is gone for the rest of the run.
func fail_resistance_step(step: int) -> void:
	if step in failed_resistance_steps:
		return
	failed_resistance_steps.append(step)
	EventBus.resistance_step_failed.emit(step)

## Being seen near a contact costs progress but never takes it below zero.
func penalise_resistance() -> void:
	resistance_progress = maxi(0, resistance_progress - 1)
	EventBus.resistance_progress_changed.emit(resistance_progress)

# ---------------------------------------------------------------------- RNG ---

## Deterministic RNG for city layout. Same seed, same city, for the whole run.
func city_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	return rng

## Deterministic RNG for one day. `stream` separates independent consumers: without it,
## two systems asking for "the day's RNG" would both start from the same seed and their
## first rolls would move together, which is a correlation nobody asked for.
func day_rng(day_index: int = -1, stream: String = "events") -> RandomNumberGenerator:
	var d := day if day_index < 0 else day_index
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [run_seed, d, stream])
	return rng

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()
