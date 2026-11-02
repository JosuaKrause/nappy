class_name TelemetryShots
extends RefCounted
## What the run log's pictures are allowed and what they are called: the day's allowance, the
## spacing between two automatic ones, and the one counter that names every picture of a run.
## `Telemetry` owns one and asks it before it photographs; the screen it photographs is the part a
## headless process has none of, so the allowance and the names are checked here on their own.

## The most shots one day may produce, and the least time between two of them.
##
## Six is about one per losing attempt plus the moment before it. The spacing is longer than any cue
## in the game holds for, so a condition that is true for two seconds is one picture rather than a
## hundred and twenty.
const PER_DAY := 6
const SPACING := 3.0

var _taken_today := 0
var _last_at := -INF

## Counts from 1 for the life of the run, reset only by `restart_names()`: neither a new day nor a
## retried attempt resets it, since a number that reset could repeat, which is the exact failure a
## clock-based name already had.
var _serial := 0

## Whether an automatic shot may be taken at `clock` (seconds on the open section's clock): the
## day's allowance is not spent and `SPACING` has passed since the last automatic one.
func allows(clock: float) -> bool:
	return _taken_today < PER_DAY and clock - _last_at >= SPACING

## Counts one automatic shot taken at `clock` against the day's allowance and starts the spacing.
func take(clock: float) -> void:
	_taken_today += 1
	_last_at = clock

## Counts a shot a person asked for. It bypasses the allowance and the spacing, and still counts.
func take_asked() -> void:
	_taken_today += 1

## A fresh day's, or a retried section's, clean slate: the allowance whole and no shot just taken.
func restart_schedule() -> void:
	_taken_today = 0
	_last_at = -INF

## The next number of the run starts over at 1 — a new run's names, not a new day's.
func restart_names() -> void:
	_serial = 0

## Names a picture by the run's counter, not by any clock. *(2026-09-11, playtest 56: "phot
## capture must use real time not game time otherwise at the end of the day all pictures get
## overwritten", then, once a real-time name was in place, "actually why not just count up the
## screenshot numbers?".)* `%03d<attempt suffix>-<kind>.png` — `001-attempt1-asked.png`,
## `002-attempt1-asked.png` — one counter across the automatic and the asked-for pictures, so a
## picture's own number already says when in the run, relative to every other picture, it was
## taken; the attempt suffix and kind say what a retried day or a heuristic-vs-asked picture still
## needs to say without opening the file.
func next_name(kind: String, attempt_suffix: String) -> String:
	_serial += 1
	return "%03d%s-%s.png" % [_serial, attempt_suffix, kind]
