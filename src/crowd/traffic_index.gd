class_name TrafficIndex
extends RefCounted
## Where the cars are, lane by lane, so that one of them can ask whether there is room in a lane
## before it turns into it.
##
## **A turn is a placement, and until M38 it was the one placement nothing checked.** *(Reported
## as "when a car turns into an occupied lane the other car just disappears.")* `_divert()` picks
## an arm at a junction out of the tile map alone, so a car diverting round a closure lands wherever
## the lane happens to be occupied — and the M27 rule that separation between bodies is positional
## then resolves it by *moving* one of them. Resolving a queue front-to-back cascades, so the car
## behind is teleported back by the shortfall plus everything ahead of it. A probe parked at a
## closure measured a turn landing 66px from another car 152px from the player, and — over ninety
## seconds, ignoring the frame the day is built in and the recycles, which are teleports by design —
## **1627 corrections with a worst of 134px**, two car lengths of road gone in one frame in plain
## sight. With the turn looking first it is 146 corrections and a worst of 66px, which is one car
## easing off another rather than one of them leaving.
##
## The positional resolve is still right and stays exactly as it was. It is the backstop for the
## case it was written for — a car *recycled* into a lane at a point it could not see, which happens
## off screen at the entry band. What it should never have been is the routine outcome of a turn.
##
## Held by every agent the way `CrowdField` is, and for the same two reasons: an agent turns and
## recycles on its own, and a test steps agents by hand with no `Crowd` ticking. It is filled once
## a frame by `Crowd.space_out_the_traffic()`, out of the buckets that pass already sorts, so the
## whole thing costs one extra walk over the cars rather than a search per junction.
##
## It is a frame stale by construction, and that is fine: a car covers three pixels in a frame and
## the question asked of it is about a car's length.

## `lane_key -> PackedFloat32Array` of the queue positions in that lane.
var _lanes: Dictionary = {}

## Replaces the whole index. Called once a frame; nothing incremental, because a car changes lane
## and the old entry would have to be found to remove it.
func rebuild(lanes: Dictionary) -> void:
	_lanes = lanes

## Whether a car could sit at `at` in this lane's queue with `clearance` of road to itself.
##
## `at` is a `CrowdAgent.queue_position()` — signed so that "ahead" is larger — and the comparison
## is absolute, because a car that would land just *behind* another one is as much inside it as one
## that would land just in front.
func room_at(key: String, at: float, clearance: float) -> bool:
	var queue: PackedFloat32Array = _lanes.get(key, PackedFloat32Array())
	for other in queue:
		if absf(other - at) < clearance:
			return false
	return true

## Records that somebody has taken a place in a lane, between one rebuild and the next.
##
## **Because agents move one at a time and the index is built once a frame**, two cars that enter a
## lane in the same frame both read an index that predates both of them, agree that the road is
## clear, and land on each other — which the separation pass then resolves by teleporting one of them
## backwards, exactly as if neither had looked. It is not a rare case: recycling is what happens to
## every car that leaves the box, and the entry band is one stretch of road that all of them aim at.
##
## Claiming is what closes it, and it wants no bookkeeping: the next rebuild replaces the lot, so a
## claim only has to outlive the frame it was made in.
func claim(key: String, at: float) -> void:
	if not _lanes.has(key):
		_lanes[key] = PackedFloat32Array()
	var queue: PackedFloat32Array = _lanes[key]
	queue.append(at)
	_lanes[key] = queue

## The queue position of the last car in a lane, or `INF` if the lane is empty.
##
## "Last" is smallest, because `CrowdAgent.queue_position()` is signed so that ahead is larger. It is
## the one place in a lane that is free by construction, which is what a car with nowhere else to go
## needs — see `CrowdAgent._recycle`.
func rearmost(key: String) -> float:
	var queue: PackedFloat32Array = _lanes.get(key, PackedFloat32Array())
	var lowest := INF
	for at in queue:
		lowest = minf(lowest, at)
	return lowest

## How many lanes currently have anybody in them. For tests, which otherwise cannot tell an index
## that says "there is room everywhere" from one that was never filled.
func lane_count() -> int:
	return _lanes.size()

## How many cars the index believes are on the road. Also for tests, and for the other half of the
## same question: `claim()` is written to be thrown away once a frame, and with nothing throwing it
## away it grows for as long as the day lasts. See `test_crowd.gd`, "the index is emptied".
func entry_count() -> int:
	var total := 0
	for key: String in _lanes:
		total += (_lanes[key] as PackedFloat32Array).size()
	return total
