class_name SeparationPass
extends RefCounted
## **The crowd gives way to the movers that keep their course** (inbox #884 in plaid-raven): when
## an event figure, an event car or a cordon officer and the crowd meet, a walker steps aside or is
## pushed and a crowd car stands, while the figure keeps its course and its timing. This is the
## world's half of it, the geometry over the map's list of moves (`ProposedMoves`): which of them a
## yielding body gives way to, where a body would stand clear of them, and how much road a car has
## before one. The crowd's half — a walker's sidestep, a car's brake and hold — is the crowd's own
## (`LaneStrategy.give_way_on_the_step()`), asked at each crowd body's own step, between its
## proposal and its check (`MoveProposal`).
##
## **Who is given way to** (a "keeper", a name of this class's, for a mover that keeps its course,
## each held as a `Keeper`): every move on the list that does not give way (`MoveProposal.yields`
## false), has a body (`radius` above zero) and has moved since this pass first saw it. The last
## clause is what leaves out what stands where it was placed all day — a market stall, a burnt-out
## car, a street musician, a puddle of a burst water main, a loudspeaker's mast — none of which walks
## into anybody, and whose solid bodies the crowd already goes round (`CityMap.obstructed_tiles`). A
## figure that has walked once is given way to from then on, standing or moving.
##
## **Read at each crowd body's own step, against the others' committed poses.** `gather()` takes the
## keepers off the list once a crowd tick, at its start, before any crowd body steps, and notes each
## one's pose (`MoveProposal.from`, the pose it committed). The events and the cordon step before the
## crowd in a tick (`City` adds the event manager first), so a crowd body gives way to where each
## figure stands this tick, and no figure reads where a crowd body went. **How a keeper moves is
## measured here, between two gatherings**, not read off its own step: a mover that stops stepping
## while it stays in the world (an event that has finished and not yet gone) then reads as standing
## still, which it is.

## `Keeper.ticks_still` for one that has not moved since this pass first saw it.
const NEVER_MOVED := 1 << 30
## A margin for the rectangle test in `is_near()` that covers the reach of every keeper's body: the
## column's trucks are the widest, 26px round their centres.
const _WIDEST_REACH := 64.0

var _moves: ProposedMoves
## Every move this pass has seen that could be a keeper, by move, so its pose and stillness carry
## from one gathering to the next; one that leaves the list is dropped at the next gathering.
var _seen := {}
## This tick's keepers, in the order their moves joined the list.
var _keepers: Array[Keeper] = []
## The rectangle round every keeper's centre this tick, so a body far from all of them asks nothing
## more (`is_near()`): most of the crowd on most ticks, since the figures stand round her and the
## crowd's box is wider than that.
var _bounds := Rect2()

func _init(moves: ProposedMoves) -> void:
	_moves = moves

## Takes this tick's keepers off the list (see the class doc), with how far each moved since the
## last gathering. Once a crowd tick, at its start (`Crowd._advance_the_world()`).
func gather() -> void:
	_keepers.clear()
	var still_here := {}
	for move in _moves.all():
		if move.yields or move.radius <= 0.0:
			continue
		var keeper: Keeper = _seen.get(move)
		if keeper == null:
			keeper = Keeper.new(move)
			_seen[move] = keeper
		keeper.look()
		still_here[move] = keeper
		if keeper.ticks_still == NEVER_MOVED:
			continue
		if _keepers.is_empty():
			_bounds = Rect2(keeper.at, Vector2.ZERO)
		else:
			_bounds = _bounds.expand(keeper.at)
		_keepers.append(keeper)
	_seen = still_here

## Whether a point at `at` is within `reach` of the rectangle round every keeper this tick: false
## for a body that no keeper can concern within that reach, which then asks nothing more.
func is_near(at: Vector2, reach: float) -> bool:
	return not _keepers.is_empty() and _bounds.grow(reach).has_point(at)

## Whether there is anybody to give way to this tick: false on most ticks of most days, and then a
## crowd body asks nothing more.
func has_keepers() -> bool:
	return not _keepers.is_empty()

## This tick's keepers, for a body that looks at each in turn (a walker making way for one). Read,
## never written.
func keepers() -> Array[Keeper]:
	return _keepers

## **Where a round body's proposed step (`move.to`) stands clear of every keeper's body**: moved
## straight out from each keeper it would overlap to where the two bodies touch (`move.radius` plus
## the keeper's), the keepers taken in turn; `move.to` itself when it overlaps none. A body exactly
## on a keeper's centre goes out along `side`. Positional, never a force, as every separation
## between bodies here is (the **crowd-traffic** skill): a body a figure walks into is pushed out of
## it on the tick it would be inside it.
func clear_of_the_keepers(move: MoveProposal, side: Vector2) -> Vector2:
	var at := move.to
	for keeper in _keepers:
		var reach := move.radius + keeper.radius
		var offset := at - keeper.at
		var distance_squared := offset.length_squared()
		if distance_squared >= reach * reach:
			continue
		var distance := sqrt(distance_squared)
		at = keeper.at + (offset / distance if distance > 0.01 else side) * reach
	return at

## **Where a round body's proposed step stands clear of every keeper's body, moved along `axis`
## only**: as `clear_of_the_keepers()`, but each keeper is cleared by moving ahead of it or back
## behind it along `axis`, whichever side of it the body is on, the coordinate across `axis` kept.
## For a body that cannot move across: one a figure squeezes against a wall.
func clear_along(move: MoveProposal, axis: Vector2) -> Vector2:
	var at := move.to
	for keeper in _keepers:
		var reach := move.radius + keeper.radius
		var offset := at - keeper.at
		if offset.length_squared() >= reach * reach:
			continue
		var along := offset.dot(axis)
		var across := offset - axis * along
		var needed := sqrt(maxf(0.0, reach * reach - across.length_squared()))
		at = keeper.at + across + axis * (needed if along >= 0.0 else -needed)
	return at

## **How far down a lane a body at `at` has before a keeper's body**, travelling `forward`: the
## distance along `forward` from `at` to the near edge of the first keeper whose body lies in, or
## within `lead_ticks` of its own travel comes into, the band `half_width` either side of the line,
## ahead of `at` and within `reach` of it; `INF` for none. Only keepers that moved within the last
## `under_way_within` ticks count. **Across the line a keeper's body counts for at most `widest`**:
## a move's `radius` is the circle round its whole body, which for a car is its length, and a car
## passing in the next lane is not in this one. What a crowd car brakes for
## (`CarStrategy._give_way()`).
func edge_ahead(at: Vector2, forward: Vector2, half_width: float, widest: float, reach: float,
		lead_ticks: float, under_way_within: int) -> float:
	if not is_near(at, reach + _WIDEST_REACH):
		return INF
	var side := Vector2(-forward.y, forward.x)
	var nearest := INF
	for keeper in _keepers:
		if keeper.ticks_still > under_way_within:
			continue
		var offset := keeper.at - at
		var along := offset.dot(forward)
		if along <= 0.0 or along - keeper.radius > reach:
			continue
		var width := half_width + minf(keeper.radius, widest)
		var lateral := offset.dot(side)
		if absf(lateral) > width:
			# Coming into the band within the lead, along its last step: where its line of travel
			# crosses the band's edge, if it does.
			var drift := keeper.step * lead_ticks
			var lateral_then := lateral + drift.dot(side)
			if signf(lateral_then) == signf(lateral) and absf(lateral_then) > width:
				continue
			along += drift.dot(forward) * (absf(lateral) - width) / absf(lateral - lateral_then)
			if along <= 0.0:
				continue
		nearest = minf(nearest, along - keeper.radius)
	return nearest

## **How far a capsule may move along `forward` from `at` before it touches a keeper ahead of its
## centre**: a body whose spine runs `half_length` either side of `at` along `forward`, rounded by
## `radius`, against every keeper that moved within the last `under_way_within` ticks, whose centre
## is ahead of `at` and nearer the line than `radius` and at most `widest` of its own (as in
## `edge_ahead()`); `INF` for none, `0.0` for one it touches already. What a crowd car's step is held
## to (`CarStrategy.give_way_on_the_step()`).
func room_ahead(at: Vector2, forward: Vector2, half_length: float, radius: float, widest: float,
		under_way_within: int) -> float:
	if not is_near(at, half_length + radius + _WIDEST_REACH):
		return INF
	var side := Vector2(-forward.y, forward.x)
	var room := INF
	for keeper in _keepers:
		if keeper.ticks_still > under_way_within:
			continue
		var offset := keeper.at - at
		var along := offset.dot(forward)
		if along <= 0.0:
			continue
		var lateral := absf(offset.dot(side))
		if lateral >= radius + minf(keeper.radius, widest):
			continue
		var reach := radius + keeper.radius
		room = minf(room, maxf(0.0, along - half_length - sqrt(maxf(0.0, reach * reach
				- lateral * lateral))))
	return room

## **One mover that keeps its course, as this pass sees it**: its move, the pose it stood at when
## last gathered, how far it moved since the gathering before, and how many gatherings in a row it
## has stood still.
class Keeper extends RefCounted:
	## Its move on the map's list, read for its pose and reach.
	var move: MoveProposal
	## Where it stands this tick: its committed pose when last gathered.
	var at := Vector2.ZERO
	## How far it moved between the last two gatherings, one tick apart in the game: its heading and
	## its speed per tick.
	var step := Vector2.ZERO
	## How many gatherings in a row it has stood still, or `NEVER_MOVED` while it has not moved since
	## this pass first saw it.
	var ticks_still := NEVER_MOVED
	## How far its body reaches round its centre (`MoveProposal.radius`).
	var radius := 0.0

	func _init(of: MoveProposal) -> void:
		move = of
		at = of.from

	## Reads its pose off its move: how far it went since the last look, and whether it stood.
	func look() -> void:
		radius = move.radius
		step = move.from - at
		at = move.from
		if step != Vector2.ZERO:
			ticks_still = 0
		elif ticks_still < NEVER_MOVED:
			ticks_still += 1
