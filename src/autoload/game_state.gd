class_name RunState
extends Node
## Owns the state of a run: the seed, the calendar, nerves and resistance progress.
##
## Determinism contract (docs/ARCHITECTURE.md): nothing gameplay-relevant may call the
## global `randi()`. Layout comes from `city_rng()`, a day's events from `calendar.day_rng()`.

## The run's state is kept in registered parts (`RunSubState`), each declaring its own fields, its
## dawn copies and their save shape once; starting a run, the dawn photograph, a lost day's
## give-back, the snapshot and the save all walk this list (`RunStateRegistry`). **A part declared
## here and not registered is caught by `tests/test_run_state.gd`**. Readers take the part
## (`run.header.day`, `run.attempt_spend.scars`), and nothing forwards to a part.
##
## **The `GameState` autoload is where the run lives**, since it outlives the scene reloads (the
## held restart, the day-14 hand-over, a run carried to its checkpoint). `main`, the composition
## root, takes it once and hands it, typed `RunState`, to `GameSave` and to every reader it builds,
## so a test hands a reader whichever run it built; the events and the resistance (`src/events/`,
## `src/resistance/`) still read it off the autoload.
var run_parts := RunStateRegistry.new()
var header: RunHeader = run_parts.register(RunHeader.new())
var resistance: ResistanceRunState = run_parts.register(ResistanceRunState.new())
var attempt_spend: AttemptSpendState = run_parts.register(AttemptSpendState.new())
var settled: SettledState = run_parts.register(SettledState.new())
var facts: RunFacts = run_parts.register(RunFacts.new())
## What is pasted on the city's walls and how many sheets she has torn — see `PosterState`. A fact
## about the run like `scars`, photographed and given back with them, so a lost day's crews and
## tears did not happen. A top-level save key of its own, so a save written before there were
## posters still loads, with bare walls.
var posters: PosterState = run_parts.register(PosterState.new())
## How many cyclists the run has drawn from its one pelican bag — see `PelicanState`. Photographed
## and given back with the rest of what an attempt spends, and a top-level save key of its own like
## `posters`, so a save written before it loads at 0.
var pelican: PelicanState = run_parts.register(PelicanState.new())
## The run's calendar over those parts: the day and act, a day's attempt begun and ended, the mode
## and the checkpoint, the day's random streams (`RunCalendar`). Whoever walks the days is handed
## this rather than the autoload.
var calendar := RunCalendar.new(run_parts, header, settled, resistance, facts)

## `%d:%02d.%03d` — minutes, seconds, milliseconds — the one format a run's own length is ever
## shown in: the ending screens (`SummaryModel.ending()`, the escape's epilogue,
## `SummaryModel.epilogue()`) and the run log. A still number, so the millisecond is kept. The escape's live clock is not this: it
## ticks on screen, and a screen cannot show a thousandth, so it reads
## `format_clock_hundredths()`.
static func format_clock(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var total_seconds := total_ms / 1000
	return "%d:%02d.%03d" % [total_seconds / 60, total_seconds % 60, total_ms % 1000]

## `%d:%02d.%02d` — minutes, seconds, hundredths — the escape's live clock in the HUD. Truncates
## like `format_clock_seconds()`, so a remaining time of 59.999 shows 59.99 — a countdown never
## reads higher than what is left. *(inbox #746 in woolly-penguin, the
## player: "escape clocke we can try 100s but it's not going to be much better? framerate is too
## low? all of this was on phone.")* A tried precision: the hundredth changes on almost every frame
## at 60 fps and on every frame at 30 fps.
static func format_clock_hundredths(seconds: float) -> String:
	var total_cs := int(seconds * 100.0 + 0.0001)
	var total_seconds := total_cs / 100
	return "%d:%02d.%02d" % [total_seconds / 60, total_seconds % 60, total_cs % 100]

## `%d:%02d` — minutes and seconds, no millisecond term — the day clock's own shape wherever it is
## shown: the HUD corner while a day runs (`hud.gd`'s `_on_day_time_changed()`) and the day summary
## once it ends (`SummaryModel.clock_line()`). Truncates rather than rounds, matching the HUD's own
## `int(remaining)` so a value read from the same clock a frame apart never disagrees by a second.
## Its own function rather than `format_clock()` with the millisecond term dropped, so the day
## clock and the run clock stay two callers of two small functions instead of one function two
## call sites have to remember to call correctly.
static func format_clock_seconds(seconds: float) -> String:
	var total_seconds := int(seconds)
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]

## Hands the run the trace its facts are written to, and the city's arcs with it. `main` hands the
## run session's at every boot; the test runner hands a silent one back between suites.
func use_trace(sink: RunTrace) -> void:
	calendar.use_trace(sink)
	attempt_spend.city_state.trace = sink

# ------------------------------------------------------------------ lifecycle ---

## Begin a fresh run. Pass a seed to reproduce a previous city, or omit for a new one.
func start_run(seed_value: int = 0) -> void:
	header.run_seed = seed_value if seed_value != 0 else _new_seed()
	header.player_is_male = run_rng("player-presentation").randi_range(0, 1) == 1
	run_parts.reset()
	# A fresh run is a normal run with nothing to go back to but its own day 1 until the title says
	# otherwise — `main._on_title_start()` sets `hard_mode` from the checkbox as the run begins.
	calendar.hard_mode = false
	calendar.checkpoint = {}
	print("[GameState] run started, seed=%d" % header.run_seed)

## Records a permanent mark, ignoring duplicates from the same spot.
func add_scar(id: String, position: Vector2) -> void:
	for scar in attempt_spend.scars:
		if scar["id"] == id and scar["position"].distance_to(position) < 1.0:
			return
	attempt_spend.scars.append({"id": id, "position": position, "since_day": header.day})

# ------------------------------------------------------------------ queries ---

func has_joined_resistance() -> bool:
	return resistance.progress > 0

## Whether the neighbor was taken in day 10's raid: the raid's day is behind her and its warning is
## not among the steps she completed on a day she won — skipped, failed or never offered, "the same
## sealed door, for the worse reason". Read by the wanted notice, which crosses out the neighbor's
## face (`PosterArt.sheet()`). Derived rather than saved, so a lost day gives it back with the step.
func neighbor_was_taken() -> bool:
	if header.day <= ResistanceHappenings.NEIGHBOR_DAY:
		return false
	var warning := ResistanceSteps.warning_step()
	return warning != null and warning.index not in resistance.completed_steps

## Whether the final sabotage is on offer at all.
func sabotage_available() -> bool:
	return resistance.progress >= Tuning.RESISTANCE_GOAL

# --------------------------------------------------------------- resistance ---

## `counts_toward_goal` is false for a pickup — the note is not the errand, only the perform
## half is, so `Tuning.RESISTANCE_GOAL` must not see the mark as well as the task it unlocked.
##
## Emits `resistance_step_completed` for `ResistanceDirector` and `Hud` to react to — a pickup's
## own words are announced from there, at the mark and nowhere else, rather than queued here for
## a day brief to read out later (`docs/NARRATIVE.md`, "Feedback").
func complete_resistance_step(step: int, counts_toward_goal: bool = true) -> void:
	if step in resistance.completed_steps:
		return
	resistance.completed_steps.append(step)
	if counts_toward_goal:
		resistance.progress += 1
		EventBus.resistance_progress_changed.emit(resistance.progress)
	EventBus.resistance_step_completed.emit(step)

## A timed step that expired. The contact is gone for the rest of the run.
func fail_resistance_step(step: int) -> void:
	if step in resistance.failed_steps:
		return
	resistance.failed_steps.append(step)
	EventBus.resistance_step_failed.emit(step)

## Being seen near a contact costs progress but never takes it below zero.
func penalise_resistance() -> void:
	resistance.progress = maxi(0, resistance.progress - 1)
	EventBus.resistance_progress_changed.emit(resistance.progress)

# ---------------------------------------------------------------------- RNG ---

## Independent reproducible choices whose lifetime is the whole run, rather than one day.
## Keeping presentation off the city/day streams preserves every seeded gameplay layout.
func run_rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:run:%s" % [header.run_seed, stream])
	return rng

## Deterministic RNG for city layout. Same seed, same city, for the whole run.
func city_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = header.run_seed
	return rng

func _new_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi()

# ------------------------------------------------------------------- save ---

## The run's state as the flat dictionary a save carries under `"state"`: every part the registry
## holds in the `STATE` slot (`RunStateRegistry.state_data()`), each writing its own keys. Plain
## JSON-safe values only — a `Vector2i` or an int-keyed `Dictionary` cannot survive
## `JSON.stringify()`, so each part turns its own into small dictionaries.
func save_snapshot() -> Dictionary:
	return run_parts.state_data()

## Whether `data` carries every key this build's `save_snapshot()` writes — the keys come from the
## parts, so a field a part gains is required of a save the moment it is written.
func snapshot_is_complete(data: Dictionary) -> bool:
	for field in run_parts.state_keys():
		if not data.has(field):
			return false
	return true

## Puts a snapshot back, each part reading its own keys.
func restore_snapshot(data: Dictionary) -> void:
	run_parts.restore_state(data)
