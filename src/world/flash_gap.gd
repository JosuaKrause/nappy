class_name FlashGap
extends RefCounted
## **No flash of the night outside starts within `LEAST_GAP` of the one before**, wherever it lights:
## the building's hallway windows (`InteriorScene`) and the escape city's sky (`FlashRhythm`)
## alike *(minty-lemur #785: flashes not so short or quick that they are dangerous for viewers)*.
## The usual guidance for photosensitive viewers is at most three flashes in any second, and with
## three gaps of `LEAST_GAP` longer than a second no second can hold a fourth. A flash asked for
## sooner waits for the gap; its owner says which waits first.
##
## Counted on the clock its owner steps (`step()`), the physics tick, so it freezes behind a pause
## with the flashes it spaces.

## The least time between two flashes' starts, in seconds: over a third of a second, so no second
## ever holds more than three.
const LEAST_GAP := 0.4

## Seconds since its owner began counting: every start is stated on it.
var _clock := 0.0
## When the last flash began, on `_clock`.
var _last_start := -INF

## Lets `delta` seconds pass.
func step(delta: float) -> void:
	_clock += delta

## Whether a flash may begin now: the gap since the last one's start has run.
func may_begin() -> bool:
	return _clock - _last_start >= LEAST_GAP

## A flash begins now: the next waits for the gap from here.
func begin() -> void:
	_last_start = _clock
