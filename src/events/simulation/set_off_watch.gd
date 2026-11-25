class_name SetOffWatch
extends RefCounted
## **The places that set a row off** (`EventDef.is_set_off_by_a_place()`): the masked man on the
## escape's stairs, and the escape city's explosions. *(minty-dolphin #852: "Stair guard could as well be placed when it should appear
## instead of when entering"; "The stair guard can become a charger that is triggered by a location
## if necessary"; "Anyway a badge shouldn't disappear before the entity is visible".)* A plan of such
## a row is not in the world until she comes within its row's `sets_off_within()` of where it
## starts; then its warning goes up first (`WarningBoard.warn_first()`), its screen-edge badge
## pointing at that place, and once the warning has run the plan comes into the world there
## (`EventStreaming.set_off()`), with its telegraph spent — the masked man running his line, an
## explosion going off — keeping the badge until she can see it.
##
## **Walking into the place sets it off at once** (`EventDef.as_set_off_at_once()`) where the
## row's set-off distance alone is the warning it owes (`EventDef.may_be_set_off_at_once()`): the
## warning goes up and the thing comes on the same tick, so it comes exactly as near as its set-off
## distance. **Inside the place already when it may come**, a fresh one after the last has run, or
## arriving inside through a door, and for a row whose distance is not warning enough however she
## came in (an explosion, whose noise is on her the moment it goes off), the badge is up alone for
## the row's own `warned_for()` first, so it never comes at her with no warning at all. It comes
## only where everything it puts on the screen at its place, what it leaves there included (the
## explosion's crater), is out of her sight, since nothing appears in her view; until then it waits.
##
## Handed the world the events stand in (`EventWorld`: where she can see), the streaming that brings
## a plan into the world and says whether it may come (`EventStreaming`), the board its warning goes
## up on (`WarningBoard`) and the walk's plans (`WalkEvents`).

var _world: EventWorld
var _streaming: EventStreaming
var _warnings: WarningBoard
var _walk: WalkEvents
## Where she stood on the tick before, `Vector2.INF` before the first: what tells walking into a
## place from being inside it already.
var _was := Vector2.INF
## The plans whose warning is up, so a second is not put up beside it.
var _warned: Dictionary[EventPlan, bool] = {}

func _init(world: EventWorld, streaming: EventStreaming, warnings: WarningBoard,
		walk: WalkEvents) -> void:
	_world = world
	_streaming = streaming
	_warnings = warnings
	_walk = walk

## Forgets every warning it had up and where she stood: a walk's start, when the board is cleared.
func clear() -> void:
	_warned.clear()
	_was = Vector2.INF

## One tick with her standing at `here`: every plan a place sets off that may come now
## (`EventStreaming.may_set_off()`), with no warning of it up yet, and with her inside its place,
## is set off. Run every tick there is a player, before the warnings are run, so one set off at once
## comes on this tick.
func watch(here: Vector2) -> void:
	for plan in _walk.plans():
		if not plan.is_set_off_by_a_place() or _warned.has(plan) \
				or not _streaming.may_set_off(plan):
			continue
		var start := plan.placed_at()
		var within := plan.sets_off_within()
		if here.distance_to(start) > within:
			continue
		_set_off(plan, here, _walked_in(start, within, here))
	_was = here

## Whether her step from the tick before to `here` walked into the place within `within` of
## `start`: outside it on the tick before, and no further away than a tile, so a door that put her
## inside is not a walk.
func _walked_in(start: Vector2, within: float, here: Vector2) -> bool:
	return _was != Vector2.INF and _was.distance_to(start) > within \
			and _was.distance_to(here) <= Tuning.TILE_SIZE

## Puts up the warning of `plan`, for her standing at `here`: no time alone where she walked in
## and its row may come at once, its row's own otherwise. Nothing goes up while the place it starts at is in her sight.
func _set_off(plan: EventPlan, here: Vector2, walked_in: bool) -> void:
	var at_once := walked_in and plan.row().may_be_set_off_at_once()
	var row := plan.row().as_set_off_at_once() if at_once else plan.row()
	var start := plan.placed_at()
	var where := func(her: Vector2) -> Vector2:
		return start if _out_of_sight(row, start, her) else Vector2.INF
	var arrive := func(_place: Vector2, _her: Vector2) -> bool:
		_warned.erase(plan)
		return _streaming.set_off(plan)
	var warning := _warnings.warn_first(row, here, where, arrive)
	if warning == null:
		return
	_warned[plan] = true
	warning.when_withdrawn(func() -> void: _warned.erase(plan))

## Whether all of what `row` puts on the screen standing at `at`
## (`EventFootprints.footprint_of()`, what it leaves there included), is out of her sight now, her
## standing at `her`.
func _out_of_sight(row: EventDef, at: Vector2, her: Vector2) -> bool:
	var siting := SpawnSiting.over(null, _world.visible_view())
	var asked := siting.ask_in_sight(EventFootprints.footprint_of(row), null, her)
	return siting.allows(SpawnSiting.Rule.OUT_OF_SIGHT, asked, at)
