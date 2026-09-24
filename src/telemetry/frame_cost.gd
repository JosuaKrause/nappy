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
## and `physics` are labelled `worst` rather than left as a bare number: `process_ms()` and
## `physics_ms()` are already the worst interval of the previous second, not a per-frame cost
## (`docs/DECISIONS.md`, M138, what the readout's `process` and `physics` lines measure), and a
## bare number reads as a per-frame mean — the misreading every phone report made before M143. The
## run log's own `line()` carries the same reading with no label, since it already writes once a
## second, at the interval the reading covers.
static func readout_lines() -> Array[String]:
	return [
		"fps         %6d" % fps(),
		"draws       %6d" % draw_calls(),
		"objects     %6d" % objects(),
		"primitives  %6d" % primitives(),
		"process     worst %5.1f ms" % process_ms(),
		"physics     worst %5.1f ms" % physics_ms(),
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

## Milliseconds — off `Performance.TIME_PROCESS`, which is **not this frame's own cost**: the
## engine keeps the longest `_process` interval of the running second, render submit (the
## rendering server's own `sync()` and `draw()`) included, and hands it over once a second,
## replacing the last (`docs/DECISIONS.md`, M138, what the readout's `process` and `physics`
## lines measure). So whatever frame calls this reads the worst interval of the previous second,
## not its own.
static func process_ms() -> float:
	return Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

## The same reading for `_physics_process`, off `TIME_PHYSICS_PROCESS` — the worst physics tick of
## the previous second, held over the same way. Held apart from `process_ms()` rather than summed,
## because the two are fixed by different things: physics runs at its own tick rate and is the
## crowd's and the traffic's, while process is the drawing decisions and everything hung off them.
static func physics_ms() -> float:
	return Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
