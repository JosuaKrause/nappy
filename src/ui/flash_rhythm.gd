class_name FlashRhythm
extends RefCounted
## **When the sky over the escape city lights up, and how brightly**: a bright flash with each
## explosion, and between them fainter ones for bombs further away *(minty-lemur #785: each
## explosion with a bright screen flash, matching the flashes in the apartment building; random
## flashes for bombs further away; not so short or quick that they are dangerous for viewers)*.
## A level from 0 to 1 the light of the day is lifted by (`light()`), stepped on the physics tick
## so it freezes behind a pause, and read by `BlastLight`.
##
## **The far flashes keep the building's rhythm**: their waits are `InteriorScene.distant_flash_wait()`,
## the same short-biased curve between a tenth of a second and five seconds, drawn from a stream of
## their own, seeded per walk, so a seed replays the same night, and held to the same gap as the
## building's (`FlashGap`), so a wait shorter than `FlashGap.LEAST_GAP` lasts that long. Light
## without noise, as in the building: no event, no field, nothing on the meter.
##
## **Safe for viewers: never more than three flashes in any one second** (`FlashGap`): no flash
## begins within `FlashGap.LEAST_GAP` of the last one's start, a bang's included, which then lights
## at most that long after its noise and goes before a far flash that is due. And no flash is a
## hard strobe: each rises over `RISE_SECONDS` and dies away eased over `FALL_SECONDS`.

## How far an explosion's flash lifts the light of the night toward the blast's
## (`Palette.ESCAPE_FLASH_LIGHT`), at its brightest. A first number, shown to the player before it
## ships.
const NEAR_PEAK := 0.6
## How far a far bomb's flash lifts it: a third of a near one's.
const DISTANT_PEAK := 0.2
## Seconds a flash takes to reach its brightest.
const RISE_SECONDS := 0.05
## Seconds a flash takes to die away from its brightest, eased.
const FALL_SECONDS := 0.4
## Seconds since the night began: every flash's start is stated on it.
var _clock := 0.0
## The gap no flash begins inside of after the last.
var _gap := FlashGap.new()
## The flashes still lit: each one's start on `_clock` (`x`) and its brightest (`y`).
var _lit: Array[Vector2] = []
## A bang's flash waiting for the gap after the last one.
var _bang_waiting := false
## The far flashes: their stream, whether they run, and the seconds until the next is due.
var _far := RandomNumberGenerator.new()
var _night_running := false
var _until_the_next_far := 0.0

## **Starts the far flashes**, their waits drawn from `seed`: on every start of the escape city's
## walk, fresh or retried, so a retry is the same night again.
func start_the_night(seed: int) -> void:
	_far.seed = seed
	_until_the_next_far = InteriorScene.distant_flash_wait(_far.randf())
	_night_running = true

## Stops the far flashes; a bang still lights the sky.
func stop_the_night() -> void:
	_night_running = false

## **An explosion went off**: its flash begins now, or as soon as the gap after the last allows.
func flash_for_a_bang() -> void:
	if _may_begin():
		_begin(NEAR_PEAK)
	else:
		_bang_waiting = true

## Lets `delta` seconds pass: a waiting bang's flash, then a far one that is due, begins once the
## gap allows, and a flash that has died away is let go.
func step(delta: float) -> void:
	_clock += delta
	_gap.step(delta)
	if _night_running:
		_until_the_next_far -= delta
	if _bang_waiting and _may_begin():
		_bang_waiting = false
		_begin(NEAR_PEAK)
	if _night_running and _until_the_next_far <= 0.0 and not _bang_waiting and _may_begin():
		_until_the_next_far = InteriorScene.distant_flash_wait(_far.randf())
		_begin(DISTANT_PEAK)
	var lasting: Array[Vector2] = []
	for flash in _lit:
		if _clock - flash.x < RISE_SECONDS + FALL_SECONDS:
			lasting.append(flash)
	_lit = lasting

## **How lit the sky is now**, 0 to 1: the brightest of the flashes still lit, each risen over
## `RISE_SECONDS` and eased away over `FALL_SECONDS`.
func light() -> float:
	var level := 0.0
	for flash in _lit:
		level = maxf(level, flash.y * _shape(_clock - flash.x))
	return level

## Whether a flash may begin now: the gap since the last one's start has run.
func _may_begin() -> bool:
	return _gap.may_begin()

func _begin(peak: float) -> void:
	_gap.begin()
	_lit.append(Vector2(_clock, peak))

## A flash's brightness `age` seconds after it began, as a share of its brightest.
static func _shape(age: float) -> float:
	if age < 0.0:
		return 0.0
	if age < RISE_SECONDS:
		return smoothstep(0.0, RISE_SECONDS, age)
	var left := 1.0 - clampf((age - RISE_SECONDS) / FALL_SECONDS, 0.0, 1.0)
	return left * left
