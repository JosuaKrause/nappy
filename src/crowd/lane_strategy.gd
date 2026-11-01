class_name LaneStrategy
extends RefCounted
## What differs between a walker and a car moving on the lattice's lanes, behind one set of
## questions the mover asks: `WalkerStrategy` and `CarStrategy` answer them, and `LaneMover` — the
## mover — keeps everything the two kinds share (the lane it is in, its look-ahead, the held step,
## placement and recycling, junction and queue questions) and never asks which kind it is.
##
## **One object per agent, handed its mover once.** A strategy holds the state only its kind has (a
## walker's door hold and sidesteps, a car's turn planning) and reads and writes the mover's lane
## state directly: the two are one feature split by kind, and the lane state stays on the mover
## because both kinds' every frame reads it. `LaneMover.kind` is what installs one, so setting the
## kind on a hand-built agent gives it that kind's rules at once.
##
## The answers below are the neutral ones — what a body with no rule of its own about the question
## does — and each kind overrides the questions it has a rule for.

## The layers both kinds ask first of a tile: today's closures, the fenced park's ground included.
static var _closed_today := Mover.of(Mover.CLOSED)

## The mover this strategy belongs to.
var _mover: LaneMover

## Half the length of the body along its own line of travel, which is what actually enters a
## junction box first and leaves it last. Zero for a walker, who is not what a box is rationed
## between.
var nose := 0.0

## How close the thing it cannot pass has to be before this agent does anything about it, in
## tiles — the whole of the difference between how the two kinds meet a barrier.
##
## **A car acts on the whole look-ahead because its answer is a junction away.** A turn is an arc
## that needs a junction box to fit in, and reversing where it stands is the last resort with no
## path in it, so a car that drove up to a wall would stand there nose-on and take the street behind
## it with it. It has to decide while the last junction is still in front of it, which is what
## `LaneMover.LOOKAHEAD_TILES` is measured to reach.
##
## **A walker acts only on the next tile, because its answer costs a stride.** *(2026-09-19:
## "pedestrians should only avoid the area if they cannot reach it physically. right now they give
## up if there is an event at all when they should only give up if they touch an impassable wall".)*
## A person turns round on the spot, so nothing is bought by deciding early and a great deal is
## lost: a street given up from a junction away is a street with nobody on it for the whole of its
## length, which is how side streets and sealed-off blocks came to stand empty. One tile rather than
## zero because the look-ahead is cached per tile and the step that would carry a walker into the
## thing is held (`LaneMover._keep_out_of_a_body()`), so "the next tile is shut" is the last moment
## a decision can still be taken with room to take it in.
var acts_within := 1

## Whether a segment held for today is shut to this agent. **A hold shuts a street to a car and not
## to a walker, and the asymmetry is the manoeuvre rather than a policy.** *(2026-09-19:
## "pedestrians should only avoid the area if they cannot reach it physically … they should only
## give up if they touch an impassable wall".)* Every held segment has something standing across the
## whole of it somewhere along its length — a hard seal, a region wall, a closure's barriers — and a
## car has to be turned away *before* it reaches that, because it cannot turn round against a
## barrier and one stopped nose to a wall holds the junction behind it. A walker turns in a stride
## wherever it is standing, so it needs no warning at all: it walks the street until it meets the
## body, which `CityMap.obstructed_tiles` records like any other, and turns there. The hold is what a
## car reads and the body is what a walker reads.
var shut_by_a_hold := false

## True while this agent has run out of road in **both** directions — only ever a car: less than a
## half turn's worth ahead of it and less than a half turn's worth in the lane it would reverse
## into. The mover recycles it once nobody can see it; `CarStrategy` sets and clears it.
##
## **It is a pocket one scale down.** A junction with all four arms shut catches a body between
## walls and `CrowdPockets` is what names that; a lane can be caught the same way between a
## precinct's paving and a solid body parked on it, which is a stretch of road too short to turn
## round in and is not a junction at all, so nothing above the lane can see it. What a body with
## nowhere to go does is settled — it stands where it is, and it leaves the way anybody else leaves
## the field, once nobody can see it go. Cleared by `_look_ahead()` the moment the road in front of
## it is clear again, so a seal that lifts puts the car back on the road rather than leaving it
## marked for the rest of the day.
var nowhere_to_turn := false

## Whether the look-ahead is asked from this agent's lane centre rather than from its body — a car's,
## not a walker's.
##
## **A car's question is about its lane.** The two are the same tile for a car sitting on its centre
## line and are different tiles for one that is still steering onto it, and the row either side of
## a carriageway lane is the *other* lane or the kerb — where a solid body that this car will never
## meet stands, and where a precinct's paving begins. A scan taken from the body's own tile
## therefore reports a wall two tiles ahead that is not on this car's road at all, and reports it
## *intermittently*, as the body crosses the row boundary and back: **a lane decision is stated over
## the lane, never over where the body happens to be.** A walker keeps asking from its body,
## because a walker with a detour running really is on the ground it is standing on and
## `WalkerStrategy._step_around_a_body()` is a question about that ground.
var scans_from_its_lane := false

## What today puts down that stops this kind, from the map's blocked record (`Mover`): where it may
## be placed and where it may stand.
var today: Mover

func _init(mover: LaneMover) -> void:
	_mover = mover

## This agent's own ground shape: a point for a walker, a capsule along the travel axis for a car.
func ground_shape() -> GroundShape:
	return GroundShape.point(7.0)

## The lanes this kind may start in across its corridor, at `along_tile` along it.
func lane_offsets_at(_along_tile: int) -> Array[int]:
	return []

## Why a pinned placement contradicts this kind's own lane rules, or empty when it does not.
func placement_problem() -> String:
	return ""

## The range this kind's ordinary speed is rolled from.
func speed_range() -> Vector2:
	return Vector2.ZERO

## Rolls this agent's answer at a region door, for a kind that has one.
func draw_the_door_answer() -> void:
	pass

## Whether this agent may stand on a tile outside the map.
func may_stand_off_the_map(_tile: Vector2i) -> bool:
	return false

## This kind's own clause of "standing somewhere it could have got to": the ground the mover's
## shared checks have already found open, in bounds and unheld.
func may_be_placed_on(_tile: Vector2i) -> bool:
	return true

## Whether a region door's segment, held for today, is shut to this agent.
func door_is_shut(_key: Vector3i) -> bool:
	return false

## Whether this agent stands on carriageway today's seals have shut in. See `CrowdPockets`.
func is_in_a_pocket() -> bool:
	return false

## This kind's own start of a frame, before the lane step. True when the frame ends here — the agent
## has moved itself, or stands held where it is (and has been recycled if it had to be) — so the
## lane step, look-ahead and recycling do not apply.
func begin_frame(_delta: float) -> bool:
	return false

## The speed the lane step advances at this frame, from the speed the agent travels at.
func paced(speed: float) -> float:
	return speed

## The velocity this agent travels at, from its heading times its speed.
func paced_velocity(moving: Vector2) -> Vector2:
	return moving

## This kind's own part of a frame after the lane step and before the look-ahead.
func after_the_step(_delta: float) -> void:
	pass

## Told when the look-ahead starts a fresh scan from `here`.
func on_new_scan(_here: Vector2i) -> void:
	pass

## Told when a fresh scan finds the road ahead clear as far as it looks.
func on_the_road_clear() -> void:
	pass

## Whether this agent cannot travel a tile, `vertical` being the axis it travels along.
func cannot_go_on(_vertical: bool, _tile: Vector2i) -> bool:
	return false

## Whether this agent's own centre may be on a tile.
func may_stand_on(_tile: Vector2i) -> bool:
	return true

## What this agent does about the thing it cannot pass, once it is within `acts_within` tiles.
func divert(_delta: float) -> void:
	pass

## Told once the mover has reversed this agent's direction where it stands.
func on_turned_round() -> void:
	pass

## One stride of this body, in px: the unit an about-face commits its new heading for.
func stride_length() -> float:
	return 1.0

## Picks a corridor, a lane in it, a direction and a speed. `roll` decides the axis for a kind that
## splits it evenly.
func choose_lane(_roll: float) -> void:
	pass

## Where this agent travels in its lane, across its corridor.
func lane_centre_here() -> float:
	return 0.0

## Drops whatever sidestep state this kind keeps beside the mover's steering offset.
func forget_the_detour() -> void:
	pass

## Gets this agent out of her way, for a kind that does.
func step_aside(_away: Vector2, _distance: float, _seconds: float) -> void:
	pass

## The clear road from its nose to an event figure it would stand for, looking `_reach` ahead of
## its centre, `INF` for none or for a kind that does not stand for one.
func road_before_a_figure(_reach := Tuning.CAR_ZEBRA_SIGHT) -> float:
	return INF

## Whether a parked event figure ahead blocks its way the way a closed tile does, for a kind that
## turns round at one (`CarStrategy.blocked_by_a_figure()`, inbox #909 in freckled-moose).
func blocked_by_a_figure() -> bool:
	return false

## Gets out of the way of somebody at `here` going `velocity`, for a kind that does.
func make_way_for(_here: Vector2, _velocity: Vector2) -> void:
	pass

## **Gives way, on this step, to the movers that keep their course** — event figures, event cars and
## cordon officers (`SeparationPass`, the map's): changes the step its mover has proposed
## (`LaneMover._move`) before the mover's own check holds it to the tiles it may stand on, for a kind
## that gives way. The crowd yields and an event figure keeps its course (inbox #884 in
## plaid-raven), so this is the only half of a meeting that moves anybody.
func give_way_on_the_step(_delta: float) -> void:
	pass

## One frame of this agent's own crossing of a checkpoint door, for a kind that crosses one.
func advance_the_door_hold(_delta: float) -> void:
	pass

## Whether this agent, at `at` along its axis on a map `limit` long, has gone past the edge of the
## map: a tile past it, for everybody but a car leaving by the spine. Outside the map is water,
## forest and mountainside, painted ground with no road on it, and the pavements do not carry on.
func has_left_the_map(at: float, limit: float) -> bool:
	var room := float(Tuning.TILE_SIZE)
	return at < -room or at > limit + room


## How far past the true edge a fresh recycle of this agent may land: nothing, for everybody but a
## car arriving on the spine.
func entry_room(_south: bool) -> float:
	return 0.0

## Moves a fresh entry past the map's edge out of anybody's sight, for a kind that enters there.
func hide_the_spine_entry() -> void:
	pass

## Told when the mover recycles this agent, before the placement's rolls.
func on_recycled() -> void:
	pass

## Takes up a lane and a speed at a stretch's end, the axis, corridor and direction already set.
## False when this kind has no lane there.
func enter_at_an_end(_along_tile: int) -> bool:
	return false

## Moves a fresh entry behind whatever already stands in its lane, for a kind that queues.
func join_the_back_of_the_queue() -> void:
	pass

## Tells the traffic index this agent is here, for a kind that queues.
func claim_the_road_here() -> void:
	pass

## Whether this agent stands in a piece of its own lane nobody else is in.
func has_room_here() -> bool:
	return true
