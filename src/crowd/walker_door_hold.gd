class_name WalkerDoorHold
extends RefCounted
## One checkpoint hut, as the crowd sees it: where it stands, who is inside it, and who is queued
## for it.
##
## A region door stands a hut on each sidewalk and a boom over the road (`RegionPlanner.RegionPlan.
## door_bodies`), and an alley door a single guard at each mouth. The boom is the cars' —
## `Crowd._stop_for_gates()` raises and lowers it — and this is the sidewalk's own equivalent: the
## shared state a queue of walkers needs, which is exactly *one body may be inside at a time* and
## *these are the people waiting*.
##
## **Held on the hut's own ground point and on nothing else.** Not on the `checkpoint_hut` row's
## `detain_radius` (48px, the reach at which the *player* is detained) and not on `EventInstance`'s
## detention, which teleports her, hides her, eases the camera onto the door and charges her meter.
## A walker is not the one being looked for; what it shares with her is the shape of the wait, not
## the machinery of it.
##
## `Crowd` builds one of these per detaining door body every morning and hands them to the walkers
## by geometry; a walker keeps a reference to the one it has committed to. There is no reverse
## lookup and nothing here knows what a `CrowdAgent` is beyond identity, which is what keeps the two
## scripts from referring to each other in a circle.

## The hut's own ground point, in world space — the same position its `checkpoint_hut` (or
## `checkpoint_post`) instance stands at, and what `Crowd` measures a walker's distance from.
var position := Vector2.ZERO

## The walker inside the hut right now, or `null`. One at a time, so the queue behind it is the
## whole of what a door's line ever is.
var inside: Node2D = null

## The walkers that have committed to this hut and have not been let in yet, in the order they
## committed — which is the order they stand in, since each is given a stopping place one spacing
## further back than the one in front. A walker joins at the moment its own lookahead first sees
## the door, seven tiles off, rather than on arrival: a queue that is only counted at the hut is a
## queue nobody could have decided against in time.
var queue: Array[Node2D] = []

## Puts a walker at the back of the line, if it is not already in it or inside.
func join(walker: Node2D) -> void:
	if walker == inside or queue.has(walker):
		return
	queue.append(walker)

## Where in the line a walker stands, or -1 for somebody who is not in it.
func place_of(walker: Node2D) -> int:
	return queue.find(walker)

## Lets the walker at the front in, and says whether it went. Refused while somebody is inside and
## refused to anybody who is not at the front, which is the two halves of *one at a time, in order*
## in the one place both are decided.
func admit(walker: Node2D) -> bool:
	if inside != null or queue.is_empty() or queue[0] != walker:
		return false
	queue.remove_at(0)
	inside = walker
	return true

## Lets go of a walker, wherever it stood. **Called for every way a walker can stop existing where
## it was** — coming out of the hut, recycling at the edge of the crowd's field, being streamed out
## — because a hut left occupied by somebody who is no longer there never takes anybody again, and
## nothing about a walker walking away from a door would say so.
func release(walker: Node2D) -> void:
	if inside == walker:
		inside = null
	var at := queue.find(walker)
	if at >= 0:
		queue.remove_at(at)

## How many are waiting behind whoever is inside.
func waiting() -> int:
	return queue.size()

## Lets go of everybody at once — what `Crowd.clear()` does when a day's whole crowd stops
## existing. Without it a hut holds references to freed nodes, which are not `null` and are not
## valid either, and the first thing that asks whether somebody is inside gets the worst of both.
func empty() -> void:
	inside = null
	queue.clear()
