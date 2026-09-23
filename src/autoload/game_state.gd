extends Node
## Owns the state of a run: the seed, the calendar, nerves and resistance progress.
##
## Determinism contract (docs/ARCHITECTURE.md): nothing gameplay-relevant may call the
## global `randi()`. Layout comes from `city_rng()`, a day's events from `day_rng()`.

var run_seed: int = 0
## A run owns its presentation just as it owns its seed. Days and scene changes only read it.
var player_is_male := false
var day: int = 1
var nerves: int = Tuning.STARTING_NERVES
var resistance_progress: int = 0
var ending: GameEnums.Ending = GameEnums.Ending.NONE

## Which section of the escape this run is in, as a `FinaleController.Section` — `0` (`NONE`) for
## every one of the fourteen days, `BUILDING` or `CITY` once a won day 14 with every task complete
## has handed over to it. An `int` rather than the enum because a cross-script enum is not the same
## type as itself across a script boundary (see the **godot** skill), and a field on the *run*
## rather than on the scene for two reasons: it survives `reload_current_scene()`, which is how the
## handover reaches the escape's own boot with the run intact, and it is the one thing the save
## carries about the escape, so a game closed in a section opens on that section's brief.
##
## Deliberately **not** in `_SAVE_FIELDS`: `GameSave` writes it beside `day_under_way` rather than
## inside the run snapshot, so a save written before the escape existed is still complete and still
## loads (`snapshot_is_complete()`), answering `NONE` by absence.
var escape_section: int = 0

## Seconds the world has actually been moving this run — advanced by exactly one owner,
## `main._process()`'s own day-loop branch, while a day is walking or returning home and the tree
## is not paused. Never shown during play; the ending screen is the only place it is read, through
## `format_clock()` below.
var play_seconds: float = 0.0

## `%d:%02d.%03d` — minutes, seconds, milliseconds — the one format a run's own length is ever
## shown in, so a second clock reading to the millisecond has this to call rather than a second
## copy of the string. `DaySummary.show_ending()` is the only caller so far; the finale's own
## clock is not built yet, and calls this the same way once it is.
static func format_clock(seconds: float) -> String:
	var total_ms := int(round(seconds * 1000.0))
	var total_seconds := total_ms / 1000
	return "%d:%02d.%03d" % [total_seconds / 60, total_seconds % 60, total_ms % 1000]

## `%d:%02d` — minutes and seconds, no millisecond term — the day clock's own shape wherever it is
## shown: the HUD corner while a day runs (`hud.gd`'s `_on_day_time_changed()`) and the day summary
## once it ends (`DaySummary.show_day()`). Truncates rather than rounds, matching the HUD's own
## `int(remaining)` so a value read from the same clock a frame apart never disagrees by a second.
## Its own function rather than `format_clock()` with the millisecond term dropped, so the day
## clock and the run clock stay two callers of two small functions instead of one function two
## call sites have to remember to call correctly.
static func format_clock_seconds(seconds: float) -> String:
	var total_seconds := int(seconds)
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]

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

## Alley tiles a completed pickup step's chalk mark stood at, this run — read by
## `ResistanceDirector._pick_reachable()` and `_nearest_alley_within()` so a later mark never
## relocates onto, or starts on, the same alley while another eligible one is still in reach
## (M177). Not in `_SAVE_FIELDS`: rides beside `escape_section` as its own top-level save key, the
## same pattern (see `GameSave`'s own class doc), so a save written before this field existed
## still loads and reads as "nothing recorded" by absence.
##
## **Not given back by `_give_the_resistance_back()`.** A lost day's own placement never reads
## this list at all — the mark it is about was placed at dawn, before any tile could have been
## recorded against it today — so leaving an undone attempt's tile in here only ever costs the
## next placement one more alley to avoid, never a placement the guarantee needs.
var completed_resistance_alley_tiles: Array[Vector2i] = []

## Records a tile a pickup's mark stood at when its step completed, ignoring one already
## recorded. `ResistanceDirector._on_contact_completed()` is the one caller — see its own doc for
## why only a pickup's tile is ever worth recording here.
func record_completed_alley_tile(tile: Vector2i) -> void:
	if tile not in completed_resistance_alley_tiles:
		completed_resistance_alley_tiles.append(tile)

## What the resistance had done when today's attempt began — the six run-scoped facts a lost day
## gives back. `begin_day()` photographs them, `finish_day()` restores them on a loss and commits
## them on a win, and nothing else writes them.
##
## The rule they exist for: *"a task is only complete if it is done on the day that won. but also
## it should reset if lost so the player can try again"*. Everything else a run spends stays spent;
## this is the part of a run the *attempt* owns rather than the run.
var _dawn_completed_steps: Array[int] = []
var _dawn_failed_steps: Array[int] = []
var _dawn_progress := 0
var _dawn_sabotage_done := false
var _dawn_carrying_package := false
var _dawn_brief := ""

## And what today's attempt has done to the *city*, photographed the same way and given back the
## same way: the one-shots it consumed, the marks it left and how far along its arc each block it
## touched has moved.
##
## The rule they exist for is older and wider than the resistance's: *"a retry always rolls new --
## nothing that happened on the day that got retried can influence the next repeat -- that has been
## a long standing rule"*, and *"it is the same day exactly how the player encountered it the first
## time this run. exact same state at the beginning of the day. nothing else"*. A fire that burnt a
## block down on a lost day did not happen, because the day did not happen.
##
## `city_state` is photographed **before** the dawn arc roll — `GameState.begin_day()` runs ahead of
## `CityState.begin_day()`, which is what advances every block whose next step was waiting for the
## calendar. So a loss gives back that roll as well, and the retry's own dawn makes it again from the
## same seed and the same day: identical by construction rather than by nothing having touched it.
var _dawn_consumed_one_shots: Array[String] = []
var _dawn_scars: Array[Dictionary] = []
var _dawn_city_state := {}

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
	player_is_male = run_rng("player-presentation").randi_range(0, 1) == 1
	day = 1
	nerves = Tuning.STARTING_NERVES
	resistance_progress = 0
	ending = GameEnums.Ending.NONE
	escape_section = 0
	play_seconds = 0.0
	consumed_one_shots.clear()
	completed_resistance_steps.clear()
	failed_resistance_steps.clear()
	scars.clear()
	city_state.reset()
	settled_in.clear()
	sabotage_done = false
	resistance_carrying_package = false
	pending_resistance_brief = ""
	completed_resistance_alley_tiles.clear()
	_snapshot_the_resistance()
	print("[GameState] run started, seed=%d" % run_seed)

## Begin an attempt at today — the first try of a day, or a retry bought with a nerve.
##
## Called before anything is placed, because what is placed is decided by the state this is the
## record of: the director asks `completed_resistance_steps` and `failed_resistance_steps` which
## step today offers, and a loss gives back exactly what is photographed here, so the retry is
## offered the same mark or contact the first attempt was.
func begin_day() -> void:
	# The package is put down first, so what a loss gives back is a pram that is not yet heavy
	# rather than whatever the last attempt ended carrying. `ResistanceDirector.start_day()` says
	# the same thing a moment later for the rigs that drive it with no day loop around it.
	resistance_carrying_package = false
	_snapshot_the_resistance()
	_snapshot_what_the_attempt_can_spend()

## Record the outcome of the day. Returns true if the run continues.
##
## **A lost day is retried, not skipped.** A nerve buys another attempt at the same day, and the
## calendar moves only when a day is won.
##
## Four things follow, and all four are chosen rather than fallen into:
##
## - **The retry is the same day.** Everything about one is deterministic from the seed and the
##   day number — the city, the closures, the whole event plan — which is exactly what makes a
##   retry worth having in a game about learning a route.
## - **What a lost attempt spent is given back.** *("a retry always rolls new -- nothing that
##   happened on the day that got retried can influence the next repeat -- that has been a long
##   standing rule"; "exact same state at the beginning of the day. nothing else".)* The one-shots
##   it consumed, the scars it left and the block arcs it advanced are facts about the attempt
##   rather than about the run, so a day 3 lost after the fire burned owes a fire again — sited from
##   whatever walk the retry takes — and leaves no shell behind it. Only a day she **wins** keeps
##   any of it.
## - **Except where she settled.** That is a fact about the attempt rather than about the run,
##   and `settled_in` is read to decide what tomorrow spoils. Left in place, an attempt that
##   reached a park and then lost the day would send tomorrow's loud event to a park she never
##   actually used — and the winning attempt could not overwrite it, because the record is written
##   once.
## - **And except everything the resistance did**, for the reason the player gives: *"a lost day
##   shouldn't retain the touch mark -- a task is only complete if it is done on the day that won.
##   but also it should reset if lost so the player can try again"*. A mark touched, a step
##   performed, a contact lost to its deadline, a package picked up and the last night's sabotage
##   are all facts about the attempt, so a loss gives back the six fields `begin_day()`
##   photographed and the retry is offered the same step, in the same place, from the same seed.
##
## The run can no longer end by running out of days while nerves remain, so the bad ending is
## the only way to lose and the fourteen days become a promise rather than a budget.
func finish_day(result: GameEnums.DayResult) -> bool:
	if result != GameEnums.DayResult.WON:
		nerves -= 1
		EventBus.nerves_changed.emit(nerves)
		# Given back before the entry below rather than after it, so the one line about the nerve
		# also says whether the day took any resistance work down with it. Given back before the
		# `nerves <= 0` branch too: an attempt that failed did not count, and a run that ends on it
		# has no reason to be the exception — the `ending` entry then reports what actually stood.
		var also_undone := _give_the_resistance_back()
		_give_back_what_the_attempt_spent()
		# Which nerve went, and on which day. The nerve economy has never been tested against
		# a game that bites early, and this is the entry that will say whether it survives it —
		# a question a retry sharpens rather than settles, since five nerves now buy five
		# attempts wherever they are needed instead of five days off the calendar.
		Telemetry.note("nerve", "spent a nerve on day %d (act %d); %d left%s%s"
				% [day, current_act(), nerves,
				"" if nerves <= 0 else " — day %d again" % day, also_undone])
		if nerves <= 0:
			_end_run(GameEnums.Ending.BAD)
			return false
		settled_in.erase(day)
		return true
	# A won day commits what it did: the attempt that stood is the one the next photograph starts
	# from, whether or not anything calls `begin_day()` before the next `finish_day()`.
	_snapshot_the_resistance()
	_snapshot_what_the_attempt_can_spend()
	if is_final_day():
		_end_run(GameEnums.Ending.GOOD if earned_good_ending() else GameEnums.Ending.NEUTRAL)
		return false
	day += 1
	return true

func _end_run(which: GameEnums.Ending) -> void:
	ending = which
	# A run that has ended is no longer in the escape, whether it reached one or never did. Left
	# set, the next boot would read a finished run's leftover section and open the escape over a
	# title screen that has nothing behind it.
	escape_section = 0
	# `played` reuses the `ending` kind rather than adding a new one — how the run finished is
	# exactly the question a run's own length answers alongside, and the telemetry skill's own
	# "a kind reused from that table, not a synonym for one" does not want a second line for it.
	Telemetry.note("ending", "%s on day %d — resistance %d/%d, sabotage %s, played %s" % [
		GameEnums.Ending.keys()[which].to_lower(), day,
		resistance_progress, Tuning.RESISTANCE_GOAL,
		"done" if sabotage_done else "not done", format_clock(play_seconds)])
	EventBus.run_ended.emit(which)
	# A finished run leaves no save: there is nothing left to resume, and a
	# save that named an ended run would have to be specially refused on load rather than simply
	# not existing. Cleared here, at the one place a run ever actually ends, rather than only where
	# a player presses on past the ending screen (`main._restart_run()` also clears it, for the
	# held restart that abandons a run before it ends on its own) — a save must not survive between
	# the two, however the process happens to close in that window.
	GameSave.clear()

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

## Photographs the resistance's run state as the attempt about to be played found it. Taken at
## dawn by `begin_day()` and again on a won day, which is what makes a win a commit.
func _snapshot_the_resistance() -> void:
	_dawn_completed_steps = completed_resistance_steps.duplicate()
	_dawn_failed_steps = failed_resistance_steps.duplicate()
	_dawn_progress = resistance_progress
	_dawn_sabotage_done = sabotage_done
	_dawn_carrying_package = resistance_carrying_package
	_dawn_brief = pending_resistance_brief

## Photographs what today's attempt is about to be allowed to spend of the city: the run's consumed
## one-shots, its scars and every block's arc position. Taken beside `_snapshot_the_resistance()` and
## at the same two moments, for the same reason — dawn, and again on a won day, which is what makes a
## win a commit.
##
## The scar array is duplicated one level deep only, and that is enough: a scar dictionary is written
## once by `add_scar()` and never edited, so nothing can reach into the photograph through a shared
## entry.
func _snapshot_what_the_attempt_can_spend() -> void:
	_dawn_consumed_one_shots = consumed_one_shots.duplicate()
	_dawn_scars = scars.duplicate()
	_dawn_city_state = city_state.snapshot()

## Puts the city back where the lost day found it. A one-shot the attempt spent is owed again, the
## shell it left is gone, and the block it burned is back at the step it was on this morning.
##
## **Restored rather than counted back**, exactly like the resistance's step lists: those lists are
## what the next attempt's planning reads — `EventScheduler._place_one_shots` skips a consumed row
## and `build_day` stands a permanent body on every scar — so putting the photograph back is the
## whole of it.
func _give_back_what_the_attempt_spent() -> void:
	consumed_one_shots = _dawn_consumed_one_shots.duplicate()
	scars = _dawn_scars.duplicate()
	city_state.restore(_dawn_city_state)

## Puts the resistance back where the lost day found it, and says so for the `nerve` entry —
## "" when the day touched none of it, which is most days.
##
## **The step list is restored, not repaired**, so a step the day completed is not merely
## uncounted: it is gone from `completed_resistance_steps`, which is the list
## `ResistanceSteps.for_day()` reads to decide what is on offer, so the retry meets the same mark
## or contact again rather than an empty day.
##
## `resistance_progress_changed` is emitted when the number actually moves, since the HUD's dots
## and the summary's tally are both drawn off it. Nothing announces a step *un*-completing,
## because nothing needs to: the HUD rebuilds its `somewhere out there:` line from scratch on
## `day_started` at the retry, which is the next moment either is looked at.
##
## **And the summary is left the day's own instruction to read** — see
## `_instruction_the_day_began_with()`. Queued over the restored brief rather than instead of it,
## so words that were owed and never shown are never dropped on the way past.
func _give_the_resistance_back() -> String:
	var progress_before := resistance_progress
	var undone := completed_resistance_steps != _dawn_completed_steps \
			or failed_resistance_steps != _dawn_failed_steps \
			or resistance_progress != _dawn_progress \
			or sabotage_done != _dawn_sabotage_done \
			or resistance_carrying_package != _dawn_carrying_package \
			or pending_resistance_brief != _dawn_brief
	completed_resistance_steps = _dawn_completed_steps.duplicate()
	failed_resistance_steps = _dawn_failed_steps.duplicate()
	resistance_progress = _dawn_progress
	sabotage_done = _dawn_sabotage_done
	resistance_carrying_package = _dawn_carrying_package
	pending_resistance_brief = _dawn_brief
	var instruction := _instruction_the_day_began_with()
	if instruction != "":
		pending_resistance_brief = instruction
	if resistance_progress != progress_before:
		EventBus.resistance_progress_changed.emit(resistance_progress)
	return " — and the day's resistance work with it" if undone else ""

## The instruction today began with: the words of the mark that unlocked the perform step the day
## offered at dawn — the same words the summary of the day she found that mark already read out.
##
## *(The player, on whether a lost day should read out the mark it was about to take back: "the
## words shown on the lost day are the words that show at the beginning of that day not the nexts.
## since day doesn't have words it doesn't make sense to show words on day 4".)* So a lost summary
## repeats what the retry is for rather than a touch that no longer counts, and a day whose whole
## content is finding the mark repeats nothing: this answers "" for a pickup, for the finale and
## for a day with nothing on offer, which is every lost day 4.
##
## Read off the dawn photograph through the day's own table rather than asked of the director. The
## step a day offers is a pure function of the calendar and what the resistance had already done,
## which is exactly what was photographed, so this says what the day offered even when the summary
## is drawn with no director alive.
func _instruction_the_day_began_with() -> String:
	var step := ResistanceSteps.for_day(day, _dawn_completed_steps, _dawn_failed_steps,
			_dawn_progress >= Tuning.RESISTANCE_GOAL)
	return ResistanceSteps.unlocking_brief(step)

# ---------------------------------------------------------------------- RNG ---

## Independent reproducible choices whose lifetime is the whole run, rather than one day.
## Keeping presentation off the city/day streams preserves every seeded gameplay layout.
func run_rng(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:run:%s" % [run_seed, stream])
	return rng

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

# ------------------------------------------------------------------- save ---

## Every field a save has to carry — `GameSave` reads this to write a file and calls
## `restore_snapshot()` to read one back. Named exactly after the script variables above
## (including the leading underscore on the dawn fields) rather than a prettied-up copy, so
## `tests/test_save.gd` can compare this list directly against `get_property_list()` and fail
## loudly the moment a field is added up there and forgotten down here.
##
## Plain JSON-safe values only — a `Vector2i` or an int-keyed `Dictionary` cannot survive
## `JSON.stringify()`, so `scars`, `city_state` and `settled_in` are each turned into arrays of
## small dictionaries here rather than carried through as the shapes the rest of the game reads.
## `city_state` delegates to `CityState.snapshot()`, since `_stage`/`_changed_on` are that class's
## own private fields and reaching into them from here would be the same mistake the **godot**
## skill warns against for a dictionary built by hand — one place decides the shape.
const _SAVE_FIELDS := [
	"run_seed", "player_is_male", "day", "nerves", "resistance_progress", "ending",
	"play_seconds", "consumed_one_shots", "completed_resistance_steps", "failed_resistance_steps",
	"scars", "city_state", "sabotage_done", "resistance_carrying_package",
	"pending_resistance_brief", "_dawn_completed_steps", "_dawn_failed_steps", "_dawn_progress",
	"_dawn_sabotage_done", "_dawn_carrying_package", "_dawn_brief", "settled_in",
	"_dawn_consumed_one_shots", "_dawn_scars", "_dawn_city_state",
]

func save_snapshot() -> Dictionary:
	var scars_data := _scars_as_data(scars)
	var settled_data: Array = []
	for settled_day: int in settled_in:
		var block: Vector2i = settled_in[settled_day]
		settled_data.append({"day": settled_day, "x": block.x, "y": block.y})
	return {
		"run_seed": run_seed,
		"player_is_male": player_is_male,
		"day": day,
		"nerves": nerves,
		"resistance_progress": resistance_progress,
		"ending": ending,
		"play_seconds": play_seconds,
		"consumed_one_shots": consumed_one_shots.duplicate(),
		"completed_resistance_steps": completed_resistance_steps.duplicate(),
		"failed_resistance_steps": failed_resistance_steps.duplicate(),
		"scars": scars_data,
		"city_state": city_state.snapshot(),
		"sabotage_done": sabotage_done,
		"resistance_carrying_package": resistance_carrying_package,
		"pending_resistance_brief": pending_resistance_brief,
		"_dawn_completed_steps": _dawn_completed_steps.duplicate(),
		"_dawn_failed_steps": _dawn_failed_steps.duplicate(),
		"_dawn_progress": _dawn_progress,
		"_dawn_sabotage_done": _dawn_sabotage_done,
		"_dawn_carrying_package": _dawn_carrying_package,
		"_dawn_brief": _dawn_brief,
		"settled_in": settled_data,
		"_dawn_consumed_one_shots": _dawn_consumed_one_shots.duplicate(),
		"_dawn_scars": _scars_as_data(_dawn_scars),
		"_dawn_city_state": _dawn_city_state.duplicate(true),
	}

## A scar list as the plain arrays a JSON file can hold — a `Vector2` cannot survive
## `JSON.stringify()`. Shared by the run's own scars and by the photograph a lost day gives back,
## so the two can never be written in two shapes.
static func _scars_as_data(from: Array[Dictionary]) -> Array:
	var data: Array = []
	for scar in from:
		var position: Vector2 = scar["position"]
		data.append({
			"id": scar["id"], "x": position.x, "y": position.y, "since_day": scar["since_day"],
		})
	return data

## The other half of `_scars_as_data()`. JSON has no integer type, so every number is cast.
static func _scars_from_data(raw: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for scar: Dictionary in raw:
		found.append({
			"id": String(scar["id"]),
			"position": Vector2(float(scar["x"]), float(scar["y"])),
			"since_day": int(scar["since_day"]),
		})
	return found

## Whether `data` (a save's own `"state"` object) carries every field `save_snapshot()` writes —
## checked before `restore_snapshot()` ever runs, so a save missing a field from a shape this
## build no longer writes is dropped for a fresh title screen rather than partly applied.
func snapshot_is_complete(data: Dictionary) -> bool:
	for field in _SAVE_FIELDS:
		if not data.has(field):
			return false
	return true

## The other half of `save_snapshot()`. JSON has no integer type, so every number `data` carries
## is a `float` regardless of what was written — every field read back into a typed `int` or a
## typed array below is cast explicitly rather than assigned, which is what keeps this from being
## the silent-type-drop trap the **godot** skill warns about.
func restore_snapshot(data: Dictionary) -> void:
	run_seed = int(data["run_seed"])
	player_is_male = bool(data["player_is_male"])
	day = int(data["day"])
	nerves = int(data["nerves"])
	resistance_progress = int(data["resistance_progress"])
	ending = int(data["ending"]) as GameEnums.Ending
	play_seconds = float(data["play_seconds"])
	consumed_one_shots.assign(data["consumed_one_shots"])
	completed_resistance_steps = _to_int_array(data["completed_resistance_steps"])
	failed_resistance_steps = _to_int_array(data["failed_resistance_steps"])
	scars = _scars_from_data(data["scars"])
	city_state.restore(data["city_state"])
	sabotage_done = bool(data["sabotage_done"])
	resistance_carrying_package = bool(data["resistance_carrying_package"])
	pending_resistance_brief = String(data["pending_resistance_brief"])
	_dawn_completed_steps = _to_int_array(data["_dawn_completed_steps"])
	_dawn_failed_steps = _to_int_array(data["_dawn_failed_steps"])
	_dawn_progress = int(data["_dawn_progress"])
	_dawn_sabotage_done = bool(data["_dawn_sabotage_done"])
	_dawn_carrying_package = bool(data["_dawn_carrying_package"])
	_dawn_brief = String(data["_dawn_brief"])
	settled_in.clear()
	for raw: Dictionary in data["settled_in"]:
		settled_in[int(raw["day"])] = Vector2i(int(raw["x"]), int(raw["y"]))
	# The photograph of what the attempt may spend rides along with the rest of the dawn fields, so
	# a run resumed mid-day gives back exactly what that day had spent when it was written — see
	# `_snapshot_what_the_attempt_can_spend()` and `main._ready()`, which loses a day that was under
	# way through the ordinary lost-day path.
	_dawn_consumed_one_shots.assign(data["_dawn_consumed_one_shots"])
	_dawn_scars = _scars_from_data(data["_dawn_scars"])
	_dawn_city_state = (data["_dawn_city_state"] as Dictionary).duplicate(true)

## `Array[int]` from a JSON array of floats — see `restore_snapshot()`'s own doc for why every
## number here is cast rather than assigned.
func _to_int_array(raw: Array) -> Array[int]:
	var result: Array[int] = []
	for value in raw:
		result.append(int(value))
	return result
