class_name ReleaseLatch
extends RefCounted
## One "she has just come through this, leave her alone until she has actually left" flag.
##
## A door that puts her down on the other side of itself puts her down **inside its own trigger**,
## because the far side of a thing you cannot walk through is a body's width away and the trigger
## reaches further than that. Without something like this the only cure is distance — setting her
## down far enough out that the trigger cannot reach — and distance is the wrong cure twice over:
## it teleports her further than the door is wide, and it still fails the moment anything nudges
## her back. *(2026-09-12, the player: "she just spawns further away now? it should work that she
## has a flag 'just spawned' that only resets once she leaves the area. that way she can't
## accidentally go back and we don't need to place her far away".)*
##
## So the latch is armed on the way out with the **same circle the trigger uses**, and it holds
## until she is measured outside it. Standing exactly where she was released, for as long as she
## likes, she is not taken in again; walking out of the circle clears it, and walking back in costs
## her the toll exactly as it did the first time. *"It works in both directions with the same cost
## each time"* survives, because leaving is what re-arms the door rather than time or distance.
##
## Not a field on the thing that released her: the escape scene's own doors need the identical rule
## *(2026-09-12: "same mechanism can be reused in the escape scene when going through doors")*, and
## a rule copied into two places is a rule that will disagree with itself. Whoever owns the doors
## keeps one of these per door she came out of, arms it with that door's own trigger radius, and
## asks `holds()` before it will take her again.

## Where she was let out and how far from it the door can still reach. Only meaningful while
## `_holding`.
var _center := Vector2.ZERO
var _radius := 0.0
var _holding := false

## Starts holding: she has just been put down at `center`, inside a trigger of `radius`, and this
## must not count as her walking into it. Re-arming an already-armed latch is the ordinary case —
## she can be let out of the same door twice — and replaces the old circle outright.
func arm(center: Vector2, radius: float) -> void:
	_center = center
	_radius = maxf(0.0, radius)
	_holding = true

## Tells the latch where she is now. **This is the only thing that can clear it**, and it clears on
## the first position outside the circle: there is no timer, so standing still holds it for ever and
## one step out of the door's reach ends it. Cheap enough to call every frame, which is what it is
## for — a latch only updated when somebody remembers is a latch that holds too long.
func update(position: Vector2) -> void:
	if not _holding:
		return
	if position.distance_to(_center) > _radius:
		_holding = false

## Whether she is still standing in what she was just let out of. Once false it stays false until
## somebody calls `arm()` again — a latch that could re-hold on its own would be a door that closes
## behind her.
func holds() -> bool:
	return _holding
