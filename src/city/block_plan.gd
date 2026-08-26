class_name BlockPlan
extends RefCounted
## One block's arc: the ordered list of purposes it may pass through, planned at generation.
##
## The point of planning it up front is that a block never has to invent a plausible next
## state at runtime. A park that is going to be requisitioned was always going to be
## requisitioned, on a day the generator chose, and the generator could therefore check —
## once, for the whole run — that enough calm ground survives to the end. Deciding it
## day by day would make that guarantee impossible to state, let alone test.
##
## An arc is a line, not a tree. A block moves forward one step at a time or not at all; it
## never skips, never branches and never goes back. That is what makes the city legible: the
## player can learn that a boarded-up street is on its way to being barricaded.

class Step extends RefCounted:
	## What the block becomes.
	var purpose: GameEnums.BlockPurpose
	## The earliest day this step may be taken. A cause arriving before it is ignored, not
	## queued — an act I fire cannot burn out a block whose arc says act III.
	var from_day: int
	## What has to happen for the step to be taken.
	var cause: GameEnums.BlockCause

	func _init(step_purpose: GameEnums.BlockPurpose, day: int,
			step_cause: GameEnums.BlockCause) -> void:
		purpose = step_purpose
		from_day = day
		cause = step_cause

## Step 0 is what the block starts as, and is always reached on day 1.
var steps: Array[Step] = []

static func of(start: GameEnums.BlockPurpose) -> BlockPlan:
	var plan := BlockPlan.new()
	plan.steps.append(Step.new(start, 1, GameEnums.BlockCause.SCHEDULED))
	return plan

## Appends a step. Returns self so a whole arc reads as one expression at the call site.
##
## The day is pushed forward to at least the previous step's, here rather than at the call
## sites, because "an arc never goes backwards in time" is a property of arcs and not a rule
## each caller should have to remember. It was not, at first: a commercial block could be
## planned to go dark on day 10 and then burn on day 3, which is not a story about a street.
func then(purpose: GameEnums.BlockPurpose, from_day: int,
		cause: GameEnums.BlockCause) -> BlockPlan:
	var earliest := from_day
	if not steps.is_empty():
		earliest = maxi(earliest, steps[steps.size() - 1].from_day)
	steps.append(Step.new(purpose, earliest, cause))
	return self

func starting_purpose() -> GameEnums.BlockPurpose:
	return steps[0].purpose

func final_purpose() -> GameEnums.BlockPurpose:
	return steps[steps.size() - 1].purpose

## True if this block is calm ground at every step of its arc — a piece of the city that can
## be relied on for the whole run.
func stays_calm() -> bool:
	for step in steps:
		if not is_calm(step.purpose):
			return false
	return true

## Whether a purpose is ground a day can be won on. The four calm purposes and nothing else
## — a requisitioned park is the same grass and is not calm.
static func is_calm(purpose: GameEnums.BlockPurpose) -> bool:
	return purpose == GameEnums.BlockPurpose.PARK \
			or purpose == GameEnums.BlockPurpose.FOREST \
			or purpose == GameEnums.BlockPurpose.QUIET_SQUARE \
			or purpose == GameEnums.BlockPurpose.COURTYARD

## Whether a purpose is built over: the block is mostly buildings, with at most a carved
## square, alley or court in it.
static func is_built(purpose: GameEnums.BlockPurpose) -> bool:
	return not is_calm(purpose) and purpose != GameEnums.BlockPurpose.REQUISITIONED
