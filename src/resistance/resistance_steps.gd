class_name ResistanceSteps
extends RefCounted
## The resistance subquest, as data. See docs/NARRATIVE.md.
##
## The design constraint every step obeys: joining the resistance must cost the core
## resource. A task is two beats — **pick up the instruction, perform the task the next
## day** — so the eleven steps below are five tasks of two beats each plus the finale.
##
## A pickup is a chalk mark in an alley: touch it and the resistance tells you, in the day
## brief, what tomorrow wants. A perform is the task itself, and its contact rides on the
## `EventInstance` the task is built around — a yeller, a delivery van, a checkpoint, a
## poster crew, a protest — rather than sitting on a bare tile. Only the perform half grants
## progress toward `Tuning.RESISTANCE_GOAL`; picking up a note is not the errand.

class Step extends RefCounted:
	var index := 0
	var title := ""
	var first_day := 1
	## True for a chalk-mark pickup. False for a perform step and for the finale.
	var is_pickup := false
	## Whether completing this step counts toward `Tuning.RESISTANCE_GOAL`. False for a
	## pickup — the errand is the perform half, not the note.
	var grants_progress := true
	## Tile types the contact may sit on. For a pickup this is where the mark waits; for a
	## perform it is where the task's own `EventInstance` is sited.
	var placement: Array[int] = []
	## Placed in or around this district instead, when set. Only the finale uses this.
	var district := -1
	## The `EventDef` id a perform step's contact rides on. "" for a pickup and the finale,
	## which sit on a bare tile instead.
	var task_event_id := ""
	## Fraction of the day after which the step is gone for good. 0 means no deadline.
	var deadline_fraction := 0.0
	## Only offered once the goal is already met — the finale.
	var needs_goal := false
	## The chalk mark's own words, read out on the day brief once this pickup is touched.
	## "" for anything that is not a pickup.
	var brief := ""
	## True for the one perform step that makes the pram heavier for the rest of the day.
	var applies_package_weight := false

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
static func _mark(index: int, title: String, first_day: int, brief: String) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.first_day = first_day
	step.is_pickup = true
	step.grants_progress = false
	step.placement.assign([GameEnums.TileType.ALLEY])
	step.brief = brief
	return step

static func _perform(index: int, title: String, first_day: int, task_event_id: String,
		placement: Array, deadline_fraction: float = 0.0,
		applies_package_weight: bool = false) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.first_day = first_day
	step.task_event_id = task_event_id
	step.placement.assign(placement)
	step.deadline_fraction = deadline_fraction
	step.applies_package_weight = applies_package_weight
	return step

static func _finale(index: int, title: String, first_day: int, district: int) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.first_day = first_day
	step.district = district
	step.needs_goal = true
	return step

static func _build() -> Array[Step]:
	return [
		# A · give a note to a yeller. The cost is the approach and it is paid whether or
		# not this is the right man — several homeless_yeller rows are already live, and
		# the one carrying the contact looks exactly like the rest of them.
		_mark(1, "A chalk mark", 4, "Give it to the one who won't stop shouting. Any of "
				+ "them might be him."),
		_perform(2, "A note for a stranger", 5, "homeless_yeller",
				[GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]),
		# E · carry the package home. Picking it up is instant; the cost is deferred — the
		# pram is heavier for every street after this one, for the rest of the day.
		_mark(3, "Another mark", 6, "A van will be waiting. Don't come home light."),
		_perform(4, "The package", 7, "delivery_van", [GameEnums.TileType.SIDEWALK],
				0.0, true),
		# D · walk through the checkpoint. Not round it — through.
		_mark(5, "Another mark", 8, "Don't go around it this time. Go through."),
		_perform(6, "The checkpoint", 9, "checkpoint",
				[GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]),
		# B · beat the poster crew to the wall. Keeps the old step 4's deadline fraction —
		# a window that closes rather than a clock she can watch.
		_mark(7, "Another mark", 10, "Get to the wall before they paste over it."),
		_perform(8, "The wall", 11, "poster_crew",
				[GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE], 0.55),
		# C · stand in the protest. No uncertainty about which one — the cost is the 110px
		# of bodies, paid going in and coming out.
		_mark(9, "Another mark", 12, "Stand where they're standing. That's the whole of it."),
		_perform(10, "The protest", 13, "protest",
				[GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING]),
		# The finale, offered only to a player who already did the work.
		_finale(11, "The last night", Tuning.RUN_LENGTH_DAYS, GameEnums.BlockPurpose.CIVIC),
	]
