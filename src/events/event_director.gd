class_name EventDirector
extends RefCounted
## Places the events whose content is *the moment they happen to you* rather than *where they
## are*: the ones the day budgets and the player's own walk sites.
##
## A cat that happens where it spawns is a cat nobody meets; it has to arrive in front of her
## while she walks, every time.
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
func start_day(day: int, plans: Array[EventScheduler.Planned],
		rng: RandomNumberGenerator) -> void:
	_owed.clear()
	_rng = rng
	for plan in plans:
		if plan.def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
			_owed.append(plan.def)
	# The first one is not free: a cat on the doorstep before she has taken a step reads as the
	# game starting badly rather than as something happening.
	_next_in = _roll_interval()
	_teach_the_run(day)

## Puts the day-3 lesson at the front of the queue: the day running becomes the answer opens with
## an incident that requires it.
##
## Running is a trap against every other row in the catalogue and is meant to be — so the day the
## exception arrives, the game cannot leave finding it to chance. `charging_dog` is `weight 1.4`
## of a day-3 pool and it would otherwise land whenever it landed, which for the one event that
## teaches a control is not good enough.
##
## Two things, and only on that day: the pursuit is moved to the head of the owed list, and the
## first interval is cut to a lesson rather than an ambush. `LESSON_DELAY` is far enough in that
## she is walking and off the doorstep — the director will not site anything while she is standing
## still — and early enough that it is the first thing that happens to her.
##
## It is *not* a scripted event, and that is deliberate: it is one of the day's own budgeted
## `AHEAD_OF_PLAYER` plans, so teaching the run cannot quietly make day 3 denser than the budget
## says. If the day happened not to buy one, there is nothing to teach and nothing happens.
func _teach_the_run(day: int) -> void:
	if day != Tuning.RUN_TAUGHT_DAY:
		return
	for i in _owed.size():
		if not _owed[i].pursues:
			continue
		_owed.push_front(_owed.pop_at(i))
		_next_in = LESSON_DELAY
		return

## How far into day 3 the lesson lands. A few seconds of ordinary walking first, so that what
## happens reads as the day changing rather than as the day starting.
const LESSON_DELAY := 6.0

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

	# Peeked rather than popped, because what it wants sited depends on what it is: a pursuer is
	# put *in her way* rather than across it, and a placement that fails must not spend the event.
	var next := _owed[0] as EventDef
	var path := _crossing_ahead_of(at, velocity / speed, next)
	if path.is_empty():
		# Nowhere to put it — she is in the middle of a park, or against the map edge. Try
		# again shortly rather than burning the allowance on a place that would not read.
		_next_in = 1.0
		return []
	_next_in = _roll_interval()
	return [_owed.pop_front() as EventDef, path]

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
##
## **A pursuer is sited at the lead point itself and given no route.** It does not cross her line,
## it comes down it, so a path is the wrong shape for it entirely — and building one anyway puts
## the day-3 dog a street's width off to one side of the place this function has just checked,
## 266px away and diagonal, which on a 640x360 view is at the corner of the screen or past it. What
## she is owed is the sight of it coming, and it has to be sited where that can be seen.
##
## **And a pursuer is sited as far ahead as it can be seen from**, which is `Tuning.SIGHT_AHEAD`
## flat rather than a clamp against `AHEAD_LEAD_DISTANCE`: that is a *cat's* reaction window and has
## nothing to do with a chase, and everything between the siting and the stand-off is the only
## notice a pursuit has left to give.
##
## The arithmetic is why it is the cap rather than a choice. The lunge is fired by
## **proximity** — see `EventInstance._lunged` — so the notice a player gets is the time it takes
## the gap to fall from the lead to `Tuning.pursuit_standoff()`, and she is usually walking *into*
## it, so that gap closes at her speed plus its own. There are 96px of it at 200px of lead and
## 80px at 184, which is the difference between 0.43s and 0.38s: small, and it is all there is.
## Siting further out is not available at any price — the visible world is 360px tall, and a dog
## telegraphing off the top of the screen has no telegraph at all.
func _crossing_ahead_of(at: Vector2, heading: Vector2,
		def: EventDef = null) -> PackedVector2Array:
	var lead := Tuning.AHEAD_LEAD_DISTANCE
	if def and def.pursues:
		lead = Tuning.SIGHT_AHEAD
	var centre := at + heading * lead
	if not _map.is_walkable(_map.world_to_tile(centre)):
		return PackedVector2Array()
	if def and def.pursues:
		return PackedVector2Array([centre])
	var across := Vector2(-heading.y, heading.x) * float(CROSSING_REACH_TILES * Tuning.TILE_SIZE)
	# The side it comes from is a coin flip, so a player cannot learn to watch one shoulder.
	if _rng.randf() < 0.5:
		across = -across
	var from := centre - across
	var to := centre + across
	if not _map.in_bounds(_map.world_to_tile(from)) or not _map.in_bounds(_map.world_to_tile(to)):
		return PackedVector2Array()
	return PackedVector2Array([from, to])
