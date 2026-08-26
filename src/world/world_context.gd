class_name WorldContext
extends Node2D
## What the baby is allowed to ask about the world.
##
## `Baby` must never know what an event or a tile type is — it only asks "how loud is it
## here, and is this ground calming or unnerving". The debug world answers with hand-placed
## test data; M3's generated city and M4's event manager answer for real. Adding an event
## type therefore never touches the meter code.

func _ready() -> void:
	add_to_group("world")

## Parks and quiet squares: sleepiness fills faster, excitement fades faster.
func is_calm_zone(_world_position: Vector2) -> bool:
	return false

## Alleys apply a constant excitement trickle. Shortcuts that cost you.
func is_alley(_world_position: Vector2) -> bool:
	return false

## Summed excitement per second from every active source at this point.
func total_excitement_at(_world_position: Vector2) -> float:
	return 0.0
