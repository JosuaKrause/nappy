class_name GapToHer
extends RefCounted
## How far apart a vehicle's body is from her and from her pram, measured here and not asked of the
## vehicle: off the body's own outline (`GroundShape`) at its place and heading against her rig's
## circle and her pram's, so the answer holds whatever the vehicle's own driving believes.

## The smaller of the two gaps, negative where they overlap.
static func between(vehicle: EventInstance, player: Stroller) -> float:
	var pram := player.global_position + player.facing_direction() * Tuning.PLAYER_BODY_RADIUS
	return minf(_to(vehicle, player.global_position, Tuning.PLAYER_BODY_RADIUS),
			_to(vehicle, pram, Stroller.PRAM_BODY_RADIUS))

## The gap between the vehicle's body and a circle of `radius` about `centre`.
static func _to(vehicle: EventInstance, centre: Vector2, radius: float) -> float:
	var shape := vehicle.ground_shape()
	var local := (centre - vehicle.global_position).rotated(-vehicle.facing_now().angle())
	return shape.distance_to_spine(local) - shape.rounding_radius() - radius
