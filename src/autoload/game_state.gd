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

## True for the rest of a day once the resistance's package has been picked up. Read by
## `City.decay_multiplier()` — the pram is heavier for every street after this one. Reset at
## the start of every attempt at a day, including a retry, since a fresh attempt has not
## picked it up yet.
var resistance_carrying_package := false

## The chalk mark's own words, set when a pickup step completes and read out once on the
## next day brief. "" once read, or when there is nothing to say.
var pending_resistance_brief := ""

## The calm block the baby actually went to sleep in, per day: `day -> Vector2i`.
##
## Run-scoped and gameplay-owned, deliberately *not* read out of the telemetry log even though
## the `calm` entries say the same thing. Telemetry never touches gameplay, and a rule that
## reads a trace to decide tomorrow's events would be that rule broken in the loudest possible
## way — the game would play differently with `--no-telemetry`.
var settled_in: Dictionary = {}

## Where she settled yesterday, or `Vector2i(-1, -1)` if she did not settle at all.
func settled_yesterday() -> Vector2i:
	return settled_in.get(day - 1, Vector2i(-1, -1))

## Every calm area she has used **so far this act**, most recent first, today excluded.
##
## **The act, not last night.** Remembering one night spoils one park, which makes day 2 a fresh
## decision and day 3 the same decision as day 1. Remembering the act is what turns "find a
## different park" into "find your way around the city" — an act needs as many calm areas as it has
## days, plus one — and forgetting at the act boundary is what stops it becoming "there is nowhere
## left".
##
## The reset is the act's, not the calendar's: an act is where the city changes character anyway,
## so the parks going quiet again is the one piece of good news in a run that has none.
func settled_this_act() -> Array[Vector2i]:
	var start: int = Tuning.ACT_START_DAYS[Tuning.act_for_day(day) - 1]
	var used: Array[Vector2i] = []
	for past in range(day - 1, start - 1, -1):
		var block: Vector2i = settled_in.get(past, Vector2i(-1, -1))
		if block.x >= 0 and not used.has(block):
			used.append(block)
	return used

## Called when the baby falls asleep, with the calm block she is standing in. The one place
## the city learns anything about how the player actually played.
func remember_where_she_settled(block: Vector2i) -> void:
	if settled_in.has(day):
		return
	settled_in[day] = block
	Telemetry.note("calm", "settled in the calm block %s; tomorrow will know"
			% TelemetryLog.tile(block))

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
	settled_in.clear()
	sabotage_done = false
	resistance_carrying_package = false
	pending_resistance_brief = ""
	print("[GameState] run started, seed=%d" % run_seed)

## Record the outcome of the day. Returns true if the run continues.
##
## **A lost day is retried, not skipped.** A nerve buys another attempt at the same day, and the
## calendar moves only when a day is won.
##
## Three things follow, and all three are chosen rather than fallen into:
##
## - **The retry is the same day.** Everything about one is deterministic from the seed and the
##   day number — the city, the closures, the whole event plan — which is exactly what makes a
##   retry worth having in a game about learning a route.
## - **What the run has spent stays spent.** The one-shots it consumed and the block arcs it
##   advanced are run history, not day content: a fire that burnt a block down did happen.
## - **Except where she settled.** That is a fact about the attempt rather than about the run,
##   and `settled_in` is read to decide what tomorrow spoils. Left in place, an attempt that
##   reached a park and then lost the day would send tomorrow's loud event to a park she never
##   actually used — and the winning attempt could not overwrite it, because the record is written
##   once.
##
## The run can no longer end by running out of days while nerves remain, so the bad ending is
## the only way to lose and the fourteen days become a promise rather than a budget.
func finish_day(result: GameEnums.DayResult) -> bool:
	if result != GameEnums.DayResult.WON:
		nerves -= 1
		EventBus.nerves_changed.emit(nerves)
		# Which nerve went, and on which day. The nerve economy has never been tested against
		# a game that bites early, and this is the entry that will say whether it survives it —
		# a question a retry sharpens rather than settles, since five nerves now buy five
		# attempts wherever they are needed instead of five days off the calendar.
		Telemetry.note("nerve", "spent a nerve on day %d (act %d); %d left%s"
				% [day, current_act(), nerves,
				"" if nerves <= 0 else " — day %d again" % day])
		if nerves <= 0:
			_end_run(GameEnums.Ending.BAD)
			return false
		settled_in.erase(day)
		return true
	if is_final_day():
		_end_run(GameEnums.Ending.GOOD if earned_good_ending() else GameEnums.Ending.NEUTRAL)
		return false
	day += 1
	return true

func _end_run(which: GameEnums.Ending) -> void:
	ending = which
	Telemetry.note("ending", "%s on day %d — resistance %d/%d, sabotage %s" % [
		GameEnums.Ending.keys()[which].to_lower(), day,
		resistance_progress, Tuning.RESISTANCE_GOAL,
		"done" if sabotage_done else "not done"])
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

## `counts_toward_goal` is false for a pickup — the note is not the errand, only the perform
## half is, so `Tuning.RESISTANCE_GOAL` must not see the mark as well as the task it unlocked.
func complete_resistance_step(step: int, counts_toward_goal: bool = true) -> void:
	if step in completed_resistance_steps:
		return
	completed_resistance_steps.append(step)
	if counts_toward_goal:
		resistance_progress += 1
		EventBus.resistance_progress_changed.emit(resistance_progress)
	var step_def := ResistanceSteps.by_index(step)
	if step_def and step_def.is_pickup and step_def.brief != "":
		pending_resistance_brief = step_def.brief
	EventBus.resistance_step_completed.emit(step)

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
