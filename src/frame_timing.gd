class_name FrameTiming
extends RefCounted
## Where a system charges its time to the frame record, and the names of what it charges: what a
## system that is timed is handed in place of reading a switch every reader would share. **This is
## the null sink** — it records nothing and says so (`on` is false) — which a system with no record
## to feed (a rig, a test, a page without `?framerecord=1`) keeps; `FrameRecord`
## (`src/telemetry/`) is the one that feeds the record, handed in by whoever builds the system
## (`main`, and `City` for what it makes), and the one the `Sitting` keeps across a scene reload.
##
## Every frame's time is split into the buckets below, **each microsecond in exactly one of them**:
## a timed entry point calls `enter()` on the way in and `leave()` on the way out, and the clock
## that was running before is paused while it runs and resumed after, so a timed system called
## from inside another one is charged to itself and not to both. The game's own `_draw()` calls
## are not counted here: `FrameRecorder` listens for them on the nodes that draw.
##
## **Off, it costs one member read per timed entry point**, and nothing is allocated.

## What the physics steps did that no named system claims: her own movement and the physics
## server's step, and any `_draw()` a physics callback queued, since the engine flushes those at
## the end of the step.
const PHYSICS_REST := 0
## What the process step did that no named system claims: `main`, the HUD, the day clock, the
## resistance, scenery animation, the debug readout itself.
const PROCESS_REST := 1
## `SceneryResidency.update()`: the scenery queue under its 2ms budget, guard preparations
## included, and what its jobs left to the engine's deferred flush — a new region's tile map
## update, a newly shown building's, shadow chunk's or decal's first draw (see
## `FrameLedger.deferred_scenery_begins()`). What the renderer then does with the new pictures is
## `draw`'s.
const SCENERY := 2
## The crowd's tick: `Crowd._physics_process()`, every agent's step inside it (`LaneMover.step()`).
const CROWD := 3
## The baby's influence sweep: `Baby._physics_process()`, whose cost is `excitement_sources_at()`
## over every live event and walker near her, then the meter's own arithmetic.
const INFLUENCE := 4
## Event updates: `EventManager._physics_process()` and every `EventInstance._process()`.
const EVENTS := 5
## The danger cues: `ExcitementHalo._process()` (which source charges her and the carets'
## predictions) and `DangerEdge._process()` (the badges for what is coming off screen).
const CUES := 6
## The engine's side of drawing before the renderer: from the last `_process()` callback to the
## renderer's pre-draw callback — the deferred calls and the game's own `_draw()` callbacks queued
## during process (but the scenery queue's own, which are `scenery`'s), and the engine's scene
## preparation. What the game draws is counted per kind in the row's `draws_*` counters.
const DRAW := 7
## The renderer's own work: from its pre-draw callback to its post-draw callback — the canvas
## render, the submit, and any wait on the GPU. `draw` plus `render` is what `draw` was before the
## split. No GPU time of its own: a phone's browser has no way to measure it. On a native window
## with VSync on, the buffer swap's wait is inside this too. A headless run has no renderer, so
## its `render` is 0.
const RENDER := 8
## From the renderer's post-draw callback to the next frame's first callback: idle time until the
## next refresh, plus the engine's own input and window event processing. Not a cost.
const WAIT := 9

const BUCKET_NAMES: Array[String] = ["physics_rest", "process_rest", "scenery", "crowd",
	"influence", "events", "cues", "draw", "render", "wait"]

## The kinds of the game's own `_draw()` calls the record counts: the crowd's agents, the live
## events, the danger halos' rims (`EntityHalo`), scenery (buildings, their shadow chunks, decals,
## props, edges, water), the danger badges (`DangerEdge`), her own stroller, and every other
## (traffic lights, chalk, closure markers, the HUD's own drawing). In this order, which
## `FrameLedger`'s draw counters follow.
enum Draw { CROWD, EVENTS, HALOS, SCENERY, BADGES, PLAYER, OTHER }

## The kinds of scenery job the queue counts, in the order `FrameLedger`'s `JOBS_*` counters follow
## (`GUARD` is its `GUARD_PREPARATIONS`, the synchronous ones whatever their kind).
enum Job { GROUND, BUILDING, PROP, SHADOW, DECAL, GUARD }

## The meta a canvas carries, holding its `Draw` kind, to have its `_draw()` calls counted
## (`FrameRecorder` reads it): a canvas that is no class of its own (a shadow chunk, a station's
## yard layer), and the view's nodes, which the recorder, standing beside the view, may not name.
const DRAW_KIND_META := &"counts_draws_as"

## Whether a record is running now. Read by every timed entry point before anything else.
var on := false

## Whether a record is running now, for a caller outside the timed entry points, which read `on`
## directly: they are the hot path.
func is_on() -> bool:
	return on

## Starts charging `bucket` and answers the bucket that was being charged, for `leave()`.
func enter(_bucket: int) -> int:
	return 0

## Goes back to charging `previous`, the bucket `enter()` answered.
func leave(_previous: int) -> void:
	pass

## One scenery job of `kind` (a `Job`) ran in this frame.
func scenery_job(_kind: int) -> void:
	pass

## One `SceneryResidency.update()` finished, `elapsed_usec` after it started, under a budget of
## `budget_usec`: what it spent past the budget is the scenery queue's spill-over.
func scenery_update(_elapsed_usec: int, _budget_usec: int) -> void:
	pass

## The two ends of the scenery queue's deferred window, run from the engine's deferred flush. See
## `FrameLedger.deferred_scenery_begins()`.
func scenery_deferred_begins() -> void:
	pass

func scenery_deferred_ends() -> void:
	pass

## One of the game's own `_draw()` calls of `kind` (a `Draw`) ran. A count, not a time.
func drew(_kind: int) -> void:
	pass
