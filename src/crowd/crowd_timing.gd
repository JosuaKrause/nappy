class_name CrowdTiming
extends RefCounted
## The crowd's own handle on the frame record: what `Crowd` and every agent it makes charge their
## time and their draws to, so neither reads `FrameRecord`'s statics itself. One per `Crowd`, handed
## to its agents.
##
## **An agent copies whether the record is running when it is handed this**, so that with the record
## off its `_process()` pays one member read rather than a call into a second object: with two
## hundred or so agents a frame, that difference made every player's frame measurably longer on a
## desktop (`docs/evidence/m159-frame-record-2026-10-04/`). An agent is made per day, after the
## recorder has started, so every one made under a record is timed.

## Whether the frame record is running now.
func running() -> bool:
	return FrameRecord.on

## Starts charging time to the crowd, answering the bucket that was running, for `leave()`.
func enter() -> int:
	return FrameRecord.enter(FrameRecord.CROWD)

## Hands the clock back to whatever was running before `enter()`.
func leave(previous: int) -> void:
	FrameRecord.leave(previous)

## Counts one crowd agent's draw.
func drew() -> void:
	FrameRecord.drew(FrameLedger.DRAWS_CROWD)
