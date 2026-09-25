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
## - `STATION_DOOR` sits on the pavement in front of the power station's front door
##   (`CityMap.power_station_door`), a bare point — the last night's hand-over.
## - `MAST` sits beside the foot of one of today's live loudspeaker masts, a bare point; reaching it
##   silences that mast for the rest of the run.
## - `NEIGHBOR` rides the neighbor (`task_event_id`), spawned out in the city walking home along a
##   real path; the walk is the deadline — see `ResistanceDirector._send_the_neighbor_home()`.
enum TargetKind { EVENT, SCAR, DOOR, PARK_SWING, STATION_DOOR, MAST, NEIGHBOR }

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
	## by `DOOR`, `PARK_SWING` and `STATION_DOOR`, which compute their own point from today's
	## city.
	var placement: Array[int] = []
	## The `EventDef` id a perform step's contact rides on, or the scar id a `SCAR` step looks
	## up. "" for a pickup and for the kinds that compute a bare point, none of which name a row.
	var task_event_id := ""
	var target_kind := TargetKind.EVENT
	## True for a one-place task: the red arrow points at it from the moment the mark is
	## touched until it is done, and its contact is never subject to
	## `ResistanceDirector._follow_her_between_look_alikes()`'s retargeting. False for the two
	## tasks any live instance answers (the man shouting, a roadblock), which earn no arrow and
	## retarget onto whichever instance she is within reach of, so the one she hands it to is the
	## one that counts. Unused by a pickup, which never draws the arrow; true for the finale, whose
	## door is one place.
	var is_one_place := true
	## Fraction of the day after which the step is gone for good. 0 means no deadline, which is
	## every task in the calendar: day 10's deadline is the neighbor's own walk home, not a clock.
	var deadline_fraction := 0.0
	## Only offered once the goal is already met — the finale.
	var needs_goal := false
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
## so `for_day()` has nothing to say about one.
static func for_day(day: int, completed: Array[int], failed: Array[int],
		goal_met: bool) -> Step:
	for step in all():
		if step.day != day:
			continue
		if not step.is_pickup and not step.needs_goal:
			continue
		if step.index in completed or step.index in failed:
			continue
		if step.needs_goal and not goal_met:
			continue
		return step
	return null

## The step whose task is warning the neighbor — the one `GameState.neighbor_was_taken()` asks
## about. Null on a calendar without one.
static func warning_step() -> Step:
	for step in all():
		if step.target_kind == TargetKind.NEIGHBOR:
			return step
	return null

## The day of the step whose task is the swing in one park — the day that park is forced open
## (`CityGenerator._plan_the_swing_park()`) — or 0 on a calendar without one.
static func swing_day() -> int:
	for step in all():
		if step.target_kind == TargetKind.PARK_SWING:
			return step.day
	return 0

## The kinds whose contact is a bare point the director computes from today's city rather than a
## tile type or a rider — and so the kinds `narrow_target_on()` answers for.
const NARROW_KINDS: Array[TargetKind] = [TargetKind.DOOR, TargetKind.PARK_SWING,
		TargetKind.STATION_DOOR]

## Whether `step`'s contact is a bare point this director computes from today's city rather than
## a rider — the narrow kinds and a mast's foot. A mast is not narrow: six of them stand across the
## city, and the task takes whichever live one the day's draw lands on.
static func sits_on_a_bare_point(step: Step) -> bool:
	return step != null and (step.target_kind in NARROW_KINDS or step.target_kind == TargetKind.MAST)

## Whether `step`'s contact may stand on held ground (`CityMap.is_held_at`). A hold keeps a
## catalogue row off ground something else has taken, and a contact is not a row: day 9's door
## stands on a region door's own segment, which is held so no row sits in the doorway, and the
## station's front door can face a street the day's spur turned into a region door. Nothing else
## asks this, so every other contact keeps the hold as one more refusal.
static func stands_on_held_ground(step: Step) -> bool:
	return step != null and step.target_kind in [TargetKind.DOOR, TargetKind.STATION_DOOR]

static func by_index(index: int) -> Step:
	for step in all():
		if step.index == index:
			return step
	return null

# ------------------------------------------------------------ narrow targets ---

## The step on `day` whose contact is one narrow place the day has to keep a route to — day 9's
## door, day 12's swing, the power station's front door on the last night — or null on every
## other day. A pure function of
## the day, never of what the run has done: the day's corridor is a pure function of the city and
## the day (`RouteTree.for_day`), and it is planned around this answer, so a day plans the same
## whether or not this run will actually be offered the step.
##
## **Narrow is the shape of the pool, not the importance of the task.** A mark's alleys and a
## rider's sidewalks are hundreds of tiles across the whole city, of which the day's obstruction
## seals off some but never plausibly all; a door, a swing and the station's front door are a
## handful of tiles in one place, which the day's own seals and bodies can ring entirely. These three are what the
## day's planning keeps a route to (`docs/CITY.md`, "Guarantees", the day's own half).
static func narrow_target_on(day: int) -> Step:
	for step in all():
		if step.day != day or step.is_pickup:
			continue
		if step.target_kind in NARROW_KINDS:
			return step
	return null

## Every tile `step`'s contact may stand on, before any of today's refusals — the pool
## `ResistanceDirector._place()` draws from, and the pool the day's planning keeps one reachable
## tile of. One function for both, so the tiles the planning protects are the tiles the director
## picks among. `region_plan` is today's (`City.region_plan()`); only a `DOOR` reads it.
##
## - **`DOOR`**: the middle tile of each of today's region-wall doors, **less any door whose own
##   segment borders the home block**. `RegionPlanner._union_atoms()` only atomises the one street
##   the doorstep notch opens onto, so the block's other bordering segments can become doors like
##   any other; the director places a door with `allow_held`, which skips `is_held_at()` — the half
##   of "nothing on the home block" that covers those streets (`CityMap.is_on_home_block`'s own doc
##   names `is_held_at` as the other half) — so the filter here is what keeps such a door out.
## - **`PARK_SWING`**: the swing of the one park the city chose for the task
##   (`CityGenerator.swing_park()`), which is forced open on the task's day whatever its arc has
##   reached (`CityState.purpose_of()`), at the point `City._dress_block()` draws the frame
##   (`CityMap.swing_position()`). Empty while that park is not open — on any other day, or once
##   she has taken it.
## - **`STATION_DOOR`**: the pavement tiles in front of the power station's front door
##   (`CityMap.power_station_door`), where she stands to reach it — the same tiles the day's
##   corridor grows its spur to (`RouteTree.for_day`). Empty on a city with no station, which
##   `CityGenerator.validate()` refuses.
static func target_candidates(step: Step, map: CityMap,
		region_plan: RegionPlanner.RegionPlan) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if not step or not map:
		return found
	if step.target_kind == TargetKind.STATION_DOOR:
		return map.rect_tiles(map.power_station_door) if map.has_power_station() else found
	if step.target_kind == TargetKind.DOOR:
		if not region_plan:
			return found
		var home_border := {}
		for segment in StreetNetwork.around_blocks(Rect2i(map.home_block, Vector2i.ONE)):
			home_border[segment.key()] = true
		for segment in region_plan.doors:
			if home_border.has(segment.key()):
				continue
			var rect := segment.tile_rect()
			found.append(rect.position + rect.size / 2)
		return found
	if step.target_kind == TargetKind.PARK_SWING:
		var park := CityGenerator.swing_park(map)
		var layout: BlockLayout = map.block_layouts.get(park)
		if layout and layout.playground in map.playgrounds:
			found.append(map.world_to_tile(map.swing_position(layout.playground)))
	return found

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

## The last night: the power station's front door, offered only at the goal, by the red arrow.
static func _finale(index: int, title: String, day: int, header: String) -> Step:
	var step := Step.new()
	step.index = index
	step.title = title
	step.day = day
	step.target_kind = TargetKind.STATION_DOOR
	step.needs_goal = true
	step.header = header
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

		# Day 8 · leave something at the burnt shell from day 3 — one place, red arrow. What she
		# carries is the neighbor's drawing, left in the stroller overnight, so the words say where
		# it came from rather than naming an "it" nothing showed. The
		# contact rides the run's own recorded `burnt_shell` scar (`EventDef.scar_id` on
		# `burning_building`); a run with no such scar falls back to an ordinary placement of
		# the same row on a reachable sidewalk, the smallest honest stand-in — see
		# `ResistanceDirector._begin_step()`.
		_mark(5, "Another mark", 8,
				"Something was left in the stroller in the night. Take it to the burnt building."),
		_perform(6, "The burnt shell", 8, "burnt_shell", [GameEnums.TileType.SIDEWALK], true,
				TargetKind.SCAR, false, "the burnt building"),

		# Day 9 · cross a named region door — one place, red arrow. The districts close that
		# morning (`Tuning.REGION_WALL_FIRST_DAY`) and this is the day she finds out whether a
		# stroller gets through one.
		_mark(7, "Another mark", 9, "Cross at the district door. Find out if it lets a stroller through."),
		_perform(8, "The crossing", 9, "", [], true, TargetKind.DOOR, false,
				"the district door"),

		# Day 10 · warn the neighbor before the raid — one place, red arrow, and a deadline. The
		# regime has found the worker; the neighbor is out in the city and walks home into the
		# vans, and the walk is the deadline. Warned, they run; not warned, they are taken.
		_mark(9, "Another mark", 10,
				"They come for your neighbor tonight. Get to them first."),
		_perform(10, "Warn the neighbor", 10, "neighbor", [GameEnums.TileType.SIDEWALK], true,
				TargetKind.NEIGHBOR, false, "your neighbor, on the way home"),

		# Day 11 · silence a loudspeaker mast — one place, red arrow. She reaches its foot, as she
		# touches a mark, and it stays quiet for the rest of the run; its field makes the approach
		# cost while it broadcasts, so timing it between broadcasts is the skill. The rehearsal:
		# a mast's feed can be cut by hand, nobody comes, and the masts have no power of their own.
		_mark(11, "Another mark", 11,
				"Silence the loudspeaker mast. The wire is at its foot."),
		_perform(12, "Silence a mast", 11, "", [], true, TargetKind.MAST, false,
				"the loudspeaker mast"),

		# Day 12 · the swing on the playground of one specific park — one place, red arrow. The
		# park is the one the city chose for it (`CityGenerator._plan_the_swing_park()`), forced
		# open today whatever its arc has reached, and taken once she has reached the swing.
		_mark(13, "Another mark", 12, "Go to the swing. Get there before they close the gate."),
		_perform(14, "The swing", 12, "", [], true, TargetKind.PARK_SWING, false,
				"the park's own swing"),

		# Day 13 · walk into a roadblock's band — any of them. The army arrived that morning;
		# nobody looks twice at a parent walking a baby who won't settle. A roadblock is solid, so
		# the words ask how close she gets rather than for a way through it.
		_mark(15, "Another mark", 13,
				"Walk up to the roadblock. See how close they let you come."),
		_perform(16, "Into a roadblock's band", 13, "roadblock",
				[GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING], false, TargetKind.EVENT,
				false, "the roadblock"),

		# The finale, offered only to a player who already did the work: the power station's
		# front door, one place, by the red arrow. She hands the key over there and walks away.
		_finale(17, "The last night", Tuning.RUN_LENGTH_DAYS, "the power station's front door"),
	]
