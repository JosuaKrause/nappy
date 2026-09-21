class_name ResistanceSteps
extends RefCounted
## The resistance subquest, as data. See docs/NARRATIVE.md.
##
## The design constraint every step obeys: joining the resistance must cost the core
## resource. A task is one day: she touches the chalk mark, the task is announced there and
## then — in the world, never in the day brief — and it is performed the same day. Every task
## day still owns two entries here, a mark and the perform it unlocks, because the mark is
## found by walking past it and the task is a place or a rider the mark cannot also be — but
## both carry the same `day`, and `ResistanceDirector` activates the perform half the instant
## the mark is touched rather than waiting for the next day's dawn. Only the perform half
## grants progress toward `Tuning.RESISTANCE_GOAL`; picking up a note is not the errand.

## How a perform step's contact is placed once its mark is touched.
## - `EVENT` rides a freshly spawned `EventInstance` of `task_event_id`, at a tile from
##   `placement` — the man shouting, the van, the roadblock.
## - `SCAR` rides the run's own recorded scar for `task_event_id` (`GameState.scars`), or falls
##   back to `EVENT`'s own placement when the run has no such scar.
## - `DOOR` sits at one of today's region-wall doors, a bare point rather than a rider.
## - `PARK_SWING` sits at the swing of one specific park's playground, also a bare point.
enum TargetKind { EVENT, SCAR, DOOR, PARK_SWING }

class Step extends RefCounted:
	var index := 0
	var title := ""
	## The calendar day this task belongs to. A mark and the perform it unlocks share one day —
	## the perform is never offered at dawn (see `ResistanceSteps.for_day()`), only activated by
	## the mark that precedes it in `_build()`.
	var day := 0
	## True for a chalk-mark pickup. False for a perform step and for the finale.
	var is_pickup := false
	## Whether completing this step counts toward `Tuning.RESISTANCE_GOAL`. False for a
	## pickup — the errand is the perform half, not the note.
	var grants_progress := true
	## Tile types the contact may sit on. For a pickup this is where the mark waits; for an
	## `EVENT` or a `SCAR` fallback it is where the task's own `EventInstance` is sited. Unused
	## by `DOOR` and `PARK_SWING`, which compute their own point from today's city.
	var placement: Array[int] = []
	## Placed in or around this district instead, when set. Only the finale uses this.
	var district := -1
	## The `EventDef` id a perform step's contact rides on, or the scar id a `SCAR` step looks
	## up. "" for a pickup, the finale, `DOOR` and `PARK_SWING`, none of which name a row.
	var task_event_id := ""
	var target_kind := TargetKind.EVENT
	## True for a one-place task: the red arrow points at it from the moment the mark is
	## touched until it is done, and its contact is never subject to `_track_first_reached()`'s
	## retargeting. False for the two tasks any live instance answers (the man shouting, a
	## roadblock), which earn no arrow and do retarget onto whichever instance she reaches
	## first. Unused by a pickup and by the finale, neither of which ever draws the arrow.
	var is_one_place := true
	## Fraction of the day after which the step is gone for good. 0 means no deadline. No task
	## built this slice carries one; kept for the two days a later slice adds.
	var deadline_fraction := 0.0
	## Only offered once the goal is already met — the finale.
	var needs_goal := false
	## False for a day whose task is not yet built. `ResistanceSteps.for_day()` never returns
	## such a step, so a day whose task is unavailable has no mark at all — see `_build()`'s own
	## comment on days 10 and 11.
	var available := true
	## The chalk mark's own words, announced the instant she touches it — see
	## `ResistanceDirector._on_contact_completed()` and `Hud._on_resistance_step_completed()`.
	## "" for anything that is not a pickup.
	var brief := ""
	## The HUD header's own line while this perform step is on offer — `Step.title` stays for
	## the progress dots, never the header, because a bare noun ("A note for a stranger") is
	## what playtest 69 could not use ("note for a stranger contains less information than
	## won't stop shouting"). The wording rule: this is the associated pickup's own `brief`
	## text, cut to the one clause that is the instruction rather than the framing. "" for a
	## pickup and the finale, neither of which the header names this way — see
	## `hud.gd:_refresh_resistance()`.
	var header := ""
	## True for the one perform step that makes the pram heavier for the rest of the day.
	var applies_package_weight := false

static var _all: Array[Step] = []

static func all() -> Array[Step]:
	if _all.is_empty():
		_all = _build()
	return _all

## Only ever returns a pickup or the finale — a perform step is never offered at dawn, it is
## activated the instant its own mark is touched (`ResistanceDirector._on_contact_completed()`),
## so `for_day()` has nothing to say about one. A day whose only step is `not available` (10, 11
## this slice) answers null, which is what leaves it with no mark.
static func for_day(day: int, completed: Array[int], failed: Array[int],
		goal_met: bool) -> Step:
	for step in all():
		if step.day != day or not step.available:
			continue
		if not step.is_pickup and not step.needs_goal:
			continue
		if step.index in completed or step.index in failed:
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
static func _mark(index: int, title: String, day: int, brief: String) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.day = day
	step.is_pickup = true
	step.grants_progress = false
	step.placement.assign([GameEnums.TileType.ALLEY])
	step.brief = brief
	return step

static func _perform(index: int, title: String, day: int, task_event_id: String,
		placement: Array, is_one_place: bool, target_kind: TargetKind = TargetKind.EVENT,
		applies_package_weight: bool = false, header: String = "") -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.day = day
	step.task_event_id = task_event_id
	step.placement.assign(placement)
	step.target_kind = target_kind
	step.is_one_place = is_one_place
	step.applies_package_weight = applies_package_weight
	step.header = header
	return step

## A step for a day whose task is not yet built — see the comment in `_build()` for why. Never
## returned by `for_day()`, so it places no mark and asks nothing of `ResistanceDirector`.
static func _unavailable(index: int, title: String, day: int) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.day = day
	step.available = false
	return step

static func _finale(index: int, title: String, day: int, district: int) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.day = day
	step.district = district
	step.needs_goal = true
	step.is_one_place = false
	return step

static func _build() -> Array[Step]:
	return [
		# Day 6 · a note for the man shouting — any of them. He is the group's lookout, and
		# the cost is the approach: several homeless_yeller rows are already live, and the one
		# carrying the contact looks exactly like the rest of them.
		_mark(1, "A chalk mark", 6, "Give it to the one who won't stop shouting."),
		_perform(2, "A note for a stranger", 6, "homeless_yeller",
				[GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE], false,
				TargetKind.EVENT, false, "the one who won't stop shouting"),

		# Day 7 · the package at a delivery_van's drop — one place, red arrow. From the group
		# to the neighbor down the hall; carrying it makes the pram heavier for the rest of the
		# day.
		_mark(3, "Another mark", 7, "A van is waiting on the sidewalk. Don't come home light."),
		_perform(4, "The package", 7, "delivery_van", [GameEnums.TileType.SIDEWALK], true,
				TargetKind.EVENT, true, "a van, waiting"),

		# Day 8 · leave something at the burnt shell from day 3 — one place, red arrow. The
		# contact rides the run's own recorded `burnt_shell` scar (`EventDef.scar_id` on
		# `burning_building`); a run with no such scar falls back to an ordinary placement of
		# the same row on a reachable sidewalk, the smallest honest stand-in — see
		# `ResistanceDirector._begin_step()`.
		_mark(5, "Another mark", 8, "Leave it at the burnt building. Nobody goes there but you."),
		_perform(6, "The burnt shell", 8, "burnt_shell", [GameEnums.TileType.SIDEWALK], true,
				TargetKind.SCAR, false, "the burnt-out building"),

		# Day 9 · cross a named region door — one place, red arrow. The districts close that
		# morning (`Tuning.REGION_WALL_FIRST_DAY`) and this is the day she finds out whether a
		# stroller gets through one.
		_mark(7, "Another mark", 9, "Cross at the district door. Find out if it lets a stroller through."),
		_perform(8, "The crossing", 9, "", [], true, TargetKind.DOOR, false,
				"the district door"),

		# Days 10 and 11 wait on a later slice: day 10 (warn the neighbor before the raid,
		# with a deadline) needs a new figure in the event catalogue, and day 11 (silence a
		# loudspeaker mast) waits on M180, posters she notices, and loudspeakers that are
		# somewhere, to give the mast a body and a field to silence. `_unavailable()` keeps the
		# calendar's own shape complete without offering either mark.
		_unavailable(9, "Warn the neighbor", 10),
		_unavailable(10, "Silence a mast", 11),

		# Day 12 · the swing on the playground of one specific park — one place, red arrow. A
		# calm area is not reusable, so the park she is sent to is whichever one this run's
		# playgrounds still leave open today; see `ResistanceDirector._place_at_a_swing()` for
		# why "forced open whatever its state" is not this slice's to build.
		_mark(11, "Another mark", 12, "Go to the swing. Get there before they close the gate."),
		_perform(12, "The swing", 12, "", [], true, TargetKind.PARK_SWING, false,
				"the park's own swing"),

		# Day 13 · walk into a roadblock's band — any of them. The army arrived that morning;
		# nobody looks twice at a screaming baby.
		_mark(13, "Another mark", 13, "Walk straight through the roadblock. Not around it."),
		_perform(14, "The roadblock", 13, "roadblock",
				[GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING], false, TargetKind.EVENT,
				false, "the one you go through, not around"),

		# The finale, offered only to a player who already did the work. Day 14 keeps the
		# civic-district contact it has today; the power station's front door is M183's.
		_finale(15, "The last night", Tuning.RUN_LENGTH_DAYS, GameEnums.BlockPurpose.CIVIC),
	]
