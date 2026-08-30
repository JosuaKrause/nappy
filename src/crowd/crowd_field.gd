class_name CrowdField
extends RefCounted
## The patch of city the crowd is actually simulated in: a box that travels with the player.
##
## Playtest 04, and the one instruction in it that was emphasised: *"don't load everything
## upfront — only load / spawn things in the surrounding few blocks of the player when needed;
## consistency is not that important, nobody can run after cars anyway to confirm they are
## still there off screen."*
##
## That last clause is the licence for everything here. A city-wide crowd spends its population
## on pavement nobody is looking at, and the density that reaches the player is whatever is left
## over — which is how 110 cars became *"I can just ignore it and cross the street whenever"*.
## The same agents inside a box a twentieth of the area are a street with traffic on it.
##
## What is given up is continuity: the car that just went past behind you is not the car that
## comes back if you turn round. Nothing in the game can observe that, which is why it is the
## cheap half of the trade.
##
## One object rather than a query on `Crowd`, because `CrowdAgent` recycles itself and a test
## steps agents by hand with no `Crowd` ticking. The agents hold this by reference and read a
## centre that something else moves.

## Where the box is centred — the player, once there is one. Moving it re-sizes the box, which
## is the whole of `_grown_for` below.
var centre := Vector2.ZERO:
	set(at):
		centre = at
		radius = _grown_for(at)
## Half-extent of the box. Read by everything that places or recycles an agent; never set from
## outside, because it is a function of where the centre is.
var radius := Tuning.CROWD_FIELD_RADIUS
var map: CityMap

func _init(city_map: CityMap, at := Vector2.ZERO) -> void:
	map = city_map
	centre = at

## Half-extent that keeps the amount of **city** in the box the same wherever she is standing.
##
## *(M46.)* The population is a fixed number per act and the box near the boundary is half wall,
## so the same two hundred people were spread over half the ground: against the west wall the box
## is 53% city and still put 67 walkers on screen — the same count as mid-map, in half the
## streets — and the corridors beside the wall read as 1.6x an ordinary middle one, loud enough
## that on two of five seeds one of them beat the main road.
##
## The fix is a property of the box rather than of the population, which is why it is here and is
## nine lines: everything downstream already reads `radius`, so `contains`, `along_bounds` and
## `corridor_range` all follow, and no agent is ever created, destroyed or made to vanish. Growing
## it is always safe — the floor under `CROWD_FIELD_RADIUS` is that nothing may be seen to appear,
## and that is a floor.
##
## Solved by iteration rather than in closed form. The exact answer is a quadratic whose terms
## depend on which of the four sides are against a wall and which of them clip *while it grows*,
## which is four cases to get wrong; scaling by the square root of the shortfall converges to
## within a pixel in three passes because a bigger box can only add city on the sides that are
## not already against a wall.
func _grown_for(at: Vector2) -> float:
	if not map:
		return Tuning.CROWD_FIELD_RADIUS
	var want := pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0)
	var grown := Tuning.CROWD_FIELD_RADIUS
	for _pass in 3:
		var area := _city_area(at, grown)
		if area <= 0.0 or area >= want:
			break
		grown *= sqrt(want / area)
	return grown

## How much of a box of this size, centred here, is inside the city.
func _city_area(at: Vector2, half: float) -> float:
	var extent := map.world_size()
	var across := minf(extent.x, at.x + half) - maxf(0.0, at.x - half)
	var down := minf(extent.y, at.y + half) - maxf(0.0, at.y - half)
	return maxf(0.0, across) * maxf(0.0, down)

## True while a point is inside the box. `slack` widens it, which is how an agent is allowed a
## little way past the edge before it is recycled — otherwise one that recycles onto the
## boundary can qualify to be recycled again on the next frame.
func contains(at: Vector2, slack := 0.0) -> bool:
	return absf(at.x - centre.x) <= radius + slack \
			and absf(at.y - centre.y) <= radius + slack

## The lowest and highest coordinate the box spans along an axis, clamped to the map. Agents
## enter at one of these and leave at the other.
func along_bounds(vertical: bool) -> Vector2:
	var extent := map.world_size()
	var here: float = centre.y if vertical else centre.x
	var limit: float = extent.y if vertical else extent.x
	return Vector2(maxf(0.0, here - radius), minf(limit, here + radius))

## The corridors of one axis that the box overlaps, as an inclusive index range.
##
## Clamped to the city rather than to the box: near the map edge the box hangs over the
## boundary wall, and a corridor index out there does not exist.
##
## This used to claim the clamp is *why* the crowd thins out in the corner of the map instead of
## bunching against the wall, "because there are simply fewer streets to put anybody on". On its
## own it does the opposite: fewer streets and the same two hundred people is more people per
## street, and M46 measured 1.6x an ordinary corridor beside the wall. What makes the sentence
## true is `_grown_for` — the range still clamps, and the box it clamps is now big enough that
## the streets left in it hold the population at the density they hold it at mid-map.
func corridor_range(vertical: bool) -> Vector2i:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	var last := CrowdLanes.corridor_count(blocks) - 1
	# The cross-axis coordinate is what picks a corridor: a vertical corridor is a range of x.
	var here: float = centre.x if vertical else centre.y
	var lo := floori((here - radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	var hi := floori((here + radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	return Vector2i(clampi(lo, 0, last), clampi(hi, 0, last))
