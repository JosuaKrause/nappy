class_name CarStrike
extends RefCounted
## Where a driving car kills: the box in front of it, from its centre forward.
##
## The rectangle is `Tuning.CAR_STRIKE_HALF_LENGTH` long and `CAR_STRIKE_HALF_WIDTH` either side of
## its axis. Behind the car's centre the car is driving away from her, and a car slower than
## `CAR_STRIKE_MIN_SPEED` kills nobody, so the answer is a pure function of the car's centre, its
## heading and its speed, and of where she stands. `Crowd._strike()` asks it for the collision and
## the day's end; it is a static function so the box can be asked about without a car on the street.

## Whether a car at `centre`, pointing along `heading` at `speed`, strikes somebody standing at `here`.
static func hits(centre: Vector2, heading: Vector2, speed: float, here: Vector2) -> bool:
	if speed < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var offset := here - centre
	# Only from the car's centre forward: behind it the car is driving away from her.
	var along := offset.dot(heading)
	if along < 0.0 or along > Tuning.CAR_STRIKE_HALF_LENGTH:
		return false
	return absf(offset.dot(Vector2(-heading.y, heading.x))) <= Tuning.CAR_STRIKE_HALF_WIDTH
