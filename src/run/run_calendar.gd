class_name RunCalendar
extends RefCounted
## The run's calendar: which day and act it is, what a day's attempt begins with and ends in, the
## nerves a loss spends, the checkpoint a normal run goes back to, and the day's random streams.
## `RunState` builds one over the parts it registers and hands it to whoever walks the days
## (`DayDirector`, the readers `main` builds), so those take the calendar rather than the whole
## run; a test builds a `RunState` and takes its `calendar()`.
##
## It holds the run's mode and its checkpoint, which are the calendar's state rather than any
## part's: both ride beside the snapshot as top-level keys of the save. It reads and writes the
## parts it is handed (the header's day and nerves, where she settled, the resistance's
## photographed fields) and reads and writes a checkpoint through the registry's own `run_data()`.

var _run_parts: RunStateRegistry
var _header: RunHeader
var _settled: SettledState
var _resistance: ResistanceRunState
var _facts: RunFacts

## Where the calendar's facts — a nerve spent, a checkpoint kept, the mode, the ending, where she
## settled — are written down for the run log. Handed in by `use_trace()`; silent until then.
var _trace := RunTrace.new()

func _init(parts: RunStateRegistry, the_header: RunHeader, the_settled: SettledState,
		the_resistance: ResistanceRunState, the_facts: RunFacts) -> void:
	_run_parts = parts
	_header = the_header
	_settled = the_settled
	_resistance = the_resistance
	_facts = the_facts

## Hands the calendar the trace its facts are written to.
func use_trace(sink: RunTrace) -> void:
	_trace = sink

## Whether this run is in hard mode, chosen once on the title's Hard Mode checkbox as a new game
## begins and fixed for the rest of the run. *(gentle-osprey, the player: "a "Hard Mode" checkbox on
## the title screen (if new game) that decides whether checkpoints are available".)* **Hard mode is
## the run with no checkpoints**: the last nerve ends it with the bad ending, and the escape spends
## nerves as well (`finish_day()` on a section's `DaySpec`), and nothing, a won day or a won
## section, gives one back (`regain_a_nerve_for_a_won_day()`). **Normal mode never reaches the
## bad ending**: the last nerve sends the run back to its latest checkpoint (`checkpoint()`). Nothing
## else differs — *"hard mode doesn't affect gameplay -- only restart pacing"*.
##
## Not in the run snapshot: it rides beside `RunFacts.escape_section()` as its own top-level save key, so a
## save written before there were two modes loads as normal mode by absence.
var _hard_mode := false

## The run as it stood at the dawn of the latest checkpoint day it has reached — days 4, 8 and
## 12, the first days of acts II, III and IV, read off `Tuning.ACT_START_DAYS` — in exactly the
## shape the save carries the run (`RunStateRegistry.run_data()`), or `{}` before day 4.
## *(gentle-osprey, the player: "store the exact state at the checkpoint -- continuing should
## not have anything that happened after the checkpoint".)* Taken by `begin_day()` the first
## time a checkpoint day is begun, never on a retry of it, so nothing of that day can have
## happened yet; given back by `finish_day()` when a normal run spends its last nerve, with
## `Tuning.STARTING_NERVES`.
##
## **`{}` is checkpoint zero**, day 1 of the same city: the registry's reset rebuilds that dawn
## exactly, so nothing is stored for it — which is also what a save written before checkpoints
## existed reads as. Never taken in hard mode, which has none.
##
## Not in the run snapshot, for the same reason as `_hard_mode`: a top-level save key of its own.
var _checkpoint: Dictionary = {}

## Whether this run is in hard mode (`_hard_mode` says what that is).
func in_hard_mode() -> bool:
	return _hard_mode

## The run as it stood at the dawn of its latest checkpoint day, or `{}` (`_checkpoint`): the live
## dictionary, which a reader does not change.
func checkpoint() -> Dictionary:
	return _checkpoint

## Puts back the mode a save holds, with no line in the run log: `GameSave` reading a run, and
## `RunState.start_run()` beginning one in normal mode. A new game's choice is `choose_mode()`.
func restore_mode(hard: bool) -> void:
	_hard_mode = hard

## Puts back the checkpoint a save holds (`GameSave`), or none for a run just begun (`RunState`).
func restore_checkpoint(kept: Dictionary) -> void:
	_checkpoint = kept

## The calendar day, the header's (`RunHeader.day()`), for whoever walks the days with the
## calendar alone (`DayDirector`).
func day() -> int:
	return _header.day()

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
	var start: int = Tuning.ACT_START_DAYS[Tuning.act_for_day(_header.day()) - 1]
	var used: Array[Vector2i] = []
	for past in range(_header.day() - 1, start - 1, -1):
		var block: Vector2i = _settled.block_on(past)
		if block.x >= 0 and not used.has(block):
			used.append(block)
	return used

## Called when the baby falls asleep, with the calm block she is standing in. The one place
## the city learns anything about how the player actually played.
func remember_where_she_settled(block: Vector2i) -> void:
	if _settled.block_on(_header.day()).x >= 0:
		return
	_settled.remember(_header.day(), block)
	_trace.note("calm", "settled in the calm block %s; tomorrow will know"
			% RunTrace.tile(block))

## Begin an attempt at today — the first try of a day, or a retry bought with a nerve.
##
## Called before anything is placed, because what is placed is decided by the state this is the
## record of: the director asks `resistance.completed_steps` and `resistance.failed_steps` which
## step today offers, and a loss gives back exactly what is photographed here, so the retry is
## offered the same mark or contact the first attempt was.
func begin_day() -> void:
	# The package is put down first, so what a loss gives back is a pram that is not yet heavy
	# rather than whatever the last attempt ended carrying. `ResistanceDirector.start_day()` says
	# the same thing a moment later for the rigs that drive it with no day loop around it.
	_resistance.put_down_package()
	_run_parts.photograph()
	_keep_a_checkpoint_if_one_is_due()

## Fixes a new game's mode, from the title's checkbox as it is dismissed (`main._on_title_start()`)
## or from `--hard`. A hard run keeps no checkpoint, so one a `--day` boot already took behind the
## title is dropped with the choice.
func choose_mode(hard: bool) -> void:
	_hard_mode = hard
	if hard:
		_checkpoint = {}
	_trace.note("nerve", "%s: %s" % ["hard mode" if hard else "normal mode",
			"the last nerve ends the run" if hard
			else "the last nerve goes back to the latest checkpoint"])

## Whether `for_day` is one of the days a normal run keeps a checkpoint at: the first day of every
## act after the first, read off `Tuning.ACT_START_DAYS` (days 4, 8 and 12). Day 1 is checkpoint
## zero, which the registry's reset rebuilds rather than anything storing it — see `_checkpoint`.
static func _is_checkpoint_day(for_day: int) -> bool:
	return for_day > 1 and for_day in Tuning.ACT_START_DAYS

## The day the run goes back to when a normal run spends its last nerve: the latest checkpoint day
## it has begun, or day 1 before day 4.
func _checkpoint_day() -> int:
	if _checkpoint.is_empty():
		return 1
	return int((_checkpoint["state"] as Dictionary)["day"])

## Whether losing the attempt now under way spends the run's last nerve and sends a normal run back
## to its checkpoint — asked by `main` before `finish_day()`, which is what actually goes back, so
## the screen that follows can say where she is going. Hard mode never goes back: its last nerve is
## the bad ending.
func a_loss_goes_back_to_the_checkpoint() -> bool:
	return not _hard_mode and _header.nerves() <= 1

## Keeps today's dawn as the run's checkpoint the first time a checkpoint day is begun — after the
## two photographs above, so the dawn fields it carries are this dawn's, and before anything of the
## day can have happened. A retry of the same day, or a run sent back to it, finds the checkpoint
## already on this day and keeps it as it is; only the next checkpoint day replaces it. **Not in
## hard mode**, which has none. The escape's sections never reach this: they begin no calendar day
## (`begin_day()`), since the run is still on its last one.
func _keep_a_checkpoint_if_one_is_due() -> void:
	if _hard_mode or not _is_checkpoint_day(_header.day()) or _header.day() <= _checkpoint_day():
		return
	_checkpoint = _run_parts.run_data()
	_trace.note("nerve", "day %d's dawn is the checkpoint a run out of nerves goes back to" % _header.day())

## Record the outcome of the day. Returns true if the run continues.
##
## **`spec` says what this day costs and settles**, and an ordinary day is what no `spec` means. The
## escape's sections are days of their own with their own rules (`DaySpec.for_section()`): a normal
## run's lost section costs nothing, a hard run's costs a Nerve and its last one ends the run, a
## lost section gives nothing back, since it touched none of what a day gives back, a won section
## gives no Nerve back, and the building's win settles nothing — the run goes on into the city,
## and only getting out of that ends it.
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
##   and where she settled (`SettledState`) is read to decide what tomorrow spoils. Left in place, an attempt that
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
## The run can no longer end by running out of days while nerves remain, so the fourteen days are
## a promise rather than a budget. **What the last nerve does depends on the mode**: hard mode's
## run ends with the bad ending, and a normal run goes back to its latest checkpoint with every
## nerve (`_go_back_to_the_checkpoint()`), which is why a normal run never ends badly.
##
## **A won day gives a nerve back**, up to `Tuning.STARTING_NERVES` (5) — the player's own reason:
## *"that way you can recover from a bad single day without being in a tight spot towards the end
## of the game"*. See `regain_a_nerve()` below for where this is granted and where it deliberately
## is not.
func finish_day(result: GameEnums.DayResult, spec: DaySpec = null) -> bool:
	var rules := spec if spec else DaySpec.new()
	if result != GameEnums.DayResult.WON:
		if not rules.a_loss_costs_a_nerve(_hard_mode):
			return true
		_header.set_nerves(_header.nerves() - 1)
		EventBus.nerves_changed.emit(_header.nerves())
		if rules.a_loss_gives_back_the_attempt:
			# Given back before the entry below rather than after it, so the one line about the
			# nerve also says whether the day took any resistance work down with it. Given back
			# before the `nerves <= 0` branch too: an attempt that failed did not count, and a run
			# that ends on it has no reason to be the exception — the `ending` entry then reports
			# what actually stood.
			var also_undone := _give_the_attempt_back()
			# Which nerve went, and on which day. The nerve economy has never been tested against
			# a game that bites early, and this is the entry that will say whether it survives it
			# — a question a retry sharpens rather than settles, since five nerves now buy five
			# attempts wherever they are needed instead of five days off the calendar.
			_trace.note("nerve", "spent a nerve on day %d (act %d); %d left%s%s"
					% [_header.day(), current_act(), _header.nerves(),
					"" if _header.nerves() <= 0 else " — day %d again" % _header.day(), also_undone])
		else:
			_trace.note("nerve", "spent a nerve in the escape; %d left" % _header.nerves())
		if _header.nerves() <= 0:
			if _hard_mode:
				_end_run(GameEnums.Ending.BAD)
				return false
			_go_back_to_the_checkpoint()
			return true
		if rules.a_loss_gives_back_the_attempt:
			_settled.forget(_header.day())
		return true
	# A section won that leads into the next settles nothing: the run goes on, and only the walk's
	# own end does.
	if rules.a_win_leads_into != DaySpec.Section.NONE:
		return true
	# A won day commits what it did: the attempt that stood is the one the next photograph starts
	# from, whether or not anything calls `begin_day()` before the next `finish_day()`.
	_run_parts.photograph()
	# Not for the escape: walking out of the city gives no nerve in either mode — a normal run's
	# escape has none to give ("the escape doesn't have nerves", the player), and a hard run gets
	# none back at all.
	if rules.a_win_gives_a_nerve_back:
		regain_a_nerve_for_a_won_day()
	if is_final_day():
		_end_run(GameEnums.Ending.GOOD if earned_good_ending() else GameEnums.Ending.NEUTRAL)
		return false
	_header.set_day(_header.day() + 1)
	return true

## Gives one nerve back, capped at `Tuning.STARTING_NERVES` (5) — the run's own maximum, so a
## stretch of wins can never bank more than a single bad day ever costs. `finish_day()` reaches this
## for an ordinary won day through `regain_a_nerve_for_a_won_day()`, and `main._on_day_finished()`'s
## hand-over to the escape reaches it the same way for day 14's own win, since a day that hands
## over never reaches `finish_day()` at all (that call waits for the city section's win, once she
## is out, so day 14's calendar slot and ending stay open for the escape to decide) — day 14 is
## still an ordinary day, and its win does not become the escape's just because what follows it
## is.
func regain_a_nerve() -> void:
	if _header.nerves() < Tuning.STARTING_NERVES:
		_header.set_nerves(_header.nerves() + 1)
		EventBus.nerves_changed.emit(_header.nerves())

## **A won day gives a hard run nothing back.** *(dotted-hawk, the player: "can we make hard mode
## not regenerate nerves as well?")* Nerves are restart pacing, so this is where Hard Mode's
## difference lives; nothing during a day reads the mode.
func regain_a_nerve_for_a_won_day() -> void:
	if not _hard_mode:
		regain_a_nerve()

## A normal run's last nerve, spent: the run as it stood at its latest checkpoint's dawn, every
## field the save carries, with `Tuning.STARTING_NERVES`. *(gentle-osprey, the player: "store
## the exact state at the checkpoint -- continuing should not have anything that happened after
## the checkpoint".)* **Restored rather than repaired**, through the same
## `RunStateRegistry.restore_run_data()` a save is read back with, so nothing a later field adds
## to the save can be left out of a checkpoint by forgetting it here.
##
## **Everything but the play time**: `RunHeader.play_ticks()` stays as it was at the loss, for a
## checkpoint zero and a later one alike, since going back is the game sending her back for running
## out of nerves and not the player starting over; only a new game from the title starts it at zero
## (inbox #920 in plaid-penguin).
##
## Checkpoint zero (`_checkpoint` empty) is day 1 of the same city: the registry reset. The header
## keeps the run's seed and who is pushing the pram, since `--parent` may have chosen it over the
## seed's roll; a normal run has no checkpoint to clear and is not in hard mode.
func _go_back_to_the_checkpoint() -> void:
	var lost_on := _header.day()
	var kept := _checkpoint
	# The run's play time only ever grows: the dawn's own clock is not given back (inbox #920 in plaid-penguin).
	var played := _header.play_ticks()
	if kept.is_empty():
		_run_parts.reset()
	else:
		_run_parts.restore_run_data(kept)
		_checkpoint = kept
	_header.set_play_ticks(played)
	_header.set_nerves(Tuning.STARTING_NERVES)
	EventBus.nerves_changed.emit(_header.nerves())
	EventBus.resistance_progress_changed.emit(_resistance.progress())
	_trace.note("nerve", "out of nerves on day %d — back to day %d's dawn, with every nerve"
			% [lost_on, _header.day()])
	EventBus.went_back_to_a_checkpoint.emit(_header.day(), lost_on)

func _end_run(which: GameEnums.Ending) -> void:
	_header.set_ending(which)
	# A run that has ended is no longer in the escape, whether it reached one or never did. Left
	# set, the next boot would read a finished run's leftover section and open the escape over a
	# title screen that has nothing behind it.
	_facts.set_escape_section(0)
	# `played` reuses the `ending` kind rather than adding a new one — how the run finished is
	# exactly the question a run's own length answers alongside, and the telemetry skill's own
	# "a kind reused from that table, not a synonym for one" does not want a second line for it.
	_trace.note("ending", "%s on day %d — resistance %d/%d, sabotage %s, played %s" % [
		String(GameEnums.Ending.keys()[which]).to_lower(), _header.day(),
		_resistance.progress(), Tuning.RESISTANCE_GOAL,
		"done" if _resistance.sabotage_went_through() else "not done",
		RunState.format_clock(_header.play_seconds())])
	EventBus.run_ended.emit(which)
	# A finished run leaves no save: `GameSave` clears it on `run_ended`
	# (`clear_when_a_run_ends()`).

func current_act() -> int:
	return Tuning.act_for_day(_header.day())

func is_final_day() -> bool:
	return _header.day() >= Tuning.RUN_LENGTH_DAYS

## Reaching the goal is the qualification; the sabotage is the act. Both are required, so
## a player who does the legwork and then skips the last night gets the neutral ending.
func earned_good_ending() -> bool:
	return _resistance.progress() >= Tuning.RESISTANCE_GOAL and _resistance.sabotage_went_through()

## Puts back everything the lost day spent — the resistance's work, the one-shots, scars and block
## arcs, the walls and the pelican bag, each by its part (`RunSubState.give_back()`) — and says so
## for the `nerve` entry: "" when the day touched none of the resistance's, which is most days.
##
## **Restored rather than counted back**: the step lists are what the next attempt's planning
## reads (`ResistanceSteps.for_day()` decides what is on offer from them,
## `DawnOneShots` skips a consumed row, `build_day` stands a permanent body
## on every scar), so putting the photograph back is the whole of it, and the retry meets the
## same mark again.
##
## `resistance_progress_changed` is emitted when the number actually moves, since the HUD's dots
## and the summary's tally are both drawn off it. Nothing announces a step *un*-completing,
## because nothing needs to: the HUD rebuilds its `out there:` line from scratch on
## `day_started` at the retry, which is the next moment either is looked at.
func _give_the_attempt_back() -> String:
	var progress_before := _resistance.progress()
	var undone := _resistance.differs_from_dawn()
	_run_parts.give_back()
	if _resistance.progress() != progress_before:
		EventBus.resistance_progress_changed.emit(_resistance.progress())
	return " — and the day's resistance work with it" if undone else ""

## Deterministic RNG for one day. `stream` separates independent consumers: without it,
## two systems asking for "the day's RNG" would both start from the same seed and their
## first rolls would move together, which is a correlation nobody asked for.
func day_rng(day_index: int = -1, stream: String = "events") -> RandomNumberGenerator:
	var d := _header.day() if day_index < 0 else day_index
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [_header.run_seed(), d, stream])
	return rng
