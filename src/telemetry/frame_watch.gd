class_name FrameWatch
extends RefCounted
## What the frames are costing, once a second — the one entry that is about the **device** rather
## than about the day, and the only way a session played on a phone or on the web page can be read
## back afterwards at all. *(2026-09-13: "I played a few sessions on mobile. It is a bit laggy
## now.")* A frame rate on its own cannot say where the frame went; `FrameCost` carries the draw
## calls, the renderable objects, the primitives and the two loop times beside it, and those are
## what separate *too many texture switches* from *too much work before the renderer is reached*.
##
## `TelemetryObserver` holds one, hands it each frame's length (`watch()`) and starts it over with
## a day (`restart()`); it writes through the `note` it is handed, the run log's in the game.
##
## **Timed off the frame's length rather than off `Telemetry.clock()`**, unlike the observer's
## corridor time, and the reason is a flag: `--invincible` stands the day clock still on purpose, so
## an interval measured against it would emit one line and then never advance — on exactly the runs
## a capture is most likely to be taken from. The cost is that every line of such a run carries the
## same timestamp, which is already true of every other entry there.
##
## **The worst frame in the interval is on the line, not an average of them.** "A bit laggy" is a
## hitch, and a mean is the statistic a hitch hides in; one `maxf` a frame is what makes the
## complaint measurable rather than a matter of opinion.

## How often the log says what a frame is costing. One second, because the question it answers —
## *is the game laggy on this device, and where is the frame going* — is about a stretch of play
## rather than a moment, and a line per frame would be a metrics dump wearing a log's clothes.
## A three-minute day is about a hundred and eighty lines, which a reader can scan down the same
## way they scan `near`.
const REPORT_INTERVAL := 1.0

var _sink: Callable

# Time since the last `frame` entry and the longest single frame seen since it, in frame seconds.
var _since := 0.0
var _worst := 0.0

# This second's running mean, kept the same way `_worst` is: the sum and count of every frame's
# length since the last report, so `_sum / _count` is the mean of the frames already seen this
# second, and the worst candidate found so far — its own length, the mean it beat, and what the
# game did in it. Only touched under `--spikes`; see `_watch_for_a_spike`.
var _sum := 0.0
var _count := 0
var _spike_delta := 0.0
var _spike_mean := 0.0
var _spike_what := ""

# The previous frame's tile and live event count, so a spike's own context can say what changed
# *that* frame rather than merely what the world looked like. Updated every frame under
# `--spikes`, spike or not.
var _spike_tile := Vector2i.ZERO
var _spike_events := 0

## `note` is called with a kind and a sentence for each line written.
func _init(note: Callable) -> void:
	_sink = note

## One line to the run log, under `kind`.
func _note(kind: String, text: String) -> void:
	_sink.call(kind, text)

## One frame `delta` seconds long. `spikes` is whether `--spikes` was given; only then is `scene`
## called, for her tile and the live event count this frame (`[Vector2i, int]`), so with the flag off
## this costs one boolean check beyond the frame line's own arithmetic.
func watch(delta: float, spikes: bool, scene: Callable) -> void:
	_worst = maxf(_worst, delta)
	if spikes:
		var seen: Array = scene.call()
		_watch_for_a_spike(delta, seen[0], seen[1])
	_since += delta
	if _since < REPORT_INTERVAL:
		return
	if _spike_delta > 0.0:
		_note("spike", "%.1fms, mean %.1fms — %s" % [
			_spike_delta * 1000.0, _spike_mean * 1000.0, _spike_what])
	_note("frame", FrameCost.line(_worst))
	_since = 0.0
	_worst = 0.0
	_reset_the_spike_window()

## Everything above, put back for a new day — a rewound one too.
func restart() -> void:
	_since = 0.0
	_worst = 0.0
	_reset_the_spike_window()
	_spike_tile = Vector2i.ZERO
	_spike_events = 0

## The probe behind `--spikes`: which frame in this second, if any, ran past twice the mean of
## the frames already seen this second, and what the game did in it. *(2026-09-14, on a desktop
## build reading 85 to 112 fps with `physics` under 2ms: "local laptop also stutters even though
## fps is way above 60" — a 16 to 24ms frame most seconds, two to three times its neighbours,
## with nothing saying when it falls or what ran in it.)*
##
## **Reuses the frame line's own interval rather than a trailing window of its own** — the mean is
## of every frame since the last report and starts again every `REPORT_INTERVAL`, never a rolling
## second, because the question is "which frame in *this* second was the outlier" rather than
## "what does this instant look like against the second before it", and the report already marks
## where one second ends and the next begins.
##
## **The mean is of the frames seen *before* this one**, not including it — comparing a frame
## against a mean it has already dragged upward would shrink its own ratio, and a single 100ms
## frame in a second of 16ms ones would then have to clear a mean of its own making rather than
## the ordinary one. The first frame of a fresh interval is never a candidate: there is nothing
## yet to call it twice the size of.
##
## **Only the worst candidate survives** — `delta > _spike_delta` beside the threshold check —
## so a second with two qualifying frames writes the rate limit's one line about the worse of
## the two, never the more recent.
func _watch_for_a_spike(delta: float, tile: Vector2i, events: int) -> void:
	if _count > 0:
		var mean: float = _sum / _count
		if delta > 2.0 * mean and delta > _spike_delta:
			_spike_delta = delta
			_spike_mean = mean
			_spike_what = _spike_context(tile, events)
	_sum += delta
	_count += 1
	_spike_tile = tile
	_spike_events = events

## What changed since the previous frame. `"nothing else changed that frame"` is itself an answer:
## it says the spike was not the game doing extra work, which is the other half of the question the
## probe exists to ask.
##
## **A picture arriving late is not one of the answers, because a page cannot arrive late.** Every
## page a day draws is held from the boot's own loading window, and a page read from disk outside
## one writes its own `texture` line naming the group, the moment and the milliseconds and raises
## an engine error the test gate is red for — a louder report than a count in a spike line.
func _spike_context(tile: Vector2i, events: int) -> String:
	var changes: Array[String] = []
	if tile != _spike_tile:
		changes.append("her tile changed to %s" % RunTrace.tile(tile))
	if events != _spike_events:
		changes.append("live events %d -> %d" % [_spike_events, events])
	return ", ".join(changes) if not changes.is_empty() else "nothing else changed that frame"

## The per-second spike-candidate bookkeeping, cleared alongside `_since` and `_worst` every time a
## `frame` line closes the interval, and by `restart()`.
func _reset_the_spike_window() -> void:
	_sum = 0.0
	_count = 0
	_spike_delta = 0.0
	_spike_mean = 0.0
	_spike_what = ""
