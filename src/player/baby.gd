class_name Baby
extends Node
## The two meters and the sleep state machine. See docs/MECHANICS.md.
##
## This node knows about exactly two things: the rig it rides in (for speed) and the
## WorldContext (for how loud it is here). It has no idea what an event or a tile is, so a new
## kind of event never requires touching this file.

## **What settles a baby is being pushed.** The pram is a rocking chair with wheels on, and
## rocking it is the only thing that calms her.
##
## **Zero and not merely low**, because standing still must *freeze* the excitement rather than
## clear it: the day then stops moving in both directions at once, which is the honest version of
## "waiting is not a plan". Any positive idle decay makes standing the strongest move in the game
## — a full meter cleared for a few points of sleepiness, anywhere, including the middle of a
## street she has no business being on.
##
## The counterplay this removes has a better replacement: **walk somewhere quiet**, which is what
## `City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` is for and what the whole route is about.
##
## Running still decays, barely — it is motion, and `EXCITEMENT_FROM_RUNNING` is what makes it a
## bad idea. The ordering is motion-shaped rather than arbitrary: walking calms most, running calms
## a little, standing calms nothing.
const EXCITEMENT_DECAY_IDLE := 0.0
const EXCITEMENT_DECAY_RUNNING := 0.5
## Constant dread while standing in an alley, and it is set against the ground it is felt on: an
## alley gives back 3.5/s, so the trickle sits just under its own decay and an empty alley is very
## nearly flat rather than a place to recover in. The pressure is that it is never quite recovery.
const EXCITEMENT_FROM_ALLEY := 3.0
## Excitement per second at full sprint, scaled by how far above walk speed we are.
##
## **The run button is a trap by design**: running is the wrong move against every row that merely
## emits, and the right move only against the things that follow you. This constant is what keeps
## that ordering true across the whole catalogue.
##
## It is sensitive to the shape of `Field.falloff` and not only to the radii. A fatter field makes
## time-in-field matter more, so a shoulder that is too generous makes running *out* of the widest
## rows cheaper than walking — which is not "running works" but "running is a coin flip", the worst
## of the two. `tests/test_events.gd` asserts the ordering row by row rather than leaving it in a
## document, because that is how it can break silently.
const EXCITEMENT_FROM_RUNNING := 14.0
## The two the *pram* says out loud, stated as **states with an instruction attached** rather than
## as points on a gauge — which is the whole difference between a cue and the HUD moved over the
## player's head. The other two states the pram shows need no constant at all, because the game
## already has them: the calm threshold, where the day stops progressing, and asleep.
##
## Nearly crying is the last band before `Tuning.METER_MAX` ends the day. Far enough up that it is not
## a second name for "loud street" — a pavement sits under the calm threshold and a bad moment
## reaches the fifties — and far enough from 100 to be worth acting on: the forty-five points back
## to the calm threshold are about four seconds of a park, or seven and a half of a quiet street.
const EXCITEMENT_NEARLY_CRYING := 80.0
## The bar may reach and sit at `Tuning.METER_MAX`; the day ends crying only once a further mass of
## excitement this many points has arrived **while she is already sitting at the cap**, within
## `EXCITEMENT_OVERFLOW_WINDOW`. *(2026-09-23, playtest 126, statement 1: "the bar can reach 100
## but we need also like 10 over 3s to actually end the day … those numbers are just me
## spitballing -- we would need to test it".)* That gave 10 over 3s, `docs/DECISIONS.md`'s M96
## measurement.
##
## **Tightened once**, on playtest 128's "we can make the extra push needed to end the day a tiny
## bit more aggressive/tighter" (M100, `docs/TODO.md`). `tests/probes/m96_crying_at_the_top.gd`
## swept 9.5/3s, 10/4s and 9.5/4s against one bump at the cap and the loudest stationary rows
## (`night_raid`, `curfew_announce`, `abduction`), walked past and stood in: widening the window to
## 4s changed no measured outcome, since every scenario's own mass already clears its threshold
## well inside 3s once she is actually in a source's field, so only the mass moved. 9.5 still
## leaves one bump at the cap (8.9 points of overflow, the same measurement M96 made) a real 0.6
## points short of crying, and shortens every loud row's own time to cry over the shipped 10.
##
## **What it counts, and why.** `Baby._update_excitement()` already nets `incoming − decay` every
## frame; while the bar is below the cap that net is simply added and clamped, same as always.
## Once she is sitting at `Tuning.METER_MAX`, a further positive net is what the clamp would otherwise
## have piled on top of 100 — the bar's own would-be overflow, in the same units the bar itself
## already uses — and that is what this mass sums, in a sliding window the same shape
## `Baby.decay_in_window()` already sums the decay side in. **Not the raw incoming**: charging the
## raw arriving points would make a loud but well-recovering street cry exactly as fast as a
## source with nothing fighting it, which is the "undeserved failure" the player asked to remove
## in the first place. One walker's bump barely reaches the cap and leaves almost nothing for the
## clamp to eat; a sustained source at the top keeps feeding it every frame it stays loud.
const EXCITEMENT_OVERFLOW_TO_CRY := 9.5
## The window `EXCITEMENT_OVERFLOW_TO_CRY` is summed over, in seconds — the player's own "3s".
## Long enough that two contacts in quick succession at the top add up to one push; short enough
## that leaving the source behind lets the mass drain out of the window at close to the pace she
## walked away in, rather than a push from a minute ago still counting against her.
##
## **Left at 3s** measuring playtest 128's "a tiny bit more aggressive/tighter" (M100,
## `docs/TODO.md`): `tests/probes/m96_crying_at_the_top.gd` swept a 4s window alongside 3s against
## one bump at the cap and the loudest stationary rows, and it changed no measured outcome — each
## scenario's mass already clears its own threshold well inside 3s once she is actually in a
## source's field, so the extra second of history never has anything old enough to matter yet.
## `EXCITEMENT_OVERFLOW_TO_CRY` carries the tightening instead.
##
## **The bar itself is untouched by any of this.** The moment incoming drops under decay, the net
## rate goes negative and `excitement` falls back from 100 at its ordinary ground-and-motion rate,
## exactly as it always has — nothing here freezes the bar at the cap or holds it up. The mass is
## a second, independent quantity read alongside it, and it drains the same way `decay_in_window()`
## already does: no reset, just entries aging out of the window as `Baby._clock` advances, whether
## or not she is still at the cap to add to it.
const EXCITEMENT_OVERFLOW_WINDOW := 3.0
## And how far below the wake threshold a sleeping baby starts to stir. Waking costs
## `WAKE_SLEEPINESS_PENALTY` — half the bar — so this is the most expensive thing in the return
## phase, and without a cue at the pram the only warning is a bar climbing in a corner.
const EXCITEMENT_STIR_MARGIN := 12.0
## Standing still has to be strictly worse than walking, or waiting is a strategy. It also
## has to stay cheaper than a calm zone gives, because stopping is the counterplay to a loud
## event and pricing it above the park's own rate would take that move away.
const SLEEPINESS_DRAIN_IDLE := 1.0
## Incoming excitement multiplier while the baby is asleep.
const SLEEPING_SENSITIVITY := 0.55
## Sleepiness the baby keeps after being woken up. Half the bar, which is now about twelve
## seconds of park — a fifth of a well-played day, which is what it was before and should
## stay whatever the rates are.
const WAKE_SLEEPINESS_PENALTY := 50.0

## Debug affordance: lets the debug world start a session mid-way for UI checks.
@export_range(0.0, 100.0) var starting_sleepiness := 0.0

## What the pram is saying about her.
##
## Four states and no gauge. Every other cue in `docs/EVENTS.md` says something about the *world* —
## a thing is dangerous, something is coming, this spot is about to be bad — and none of them says
## anything about the baby, who is the only thing the player is trying to change. Two bars
## in the corner of a game whose camera is on the pram asks a person to read a number about the
## thing they are looking at from somewhere else on the screen.
##
## The two rules it is built to, both from the **cues** skill's standing decisions:
##
## - **Stages, not a gauge.** A meter drawn over her head is the HUD moved. What earns a place
##   in the vocabulary is a small number of states, each of which is a different instruction:
##   *the day has stopped progressing*, *the day is about to end*, *you are on the way home*,
##   *she is about to wake and it will cost you half the bar*.
## - **It is not the exclamation mark.** That one means "this will end your day" and means only
##   that. Different shape, different anchor — the pram, not her head — and `Stroller` keeps them
##   out of each other's way when the pram is behind her.
enum Cue {
	NONE,
	## Over the calm threshold and awake: sleepiness is frozen, so the day is not progressing.
	UNSETTLED,
	## Close enough to `METER_MAX` that the next loud thing ends the day.
	NEARLY_CRYING,
	## Asleep. The one state with the most consequence attached and the least on-screen presence.
	ASLEEP,
	## Asleep and nearly awake again, which costs `WAKE_SLEEPINESS_PENALTY`.
	STIRRING,
}

var sleepiness := 0.0
var excitement := 0.0
var state := GameEnums.BabyState.AWAKE
## Nothing adds to `excitement` while this holds; decay still runs. Handed in by whoever places
## her, from `--invincible` — see `_update_excitement()`.
var excitement_frozen := false

## Last frame's breakdown, for the debug overlay.
var last_incoming := 0.0
var last_decay := 0.0

## This baby's own simulated clock, advanced by `delta` in `_physics_process` — the same shape
## every source's `ExcitementSource.landed()` uses, so `decay_in_window()` below prunes against a
## clock that keeps pace with every source's own, without depending on any one directly.
var _clock := 0.0
## `[when, points]` entries of decay actually taken from the meter, pruned to
## `ExcitementSource.WINDOW` the same way a source's own ledger is — see
## `decay_in_window()`, what `ExcitementHalo` shares this against.
var _decay_history: Array = []

## `[when, points]` entries of her own running and alley share of `incoming`, in the same sliding
## window every other source's `landed()` keeps (`ExcitementSource`). **Read by nothing in
## gameplay.** `EXCITEMENT_FROM_RUNNING` and
## `EXCITEMENT_FROM_ALLEY` are folded into `incoming` with no source object of their own
## (`_update_excitement()` below), so this is where "what she did to herself" is kept for whatever
## names the cause of a crying day — see `DayDirector.landed_by_group()`.
var _self_landed_history: Array = []

## `[when, points]` entries of the bar's own would-be overflow while sitting at
## `Tuning.METER_MAX` — see `EXCITEMENT_OVERFLOW_TO_CRY` for what this counts and why, and
## `_record_overflow()` for where it is fed. Pruned the same shape `_decay_history` is, to
## `EXCITEMENT_OVERFLOW_WINDOW`.
var _overflow_history: Array = []

var _stroller: Stroller
var _world: WorldContext

func _ready() -> void:
	add_to_group("baby")
	_stroller = get_parent() as Stroller
	assert(_stroller != null, "Baby must be a child of the Stroller rig")
	sleepiness = starting_sleepiness

## The world she is in, told rather than discovered: whoever places her (`main`, as it puts her
## into each world, `WorldMap.world`; a test, for a stand-in) hands her the `WorldContext` she asks
## about excitement, calm ground, alleys and decay, and hands her the next one when the world
## changes. The rig is reparented from the building to the city without `_ready()` running again,
## and the building is still in the tree, so nothing she found for herself could tell her which
## world she walks. `null` is no world: neutral answers, as for a data-level `Baby.new()`.
func set_world(world: WorldContext) -> void:
	_world = world

## The world she was last handed, or null.
func world() -> WorldContext:
	return _world

## Back to the start of a day. The baby does not carry yesterday's mood.
func reset() -> void:
	sleepiness = starting_sleepiness
	excitement = 0.0
	last_incoming = 0.0
	last_decay = 0.0
	_decay_history.clear()
	_self_landed_history.clear()
	_overflow_history.clear()
	_set_state(GameEnums.BabyState.AWAKE)
	EventBus.sleepiness_changed.emit(sleepiness)
	EventBus.excitement_changed.emit(excitement)

## Dev affordance: straight to sleep, so the return phase and the way home can be
## inspected without walking the whole meter up first.
func force_sleep() -> void:
	sleepiness = Tuning.METER_MAX
	EventBus.sleepiness_changed.emit(sleepiness)
	_set_state(GameEnums.BabyState.ASLEEP)
	EventBus.return_phase_started.emit()

func _physics_process(delta: float) -> void:
	if FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.INFLUENCE)
		_feel_the_frame(delta)
		FrameRecord.leave(outer)
	else:
		_feel_the_frame(delta)

## The influence sweep and the meters, timed under `FrameRecord.INFLUENCE`.
func _feel_the_frame(delta: float) -> void:
	if state == GameEnums.BabyState.CRYING:
		return

	var here := _stroller.global_position
	var calm_gain := _world.sleepiness_multiplier(here) if _world else 1.0
	var in_alley := _world.is_alley(here) if _world else false

	_update_excitement(delta, here, in_alley)
	_update_sleepiness(delta, calm_gain)
	_update_state()

# --------------------------------------------------------------- excitement ---

## **This is where the meter is fed, so this is where a source's `landed()` colour is traced
## from** — *(2026-09-08, the player: "don't derive it from the source numbers but trace an
## increase in excitement back to its constituents".)* `excitement_sources_at()` returns the same
## bodies `total_excitement_at()` would have summed, broken out so each one's own share of what
## reaches the bar this frame can be handed to its own `accumulate_landed()` — sensitivity
## included, so `ExcitementHalo`'s colour can never disagree with what the bar actually did.
## Running and the alley trickle have no source and are never attributed to anybody.
##
## **`excitement_frozen` (`--invincible`) freezes this meter too, never only the clock**
## (2026-09-11, the player: "when invincible the timer should never go down and excitement should
## never go up"). Nothing may add to `excitement` while it holds — decay still runs, since that is
## what keeps the meter honest as a rate rather than turning it off. `sources` is emptied rather
## than merely left unsummed, so `accumulate_landed()` below is never called either: a source that
## charges the halo but never reaches the meter is the exact drift this guards against.
func _update_excitement(delta: float, here: Vector2, in_alley: bool) -> void:
	_clock += delta
	var frozen := excitement_frozen
	var sources := [] if frozen else (_world.excitement_sources_at(here) if _world else [])
	var incoming := 0.0
	var self_incoming := 0.0
	if not frozen:
		for pair in sources:
			incoming += pair[1]
		# Added to `incoming` one term at a time, exactly as before `self_incoming` existed:
		# summing the two first and adding the total would round differently, and a record kept
		# only for the counter must not move the meter by even its last bit.
		var from_running := EXCITEMENT_FROM_RUNNING * _stroller.run_excess_ratio()
		incoming += from_running
		self_incoming = from_running
		if in_alley:
			incoming += EXCITEMENT_FROM_ALLEY
			self_incoming += EXCITEMENT_FROM_ALLEY
	# A sleeping baby is harder to disturb, but not immune -- and whatever fraction of a source's
	# own contribution actually reaches the meter is exactly the fraction that should reach that
	# source's own accumulate_landed(), or the halo would read a cost the meter never took.
	var sensitivity := current_sensitivity()
	incoming *= sensitivity
	for pair in sources:
		var source: ExcitementSource = pair[0]
		var contribution: float = pair[1]
		source.accumulate_landed(contribution * sensitivity * delta)
	_record_self_landed(self_incoming * sensitivity * delta)

	var decay := decay_rate()
	last_incoming = incoming
	last_decay = decay
	_record_decay(decay * delta)

	# Net rate, so that decay always counts: standing still fights a loud event, and
	# sprinting past one (decay ~0) makes it far worse than walking past it.
	var before := excitement
	var net := incoming - decay
	excitement = clampf(before + net * delta, 0.0, Tuning.METER_MAX)
	# Only while she is already sitting at the cap does a positive net mean anything beyond what
	# the bar shows: below the cap that net is simply the bar rising, already reflected above.
	# See `EXCITEMENT_OVERFLOW_TO_CRY` for what this sum decides and why it is netted
	# rather than raw.
	if before >= Tuning.METER_MAX and net > 0.0:
		_record_overflow(net * delta)
	if not is_equal_approx(before, excitement):
		EventBus.excitement_changed.emit(excitement)

## Folds this frame's decay into the sliding window `ExcitementHalo` shares out to every source's
## own net — see `decay_in_window()`. The nominal rate times `delta`, the same figure `last_decay`
## reports, not the excitement actually removed after clamping at the meter's own floor or
## ceiling: the clamp is an edge of the bar, not a fact about what walking gave back, and reading
## the rate rather than the clamp is what `last_decay` already does for the debug overlay.
func _record_decay(points: float) -> void:
	_prune_decay_history()
	if points > 0.0:
		_decay_history.append([_clock, points])

func _prune_decay_history() -> void:
	var cutoff := _clock - ExcitementSource.WINDOW
	while not _decay_history.is_empty() and _decay_history[0][0] < cutoff:
		_decay_history.pop_front()

## Folds this frame's running/alley share into the sliding window `self_landed()` reads, the same
## `[when, points]` shape and the same `ExcitementSource.WINDOW` prune every other source's own
## `accumulate_landed()` keeps — see `_self_landed_history`'s own doc for why there is no source
## object to call that method on instead.
func _record_self_landed(points: float) -> void:
	_prune_self_landed_history()
	if points > 0.0:
		_self_landed_history.append([_clock, points])

func _prune_self_landed_history() -> void:
	var cutoff := _clock - ExcitementSource.WINDOW
	while not _self_landed_history.is_empty() and _self_landed_history[0][0] < cutoff:
		_self_landed_history.pop_front()

## The sum of every entry still inside `ExcitementSource.WINDOW` — her own running and alley share of
## what has landed on her, the same sliding sum `landed()` gives every other source. Read only by
## `DayDirector.landed_by_group()`, naming what ended a crying day for `VisitCounter`.
func self_landed() -> float:
	_prune_self_landed_history()
	var total := 0.0
	for entry in _self_landed_history:
		total += entry[1]
	return total

## The decay taken from the meter over the last `ExcitementSource.WINDOW` seconds — what
## `ExcitementHalo` divides among the sources that landed a point in the same window, in
## proportion to what each landed, so a source's own net can never disagree with what walking (or
## standing, or running) actually gave back while it was costing her.
func decay_in_window() -> float:
	_prune_decay_history()
	var total := 0.0
	for entry in _decay_history:
		total += entry[1]
	return total

## Folds this frame's would-be overflow into the sliding window `EXCITEMENT_OVERFLOW_TO_CRY`
## reads — see `_update_excitement()` for what qualifies as overflow and why it is netted rather
## than raw. Stored the same shape `_record_decay()` uses, so the mass drains the same way: nothing
## resets it, entries simply age out of `EXCITEMENT_OVERFLOW_WINDOW` as `_clock` advances,
## whether or not she is still adding to it.
func _record_overflow(points: float) -> void:
	_prune_overflow_history()
	if points > 0.0:
		_overflow_history.append([_clock, points])

func _prune_overflow_history() -> void:
	var cutoff := _clock - EXCITEMENT_OVERFLOW_WINDOW
	while not _overflow_history.is_empty() and _overflow_history[0][0] < cutoff:
		_overflow_history.pop_front()

## The mass of overflow still inside `window` seconds — `EXCITEMENT_OVERFLOW_WINDOW` by
## default, what `_update_state()` checks every frame against `EXCITEMENT_OVERFLOW_TO_CRY`.
##
## **The override is for measurement, not for play.** `_record_overflow()` only ever retains
## `EXCITEMENT_OVERFLOW_WINDOW` seconds of history — pruning to a *narrower* `window` here
## is always a true subset of what is stored, so `tests/probes/m96_crying_at_the_top.gd` can sweep
## a smaller window against the same live rig without touching `Tuning`; a `window` wider than the
## default would read short, since the older history was never kept.
func overflow_mass(window: float = EXCITEMENT_OVERFLOW_WINDOW) -> float:
	_prune_overflow_history()
	var cutoff := _clock - window
	var total := 0.0
	for entry in _overflow_history:
		if entry[0] >= cutoff:
			total += entry[1]
	return total

## How fast the meter falls: what she is doing, times what she is standing on.
##
## The ground half is a **rate** the world answers with rather than a bool — calm, precinct,
## ordinary street, main road, best to worst. The two halves multiply rather than adding, so
## *walking somewhere better* is always worth something and running is always worth little,
## whichever ground she does it on.
##
## Public — `M174`'s caret reads this as "the decay her current movement earns," projected
## forward over `Tuning.EXPECTED_IMPACT_HORIZON` on the assumption that she keeps doing what she
## is doing, the same rate this function already answers every physics frame for the bar itself.
##
## `0.0` with no `_stroller` or no `_world` — a data-level `Baby.new()` never added to a tree,
## which `tests/test_halo.gd` builds on purpose to hold `decay_in_window()` in isolation. That call
## never reached here before this function had an external caller of its own
## (`ExcitementHalo._process()`); `_update_excitement()`'s own call is always on a live Baby, where
## both are set by `_ready()`, so the guard changes nothing for the bar itself.
func decay_rate() -> float:
	if not _stroller or not _world:
		return 0.0
	var rate := Tuning.EXCITEMENT_DECAY_WALKING
	if _stroller.is_idle():
		rate = EXCITEMENT_DECAY_IDLE
	elif _stroller.run_excess_ratio() > 0.0:
		rate = EXCITEMENT_DECAY_RUNNING
	return rate * _world.decay_multiplier(_stroller.global_position)

## `SLEEPING_SENSITIVITY` while asleep, `1.0` otherwise — the same fraction
## `_update_excitement()` scales `incoming` by, pulled out so the caret's own projection can read
## "the baby's current state" without duplicating the branch.
func current_sensitivity() -> float:
	return SLEEPING_SENSITIVITY if state == GameEnums.BabyState.ASLEEP else 1.0

# --------------------------------------------------------------- sleepiness ---

func _update_sleepiness(delta: float, calm_gain: float) -> void:
	if state == GameEnums.BabyState.ASLEEP:
		return

	var before := sleepiness
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		# Too interested in the world to settle — frozen, but it does not slip back either.
		pass
	elif _stroller.is_idle():
		sleepiness -= SLEEPINESS_DRAIN_IDLE * delta
	elif _stroller.run_excess_ratio() > 0.0:
		# Never fills while running, at any excitement level.
		pass
	else:
		# One multiplier rather than a branch: the ground answers with a **rate** —
		# 1.0 anywhere ordinary, more on calm, more again on a calm area that is one block — so
		# there is nothing here to ask about what kind of place she is standing in.
		sleepiness += Tuning.SLEEPINESS_GAIN_WALKING * calm_gain * delta

	sleepiness = clampf(sleepiness, 0.0, Tuning.METER_MAX)
	if not is_equal_approx(before, sleepiness):
		EventBus.sleepiness_changed.emit(sleepiness)

# -------------------------------------------------------------------- state ---

## The bar may reach and sit at `Tuning.METER_MAX` without ending the day — only a further push
## while she is up there does, `EXCITEMENT_OVERFLOW_TO_CRY` of it inside
## `EXCITEMENT_OVERFLOW_WINDOW` — the same check whether she is `AWAKE` or `ASLEEP`, since
## `_update_excitement()` already applies `SLEEPING_SENSITIVITY` to what counts as incoming before
## this ever sees it. A baby who reaches the cap asleep without that push falls through to the
## `ASLEEP` branch below and wakes at the ordinary penalty instead of crying.
func _update_state() -> void:
	if excitement >= Tuning.METER_MAX and overflow_mass() >= EXCITEMENT_OVERFLOW_TO_CRY:
		_set_state(GameEnums.BabyState.CRYING)
		return

	match state:
		GameEnums.BabyState.AWAKE:
			if sleepiness >= Tuning.METER_MAX:
				_set_state(GameEnums.BabyState.ASLEEP)
				EventBus.return_phase_started.emit()
		GameEnums.BabyState.ASLEEP:
			if excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD:
				sleepiness = WAKE_SLEEPINESS_PENALTY
				EventBus.sleepiness_changed.emit(sleepiness)
				_set_state(GameEnums.BabyState.AWAKE)

func _set_state(next: GameEnums.BabyState) -> void:
	if state == next:
		return
	state = next
	EventBus.baby_state_changed.emit(state)

# ------------------------------------------------------------------ queries ---

## Which of the four states the pram is showing, or `NONE` while there is nothing to say.
##
## A pure query, like everything else the rig asks of the baby: the drawing lives in `Stroller`
## because the rig draws itself, and the decision lives here because this is where the meters
## are. Nothing about it is a threshold `_update_state()` does not already turn the day on.
func cue() -> Cue:
	match state:
		GameEnums.BabyState.CRYING:
			return Cue.NEARLY_CRYING
		GameEnums.BabyState.ASLEEP:
			if excitement >= Tuning.EXCITEMENT_WAKE_THRESHOLD - EXCITEMENT_STIR_MARGIN:
				return Cue.STIRRING
			return Cue.ASLEEP
	if excitement >= EXCITEMENT_NEARLY_CRYING:
		return Cue.NEARLY_CRYING
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		return Cue.UNSETTLED
	return Cue.NONE

## Why sleepiness is not currently rising, or "" if it is. Drives the HUD hint.
func stall_reason() -> String:
	if state == GameEnums.BabyState.ASLEEP:
		return ""
	if excitement >= Tuning.EXCITEMENT_CALM_THRESHOLD:
		return "too excited"
	if _stroller.is_idle():
		return "standing still"
	if _stroller.run_excess_ratio() > 0.0:
		return "running"
	return ""
