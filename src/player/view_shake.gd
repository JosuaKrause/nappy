class_name ViewShake
extends RefCounted
## **A small, eased shake of her view**, for an explosion close enough to be felt *(minty-lemur
## #785: for the close-by explosion, the screen shakes a little)*: the camera's offset swings round
## where it would be, two slow sines at different rates so it reads as a jolt rather than a
## buzz, and dies away eased over `SECONDS`. It moves the world under the camera only: the HUD, the
## screen-edge badges and the touch controls are drawn on their own layers and stay where they are,
## and at `MOST_PX` nothing she has to see goes out of view.
##
## The game has no reduced-motion setting, so nothing here asks one. Held by `Stroller`, which adds
## `step()`'s offset to the look-ahead every physics tick (`Stroller.shake_the_view()`).

## The widest the view swings, in world px, for an explosion at full strength where she stands: two
## screen pixels at zoom 2 for every one here. A first number, shown to the player before it ships.
const MOST_PX := 3.0
## How long a shake lasts, in seconds, from its jolt to still.
const SECONDS := 0.45
## The two rates the view swings at, in swings per second, across and down.
const ACROSS_HZ := 7.0
const DOWN_HZ := 5.5

## Seconds since the shake began, `SECONDS` or more once it is still.
var _age := SECONDS
## How wide this shake starts, in px.
var _size := 0.0

## **Shakes the view for an explosion landing `share` of its full strength on her** (0 to 1): a
## share of `MOST_PX`. A weaker shake than the one under way does not cut it short.
func start(share: float) -> void:
	var size := MOST_PX * clampf(share, 0.0, 1.0)
	if size <= 0.0:
		return
	if _age < SECONDS and size <= _size_now():
		return
	_size = size
	_age = 0.0

## Lets `delta` seconds pass and answers the offset the view has now, zero once it is still.
func step(delta: float) -> Vector2:
	_age += delta
	if _age >= SECONDS:
		return Vector2.ZERO
	var size := _size_now()
	return Vector2(sin(TAU * ACROSS_HZ * _age), sin(TAU * DOWN_HZ * _age + 1.3)) * size

## How wide the shake is now: its start, eased out to nothing over `SECONDS`.
func _size_now() -> float:
	var left := 1.0 - clampf(_age / SECONDS, 0.0, 1.0)
	return _size * left * left
