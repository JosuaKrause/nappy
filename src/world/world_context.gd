class_name WorldContext
extends Node2D
## What the baby is allowed to ask about the world.
##
## `Baby` must never know what an event or a tile type is — it only asks "how loud is it
## here, and what is this ground doing to me". The debug world answers with hand-placed
## test data; M3's generated city and M4's event manager answer for real. Adding an event
## type therefore never touches the meter code.
##
## It was three questions until M41 and is four. The new one is the *general* form of the half of
## `is_calm_zone` that was about recovery: the ground is no longer calm-or-not, it is a rate, and
## the order is calm, precinct, ordinary street, main road.
##
## **M52 did the same thing to the other half, which is why there is still no fifth question.**
## *(Playtest 14, finding 11: "x1.5 the sleepiness effect of calm zones and double it for 1x1 calm
## zones.")* `is_calm_zone` was a bool because calm ground was one kind of place; a single-block
## calm area now fills the meter twice as fast as a four-block one, so it is a rate as well. The
## rule this is an instance of is worth keeping: **the new question generalises an old answer
## instead of sitting beside it.** A fifth question that is a special case of one of these four is
## exactly what that rule exists to stop.
##
## `City` still has an `is_calm_zone` of its own, for the debug overlay and the telemetry, which
## genuinely do want the yes/no. It is not on this interface because `Baby` has no use for it.

func _ready() -> void:
	add_to_group("world")

## What this ground multiplies the sleepiness gain by while she walks. 1.0 is anywhere that is not
## calm; calm ground is worth many times that, and a small calm area more again.
func sleepiness_multiplier(_world_position: Vector2) -> float:
	return 1.0

## What this ground multiplies the excitement decay by. 1.0 is an ordinary street.
##
## Asked every frame, so the world answers from the tile she is standing on rather than from
## anything it has to search for.
func decay_multiplier(_world_position: Vector2) -> float:
	return 1.0

## Alleys apply a constant excitement trickle. Shortcuts that cost you.
func is_alley(_world_position: Vector2) -> bool:
	return false

## Summed excitement per second from every active source at this point.
func total_excitement_at(_world_position: Vector2) -> float:
	return 0.0
