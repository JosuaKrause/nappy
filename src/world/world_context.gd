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
## the order is calm, precinct, ordinary street, main road. `is_calm_zone` stays because the
## sleepiness half is genuinely a threshold — only calm ground puts a baby to sleep.

func _ready() -> void:
	add_to_group("world")

## Parks and quiet squares: sleepiness fills faster, excitement fades faster.
func is_calm_zone(_world_position: Vector2) -> bool:
	return false

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
