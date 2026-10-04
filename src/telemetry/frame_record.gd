class_name FrameRecord
extends RefCounted
## The one switch the per-system frame record's timing goes through, and the names of what it
## times. *(2026-10-03, inbox #510: "let's focus on recording what cause spillover in the regular
## 2ms ... it seems that stuttering happens with a lot of objects on screen so influence
## calculation, pathing, drawing, etc. can all be the culprit".)*
##
## Every frame's time is split into the buckets below, **each microsecond in exactly one of them**:
## a timed entry point calls `enter()` on the way in and `leave()` on the way out, and the clock
## that was running before is paused while it runs and resumed after, so a timed system called
## from inside another one is charged to itself and not to both. `FrameRecorder` moves the clock
## between the engine's own phases (physics, process, drawing, waiting), and what no named system
## claims stays in the phase's own rest. That is why the buckets add up to the frame exactly.
##
## **Off, it costs one read per timed entry point**, and nothing is allocated, so a release page
## without `?framerecord=1` never reaches the clock. The crowd's agents and the live events, timed
## a couple of hundred times a frame, read a copy of `on` taken when each was made
## (`CrowdAgent._timed`, `EventInstance._timed`); the systems timed once a frame read `on` itself.

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
## The crowd's pathing: `Crowd._physics_process()` and every `CrowdAgent._process()`.
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

## Whether the record is running. Read by every timed entry point before anything else. Only
## while a `FrameRecorder` is in the tree: the escape builds none, so it pays nothing.
static var on := false
## The record itself, kept across a scene reload (the held restart), so a recording spans the
## restart rather than starting over at it.
static var ledger: FrameLedger

static func start(with: FrameLedger) -> void:
	ledger = with
	on = true

static func stop() -> void:
	on = false
	ledger = null

## Starts charging `bucket` and answers the bucket that was being charged, for `leave()`.
static func enter(bucket: int) -> int:
	return ledger.enter(bucket, Time.get_ticks_usec())

## Goes back to charging `previous`, the bucket `enter()` answered.
static func leave(previous: int) -> void:
	ledger.switch_to(previous, Time.get_ticks_usec())

## One of the game's own `_draw()` calls of `kind` (a `FrameLedger` draw counter) ran. A count, not
## a time: the page's clock steps in 100µs. Callers guard it with `if FrameRecord.on`, so a page
## without the record pays one static read per `_draw()`.
static func drew(kind: int) -> void:
	ledger.add(kind, 1)

## The two ends of the scenery queue's deferred window, run from the engine's deferred flush. See
## `FrameLedger.deferred_scenery_begins()`.
static func scenery_deferred_begins() -> void:
	if on:
		ledger.deferred_scenery_begins(Time.get_ticks_usec())

static func scenery_deferred_ends() -> void:
	if on:
		ledger.deferred_scenery_ends(Time.get_ticks_usec())

## One scenery job of `kind` (a `FrameLedger` job counter) ran in this frame.
static func scenery_job(kind: int) -> void:
	ledger.add(kind, 1)

## One `SceneryResidency.update()` finished, `elapsed_usec` after it started, under a budget of
## `budget_usec`: what it spent past the budget is the scenery queue's spill-over.
static func scenery_update(elapsed_usec: int, budget_usec: int) -> void:
	ledger.add(FrameLedger.SCENERY_UPDATES, 1)
	ledger.add(FrameLedger.SCENERY_OVER_BUDGET, maxi(0, elapsed_usec - budget_usec))
