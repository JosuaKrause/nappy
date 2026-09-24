class_name CityState
extends RefCounted
## Where every block currently is along its arc, for one run.
##
## This is the thing that replaces the old "the `CityMap` is immutable for the run"
## invariant. The replacement is weaker and still load-bearing: **the street lattice and the
## block boundaries are fixed for the run; what a block *is* may change, and only ever along
## the arc the generator planned for it.** The geometry the player learns stays true. The
## meaning of it does not.
##
## Nothing here decides anything. The arcs are fixed at generation and this only records how
## far along each one the run has got, which is why a day can be reconstructed from a seed
## and a day number plus the causes that have fired.

## Block -> index into that block's `BlockPlan.steps`.
var _stage := {}
## Block -> the day it last moved. Day 1 for a block that has never changed, which is what
## the route map wants to shade "this is new".
var _changed_on := {}
## The park that is open today whatever its arc has reached — day 12's, the one its task sends her
## to (`BlockPlan.forced_open_on`) — as `block -> true`, until she takes it. Derived by
## `begin_day()` from the plans and the day, never saved: a retried day derives it again.
var _open_today := {}

## Back to day 1 with every block at the start of its arc.
func reset() -> void:
	_stage.clear()
	_changed_on.clear()
	_open_today.clear()

## A block's arc position depends on run history — a fire only advances a block if something
## burned there — so `GameState`'s save has to carry it rather than recompute it from the seed and
## the day. `Vector2i` keys cannot survive `JSON.stringify()`, so each entry becomes its own small
## dictionary rather than a `Dictionary` keyed by one; see `restore()` for the other half.
func snapshot() -> Dictionary:
	var stage_data: Array = []
	for block: Vector2i in _stage:
		stage_data.append({"x": block.x, "y": block.y, "v": _stage[block]})
	var changed_data: Array = []
	for block: Vector2i in _changed_on:
		changed_data.append({"x": block.x, "y": block.y, "v": _changed_on[block]})
	return {"stage": stage_data, "changed_on": changed_data}

## The other half of `snapshot()`. JSON has no integer type, so every number in `data` is a
## `float` regardless of what was written, and is cast explicitly rather than assigned.
func restore(data: Dictionary) -> void:
	_stage.clear()
	_changed_on.clear()
	for raw: Dictionary in data.get("stage", []):
		_stage[Vector2i(int(raw["x"]), int(raw["y"]))] = int(raw["v"])
	for raw: Dictionary in data.get("changed_on", []):
		_changed_on[Vector2i(int(raw["x"]), int(raw["y"]))] = int(raw["v"])

## What `block` is now: the step of its arc the run has reached.
##
## **A recorded stage past the end of the arc reads as the arc's last step.** The stage comes from a
## save, and a save holds the run seed rather than the city, so a save written by a build whose
## generator made a different city is restored onto arcs that are not the ones it advanced. The case
## that exists is a block a newer build turned into the power station — a one-step `BIG_BUILDING`
## arc — which an older build's run had already boarded up or burnt. Reading the last step keeps
## that save loading into the city this build generates rather than indexing off the arc; nothing a
## current run records can be past its own arc, since `_can_advance` never steps beyond it.
##
## **Day 12's park is a park that day, whatever its arc has reached** (`_open_today`): *"we can
## just force open the park she needs to go to that day"* (PLAYTEST-119). A park whose arc
## requisitioned it on day 8 is grass with swings again for the one day, and the day is planned
## around it like any other park — calm, on the corridor, kept reachable — until she reaches the
## swing. The ground a park and a requisitioned park stand on is the same walkable ground, so this
## moves no walkable tile.
func purpose_of(plans: Dictionary, block: Vector2i) -> GameEnums.BlockPurpose:
	var plan: BlockPlan = plans.get(block)
	if not plan:
		return GameEnums.BlockPurpose.RESIDENTIAL
	if _open_today.has(block):
		return GameEnums.BlockPurpose.PARK
	return plan.steps[mini(_index(block), plan.steps.size() - 1)].purpose

## The day this block last became something else. 1 if it never has.
func changed_on(block: Vector2i) -> int:
	return _changed_on.get(block, 1)

## Advances every block as far as its scheduled steps allow. Called once at the start of a
## day, before anything is placed, so events are placed into the city the day actually has.
##
## Advancing is a loop rather than a single step because a run can be resumed on a later day
## (`--day 9`), and a block two scheduled steps behind has to arrive where it would have
## been rather than lag by however many days were skipped.
##
## It also opens the park the day's task sends her to, if today is its day — see `purpose_of()`.
func begin_day(plans: Dictionary, day: int) -> void:
	_open_today.clear()
	for block: Vector2i in plans:
		var plan: BlockPlan = plans[block]
		while _can_advance(plan, block, day, GameEnums.BlockCause.SCHEDULED):
			_advance(plans, block, day, GameEnums.BlockCause.SCHEDULED)
		if plan.forced_open_on == day:
			_open_today[block] = true

## Whether `block` is the park forced open today, and not yet taken.
func is_forced_open(block: Vector2i) -> bool:
	return _open_today.has(block)

## **The park day 12 sent her to is taken, now** — she has reached its swing (PLAYTEST-119: "*then*
## the park starts to close"). It stops being forced open, and its arc takes its `REQUISITIONED`
## step if that is the step it is waiting on, whatever the step's own cause or day: a step
## scheduled for day 13 is taken a day early, and the step `CityGenerator._plan_the_swing_park()`
## gave a park whose arc had none waits for exactly this (`BlockCause.TAKEN`). A park its arc had
## already requisitioned simply stops being forced open. Either way it is a requisitioned park for
## the rest of the run. Returns whether `block` was open and now is not.
func take(plans: Dictionary, block: Vector2i, day: int) -> bool:
	if not _open_today.has(block):
		return false
	_open_today.erase(block)
	var plan: BlockPlan = plans.get(block)
	if plan:
		var next := _index(block) + 1
		if next < plan.steps.size() \
				and plan.steps[next].purpose == GameEnums.BlockPurpose.REQUISITIONED:
			_advance(plans, block, day, GameEnums.BlockCause.TAKEN)
	return true

## A cause fired at a block. Advances its arc if the next step was waiting for exactly that
## cause and the day has come; otherwise nothing happens, which is the point — a fire in a
## block whose arc has no fire in it leaves a scar and changes nothing about the block.
##
## Returns true if the block moved.
func apply_cause(plans: Dictionary, block: Vector2i, cause: GameEnums.BlockCause,
		day: int) -> bool:
	var plan: BlockPlan = plans.get(block)
	if not plan or not _can_advance(plan, block, day, cause):
		return false
	_advance(plans, block, day, cause)
	return true

## Blocks that are calm ground right now. A day can only be won on calm ground, so this is the list
## the scheduler and anything drawing the city both care about.
func calm_blocks(plans: Dictionary) -> Array[Vector2i]:
	var calm: Array[Vector2i] = []
	for block: Vector2i in plans:
		if BlockPlan.is_calm(purpose_of(plans, block)):
			calm.append(block)
	calm.sort()
	return calm

func _index(block: Vector2i) -> int:
	return _stage.get(block, 0)

func _can_advance(plan: BlockPlan, block: Vector2i, day: int,
		cause: GameEnums.BlockCause) -> bool:
	var next := _index(block) + 1
	if next >= plan.steps.size():
		return false
	var step: BlockPlan.Step = plan.steps[next]
	return step.cause == cause and day >= step.from_day

## Takes the step, and writes down that it was taken.
##
## An arc step depends on run history — a fire only advances a block if something burned
## there, which depends on where the player was — so the day a block turned is not
## recomputable from the seed. It is one of the three random outcomes that branch a run, and
## it is the one that changes where the day can be won.
func _advance(plans: Dictionary, block: Vector2i, day: int,
		cause: GameEnums.BlockCause) -> void:
	var was := purpose_of(plans, block)
	_stage[block] = _index(block) + 1
	_changed_on[block] = day
	Telemetry.note("arc", "block %s %s -> %s (%s)" % [
		TelemetryLog.tile(block), TelemetryLog.purpose(was),
		TelemetryLog.purpose(purpose_of(plans, block)),
		GameEnums.BlockCause.keys()[cause].to_lower()])
