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

## Where the box is centred — the player, once there is one.
var centre := Vector2.ZERO
var radius := Tuning.CROWD_FIELD_RADIUS
var map: CityMap

func _init(city_map: CityMap, at := Vector2.ZERO) -> void:
	map = city_map
	centre = at

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
## boundary wall, and a corridor index out there does not exist. That is also why the crowd
## thins out honestly in the corner of the map instead of bunching against the wall — there
## are simply fewer streets to put anybody on.
func corridor_range(vertical: bool) -> Vector2i:
	var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
	var last := CrowdLanes.corridor_count(blocks) - 1
	# The cross-axis coordinate is what picks a corridor: a vertical corridor is a range of x.
	var here: float = centre.x if vertical else centre.y
	var lo := floori((here - radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	var hi := floori((here + radius) / float(CityMap.period() * Tuning.TILE_SIZE))
	return Vector2i(clampi(lo, 0, last), clampi(hi, 0, last))
