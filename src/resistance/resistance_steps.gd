class_name ResistanceSteps
extends RefCounted
## The six steps of the subquest, as data. See docs/NARRATIVE.md.
##
## The design constraint every step obeys: joining the resistance must cost the core
## resource. Every one of these puts the player somewhere she would otherwise route around
## — an alley, a watched district, a street chosen because it is loud — and asks her to
## stand still there, which is also the one thing that drains sleepiness.

class Step extends RefCounted:
	var index := 0
	var title := ""
	var first_day := 1
	## Seconds of held interaction. Longer is not harder to press, it is longer standing
	## still in a place that is costing you.
	var hold_seconds := 3.0
	## Tile types the contact may sit on, when it is not district-placed.
	var placement: Array[int] = []
	## Placed in or around this district instead, when set.
	var district := -1
	## Fraction of the day after which the step is gone for good. 0 means no deadline.
	var deadline_fraction := 0.0
	## Only offered once the goal is already met — the finale.
	var needs_goal := false

static var _all: Array[Step] = []

static func all() -> Array[Step]:
	if _all.is_empty():
		_all = _build()
	return _all

static func for_day(day: int, completed: Array[int], failed: Array[int],
		goal_met: bool) -> Step:
	for step in all():
		if step.index in completed or step.index in failed:
			continue
		if day < step.first_day:
			continue
		if step.needs_goal and not goal_met:
			continue
		return step
	return null

static func by_index(index: int) -> Step:
	for step in all():
		if step.index == index:
			return step
	return null

## Explicit rather than a dictionary of field names. The first version built these with
## `set(key, value)` from a Dictionary, and `set()` silently DROPS a value whose type does
## not match — so every `Array[int]` placement list came out empty and three of the six
## steps had nowhere to go, with no error anywhere.
static func _step(index: int, title: String, first_day: int, hold_seconds: float,
		placement: Array = [], district: int = -1, deadline_fraction: float = 0.0,
		needs_goal: bool = false) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.first_day = first_day
	step.hold_seconds = hold_seconds
	step.placement.assign(placement)
	step.district = district
	step.deadline_fraction = deadline_fraction
	step.needs_goal = needs_goal
	return step

static func _build() -> Array[Step]:
	return [
		# A chalk mark on an alley wall. No prompt, no quest marker — the alley's own
		# excitement trickle is running the entire time you stand there reading it.
		_step(1, "A chalk mark", 5, 3.0, [GameEnums.TileType.ALLEY]),
		# A person this time, and twice as long in the alley.
		_step(2, "The contact", 7, 6.0, [GameEnums.TileType.ALLEY]),
		# A delivery into the civic district, which by Act III is the most watched ground
		# in the city. The quiet routes there are the ones being watched.
		_step(3, "A package", 9, 4.0, [], GameEnums.District.CIVIC),
		# Timed: a warning that is worthless late. Miss the window and the contact is gone
		# for the rest of the run.
		_step(4, "A warning", 11, 3.0, [GameEnums.TileType.ALLEY], -1, 0.55),
		_step(5, "The device", 13, 5.0, [], GameEnums.District.INDUSTRIAL),
		# The finale, offered only to a player who already did the work.
		_step(6, "The last night", Tuning.RUN_LENGTH_DAYS, 8.0, [],
				GameEnums.District.CIVIC, 0.0, true),
	]
