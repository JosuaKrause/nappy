class_name EventDirector
extends RefCounted
## Places the events whose content is *the moment they happen to you* rather than *where they
## are*: the ones the day budgets and the player's own walk sites.
##
## Playtest 04: *"the cat is ineffective since it happens when it spawns — the cat should get
## spawned in in front of the player while they walk, so it happens directly in front of them
## every time."*
##
## That is a real distinction and not just a placement trick. A café spilling across a pavement
## is a *place*: it is worth putting on a map because knowing it is there changes the route you
## pick, and walking a street to find out is the game. A cat bolting is worth nothing at all as
## a place — you cannot plan around a thing that lasts three seconds, and a cat that ran across
## an empty road two blocks away was, for six milestones, an event the player had no way of ever
## meeting. It only exists as an interruption, so it is authored as one.
##
## **What is deliberately kept.** The day's budget still buys it, in `EventScheduler`, at the
## same cost as everything else — so making the cat land cannot quietly make the day denser
## too. And the spawn is far enough ahead to be a *reaction window*: `AHEAD_LEAD_DISTANCE` is
## two seconds of walking, and the cat starts a street's width off to one side, so she is
## outside its outer radius the whole time it is crouching. That is the telegraph fairness
## contract holding for an event that arrives without warning, which is the only way one is
## allowed to.
##
## Determinism is the day's RNG on its own stream, as everything else is. The *timing* depends
## on where the player walked, so no seed reproduces it from outside — which is exactly what
## `Telemetry`'s `roll` entries exist to write down.

## How far to either side of the crossing point the run reaches. A street's width, so the cat
## comes out of one kerb and is gone into the other.
const CROSSING_REACH_TILES := Tuning.STREET_WIDTH

var _map: CityMap
var _rng := RandomNumberGenerator.new()
## The events the day has budgeted and not yet spent, in the order the scheduler asked for.
var _owed: Array[EventDef] = []
var _next_in := 0.0

func _init(map: CityMap) -> void:
	_map = map

## Takes over the day's `AHEAD_OF_PLAYER` plans. Called with the same plan list the manager
## streams the sited events from, so the two halves of a day cannot disagree about what is owed.
func start_day(plans: Array[EventScheduler.Planned], rng: RandomNumberGenerator) -> void:
	_owed.clear()
	_rng = rng
	for plan in plans:
		if plan.def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
			_owed.append(plan.def)
	# The first one is not free: a cat on the doorstep before she has taken a step reads as the
	# game starting badly rather than as something happening.
	_next_in = _roll_interval()

func owed() -> int:
	return _owed.size()

## Advances the clock and returns the event to place plus the path to place it on, or null when
## nothing is due. `heading` is the direction she is actually travelling, not the way she is
## facing: something that crosses in front of a player standing still is not in front of
## anything.
##
## Returns `[EventDef, PackedVector2Array]`, or an empty array.
func due(delta: float, at: Vector2, velocity: Vector2) -> Array:
	if _owed.is_empty():
		return []
	var speed := velocity.length()
	# The clock only runs while she is going somewhere. A player who stops to let the meter
	# recover is not owed a cat for waiting, and one who spends the day in a park should not
	# come back to the pavement and be handed four of them at once.
	if speed < Tuning.AHEAD_MIN_SPEED:
		return []
	_next_in -= delta
	if _next_in > 0.0:
		return []

	var path := _crossing_ahead_of(at, velocity / speed)
	if path.is_empty():
		# Nowhere to put it — she is in the middle of a park, or against the map edge. Try
		# again shortly rather than burning the allowance on a place that would not read.
		_next_in = 1.0
		return []
	_next_in = _roll_interval()
	var def := _owed.pop_front() as EventDef
	return [def, path]

func _roll_interval() -> float:
	return _rng.randf_range(Tuning.AHEAD_INTERVAL.x, Tuning.AHEAD_INTERVAL.y)

## A run straight across her line, `AHEAD_LEAD_DISTANCE` in front of her.
##
## Perpendicular to *her* heading rather than to the street, which is the difference between a
## cat that crosses the road and a cat that crosses her path. On a pavement those are the same
## thing; walking across a square they are not, and the second one is what was asked for.
##
## Empty when the crossing point is not somewhere anybody could walk — the lead lands inside a
## building, or outside the map. The caller waits and asks again.
func _crossing_ahead_of(at: Vector2, heading: Vector2) -> PackedVector2Array:
	var centre := at + heading * Tuning.AHEAD_LEAD_DISTANCE
	if not _map.is_walkable(_map.world_to_tile(centre)):
		return PackedVector2Array()
	var across := Vector2(-heading.y, heading.x) * float(CROSSING_REACH_TILES * Tuning.TILE_SIZE)
	# The side it comes from is a coin flip, so a player cannot learn to watch one shoulder.
	if _rng.randf() < 0.5:
		across = -across
	var from := centre - across
	var to := centre + across
	if not _map.in_bounds(_map.world_to_tile(from)) or not _map.in_bounds(_map.world_to_tile(to)):
		return PackedVector2Array()
	return PackedVector2Array([from, to])
