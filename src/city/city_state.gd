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

## Back to day 1 with every block at the start of its arc.
func reset() -> void:
	_stage.clear()
	_changed_on.clear()

func purpose_of(plans: Dictionary, block: Vector2i) -> GameEnums.BlockPurpose:
	var plan: BlockPlan = plans.get(block)
	if not plan:
		return GameEnums.BlockPurpose.RESIDENTIAL
	return plan.steps[_index(block)].purpose

## The day this block last became something else. 1 if it never has.
func changed_on(block: Vector2i) -> int:
	return _changed_on.get(block, 1)

## Advances every block as far as its scheduled steps allow. Called once at the start of a
## day, before anything is placed, so events are placed into the city the day actually has.
##
## Advancing is a loop rather than a single step because a run can be resumed on a later day
## (`--day 9`), and a block two scheduled steps behind has to arrive where it would have
## been rather than lag by however many days were skipped.
func begin_day(plans: Dictionary, day: int) -> void:
	for block: Vector2i in plans:
		var plan: BlockPlan = plans[block]
		while _can_advance(plan, block, day, GameEnums.BlockCause.SCHEDULED):
			_advance(block, day)

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
	_advance(block, day)
	return true

## Blocks that are calm ground right now. Since M14 a day can only be won on calm ground, so
## this is the list the scheduler and the route map both care about.
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

func _advance(block: Vector2i, day: int) -> void:
	_stage[block] = _index(block) + 1
	_changed_on[block] = day
