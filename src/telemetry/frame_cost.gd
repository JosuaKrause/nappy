class_name FrameCost
extends RefCounted
## What one frame cost the renderer and the two loops, read from Godot's own `Performance`
## monitors in **one** place so the developer readout and the run log can never disagree about it.
##
## The question it exists for is *where does a frame go on a device that is not this one*.
## A frame rate alone cannot answer it: 40fps with three hundred draw calls and 40fps with four
## thousand are different problems with different fixes, and neither is visible from the number
## the readout used to carry on its own. So every reading here is a **cost**, not a rate —
## `draw_calls()`, `objects()` and `primitives()` say how much work was handed to the renderer,
## and `process_ms()` and `physics_ms()` say how much of the frame never reached it at all.
##
## **Nothing here reads the world.** Every number comes off `Performance`, which the engine
## maintains whether or not anybody asks, so this can be called from the run log without the
## telemetry's one invariant — *it must not touch gameplay* — coming anywhere near it.
##
## **The render counters read zero under `--headless`**, because a null display server draws no
## frame to count. That is why `tests/test_performance.gd` asserts the *shape* of what is written
## rather than any value in it, and why a measurement of this milestone's suspects has to be a
## windowed `tools/shot.sh` run rather than a headless one.

## The one sentence the run log carries, and the labels the readout below repeats. Both name the
## same six quantities in the same words, so a number read off a phone's `run.log` and the same
## number read off a desktop's readout are obviously the same number.
##
## `worst_frame_seconds` is the longest frame the caller saw across its own reporting interval,
## passed in rather than read here because this class holds no clock. **It is the field the
## complaint is actually about**: "a bit laggy" is a hitch, and a mean or a single sampled frame
## is exactly the statistic a hitch hides in.
static func line(worst_frame_seconds: float) -> String:
	return "fps %d, worst frame %.1fms, draws %d, objects %d, primitives %d, process %.2fms, physics %.2fms" % [
		fps(), worst_frame_seconds * 1000.0, draw_calls(), objects(), primitives(),
		process_ms(), physics_ms(),
	]

## The same six quantities as the block of fixed-width lines `main.gd` splices into the developer
## readout. A function here rather than six format strings there, because the pair only stays
## honest while both are assembled from the same readings — see `tests/test_performance.gd`,
## which holds exactly that: every quantity the readout names is named by `line()` too. `process`
## and `physics` also carry `mean` and `max` over the last second (`sample()`'s own window),
## labelled rather than left to column order — the run log's own `line()` stays last-frame-only,
## since it already writes once a second and a mean over that same second would be no different a
## number.
static func readout_lines() -> Array[String]:
	var process_last := process_ms()
	var physics_last := physics_ms()
	return [
		"fps         %6d" % fps(),
		"draws       %6d" % draw_calls(),
		"objects     %6d" % objects(),
		"primitives  %6d" % primitives(),
		"process     last %6.2f  mean %6.2f  max %6.2f ms" % [
			process_last, process_mean_ms(), process_max_ms()],
		"physics     last %6.2f  mean %6.2f  max %6.2f ms" % [
			physics_last, physics_mean_ms(), physics_max_ms()],
	]

static func fps() -> int:
	return Engine.get_frames_per_second()

## Draw calls issued for the frame. The number an atlas would move: the renderer only batches
## consecutive draws that share a texture, so a sprite drawn from its own texture is a call of
## its own and a few hundred entities are a few hundred calls.
static func draw_calls() -> int:
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

## Renderable items submitted for the frame — every `CanvasItem` with something in its draw list.
static func objects() -> int:
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))

## Primitives (triangles, lines) submitted for the frame. It is what separates *many small
## sprites* from *a few big fills*: a rect is two triangles whatever it covers, so a frame heavy
## in primitives and light in pixels is a geometry problem and the reverse is a fill-rate one —
## the second being the cost a desktop measurement cannot see on a phone's own screen.
static func primitives() -> int:
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

## Milliseconds the last frame spent in `_process` callbacks. Godot reports it in seconds.
static func process_ms() -> float:
	return Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

## Milliseconds the last frame spent in `_physics_process` callbacks, in seconds from the engine
## the same way. Held apart from `process_ms()` rather than summed, because the two are fixed by
## different things: physics runs at its own tick rate and is the crowd's and the traffic's, while
## process is the drawing decisions and everything hung off them.
static func physics_ms() -> float:
	return Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0

# ------------------------------------------------------------------ the last second's window ---

## How far back `sample()`'s window reaches — one second, the interval a hitch is felt over and
## the interval the run log's own `frame` entry already reports at.
const SAMPLE_WINDOW_SECONDS := 1.0

## Timestamps, in the caller's own clock, for the readings below — oldest first. Fed only by
## `sample()`, so the three arrays only ever move together.
static var _sample_times: Array[float] = []
static var _process_samples: Array[float] = []
static var _physics_samples: Array[float] = []

## Feeds this frame's `process_ms()`/`physics_ms()` into the rolling window `process_mean_ms()`,
## `process_max_ms()`, `physics_mean_ms()` and `physics_max_ms()` read from, and drops anything
## more than `SAMPLE_WINDOW_SECONDS` behind `now_seconds`. Takes the time from the caller rather
## than reading a clock here, the way `line()` takes `worst_frame_seconds` — so a test can drive
## the window with known times instead of a real one. `main.gd` calls this once a frame while the
## readout is on and nothing else does, since the window is a readout cost, not a gameplay one:
## nothing here is random and nothing here reads the day, so it does not go near the telemetry
## invariant that governs this file's neighbours.
static func sample(now_seconds: float) -> void:
	_sample_times.append(now_seconds)
	_process_samples.append(process_ms())
	_physics_samples.append(physics_ms())
	var cutoff := now_seconds - SAMPLE_WINDOW_SECONDS
	while not _sample_times.is_empty() and _sample_times[0] < cutoff:
		_sample_times.pop_front()
		_process_samples.pop_front()
		_physics_samples.pop_front()

## Clears the window. A real run never needs this — the window ages itself out one second at a
## time — but `tests/test_performance.gd` shares this static state with every other suite in the
## one process a run drives them all in, and calls this first so an earlier suite's real-clock
## samples (`tests/test_main.gd` drives `main._process()`, which calls `sample()` too) cannot leak
## into a test that hands the window its own arithmetic.
static func reset_samples() -> void:
	_sample_times.clear()
	_process_samples.clear()
	_physics_samples.clear()

## The mean of the last second of `process_ms()` readings `sample()` was fed — what a still
## actually measures, since a screenshot lands on one arbitrary frame and the mean is what that
## frame is one sample of (see `docs/DECISIONS.md`, M124, "the phone's process time split": two
## stills of one setting read 21.7ms and 65.1ms). Falls back to the instantaneous `process_ms()`
## reading while the window is empty — nothing has called `sample()` yet — so the very first frame
## reports what it has rather than a zero that would read as free.
static func process_mean_ms() -> float:
	return _window_mean(_process_samples, process_ms())

## The worst single frame in the last second `sample()` was fed — what a stutter feels like, since
## a mean is exactly the statistic a hitch hides in, the same argument `line()`'s own
## `worst_frame_seconds` makes for the run log. Same empty-window fallback as `process_mean_ms()`.
static func process_max_ms() -> float:
	return _window_max(_process_samples, process_ms())

## See `process_mean_ms()`.
static func physics_mean_ms() -> float:
	return _window_mean(_physics_samples, physics_ms())

## See `process_max_ms()`.
static func physics_max_ms() -> float:
	return _window_max(_physics_samples, physics_ms())

static func _window_mean(samples: Array[float], fallback: float) -> float:
	if samples.is_empty():
		return fallback
	var total := 0.0
	for value in samples:
		total += value
	return total / samples.size()

static func _window_max(samples: Array[float], fallback: float) -> float:
	if samples.is_empty():
		return fallback
	var worst := samples[0]
	for value in samples:
		worst = maxf(worst, value)
	return worst
