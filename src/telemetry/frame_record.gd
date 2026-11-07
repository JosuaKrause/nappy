class_name FrameRecord
extends FrameTiming
## The frame record the game feeds: the `FrameTiming` that keeps time, and the ledger it keeps it
## in. *(2026-10-03, inbox #510: "let's focus on recording what cause spillover in the regular
## 2ms ... it seems that stuttering happens with a lot of objects on screen so influence
## calculation, pathing, drawing, etc. can all be the culprit".)*
##
## One per sitting: `main` makes it when the run asks for a record and the `Sitting` keeps it, so a
## recording spans a scene reload (the held restart) rather than starting over at it, and `main`
## hands it to every system that is timed (`Baby`, `City`, the danger cues). The buckets and their
## names are `FrameTiming`'s; `FrameRecorder` moves the clock between the engine's own phases
## (physics, process, drawing, waiting), and what no named system claims stays in the phase's own
## rest. That is why the buckets add up to the frame exactly.
##
## **Off, it costs one member read per timed entry point**, and nothing is allocated, so a release
## page without `?framerecord=1` never reaches the clock. It is on only while a `FrameRecorder` is
## in the tree (`start()` and `stop()`): the escape builds none. The live events, timed a couple
## of hundred times a frame, read the sink's `on` through a member of their own
## (`EventInstance.timing`); the systems timed once a frame read it directly.

## The record itself: kept by the sitting along with this object, so a recording spans a restart.
## Null until `start()`.
var ledger: FrameLedger

## Starts the record on `with`, answering to `on` from here.
func start(with: FrameLedger) -> void:
	ledger = with
	on = true

## Switches the timing off, keeping the ledger: the next recorder carries on in it.
func stop() -> void:
	on = false

## Overrides FrameTiming.enter.
func enter(bucket: int) -> int:
	return ledger.enter(bucket, Time.get_ticks_usec())

## Overrides FrameTiming.leave.
func leave(previous: int) -> void:
	ledger.switch_to(previous, Time.get_ticks_usec())

## A count, not a time: the page's clock steps in 100µs.
##
## Overrides FrameTiming.drew.
func drew(kind: int) -> void:
	ledger.add(FrameLedger.DRAWS_CROWD + kind, 1)

## Overrides FrameTiming.scenery_deferred_begins.
func scenery_deferred_begins() -> void:
	if on:
		ledger.deferred_scenery_begins(Time.get_ticks_usec())

## Overrides FrameTiming.scenery_deferred_ends.
func scenery_deferred_ends() -> void:
	if on:
		ledger.deferred_scenery_ends(Time.get_ticks_usec())

## Overrides FrameTiming.scenery_job.
func scenery_job(kind: int) -> void:
	ledger.add(FrameLedger.JOBS_GROUND + kind, 1)

## Overrides FrameTiming.scenery_update.
func scenery_update(elapsed_usec: int, budget_usec: int) -> void:
	ledger.add(FrameLedger.SCENERY_UPDATES, 1)
	ledger.add(FrameLedger.SCENERY_OVER_BUDGET, maxi(0, elapsed_usec - budget_usec))
