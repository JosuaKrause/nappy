class_name CrowdTiming
extends RefCounted
## Where the crowd charges its time and its draws: what `Crowd` and every agent it makes are handed
## in place of reading the frame record's statics, so nothing under `src/crowd/` names the telemetry
## side. **This is the null sink** — it records nothing and says so (`running()` is false) — which a
## crowd with no record to feed (a rig, a test) keeps; `FrameRecordTiming` (`src/telemetry/`) is the
## one that feeds the frame record, handed in by whoever builds the city (`main._new_city()`).
## One per `Crowd`, handed on to its agents.
##
## **The crowd's physics tick is timed once, with every agent's step inside it** (`Crowd._tick_the_crowd()`),
## so no agent times itself: an agent keeps the sink only to count its draws (`drew()`).

## Whether a record is running now.
func running() -> bool:
	return false

## Starts charging time to the crowd, answering the bucket that was running, for `leave()`.
func enter() -> int:
	return 0

## Hands the clock back to whatever was running before `enter()`.
func leave(_previous: int) -> void:
	pass

## Counts one crowd agent's draw.
func drew() -> void:
	pass
