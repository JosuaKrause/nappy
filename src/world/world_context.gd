class_name WorldContext
extends Node2D
## What the baby is allowed to ask about the world.
##
## `Baby` must never know what an event or a tile type is — it only asks "how loud is it
## here, and what is this ground doing to me". The debug world answers with hand-placed test data;
## the generated city and the event manager answer for real. Adding an event type therefore never
## touches the meter code.
##
## **Four questions, and neither of the ground ones is a bool.** Recovery is a rate — calm,
## precinct, ordinary street, main road — and so is how fast the sleepiness fills, because a
## single-block calm area fills the meter twice as fast as a four-block one. The rule that keeps
## this interface at four is worth stating: **a new question generalises an old answer instead of
## sitting beside it.** A fifth that is a special case of one of these four is exactly what that
## rule exists to stop.
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
