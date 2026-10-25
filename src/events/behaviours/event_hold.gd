class_name EventHold
extends EventBehaviour
## **A conversation, or a door's hold**: a row with `EventDef.detain_seconds` takes her controls for
## that long, once for `chatting_mother` and every time she walks in again for a door's hut or post
## (`EventDef.redetains`). `CheckpointController` decides *when* — it holds the player, whom it
## detains, hides and lets out — and this is the clock of *what happens once it has*.

func _init() -> void:
	steps_each_tick = false

## Whether she has ever had her one conversation: once true, a row that does not redetain never
## detains again, whatever she does — spent as a detainer the moment the first one starts.
var _has_chatted := false
## Seconds left in the hold running now, or 0 when none is.
var _seconds_left := 0.0

## Whether a hold is running right now. Freezes the event (`EventInstance._process()`) and
## switches a mother's posture from strolling to talking.
func is_running() -> bool:
	return _seconds_left > 0.0

## Whether this row has ever held her.
func has_held() -> bool:
	return _has_chatted

## Starts a hold. Spends a row that does not redetain at once, before the clock has run a frame,
## so a second call before this one ends can never restart it.
func start() -> void:
	_has_chatted = true
	_seconds_left = event.def.detain_seconds

## One tick of a running hold: only its clock runs. **A door's body stays where it is when its hold
## ends**, still solid and ready to be armed again the instant she is released and clear; a
## mother's conversation ending is what starts her departure. **Nothing here shows her again**:
## this runs on a drawn frame, and the release that moves her runs on a physics frame
## (`CheckpointController.release_finished_holds()`), which shows her as it moves her.
func step(delta: float) -> void:
	_seconds_left = maxf(0.0, _seconds_left - delta)
	if _seconds_left <= 0.0 and not event.def.redetains:
		event._be_done()

func save() -> Dictionary:
	return {"has_chatted": _has_chatted, "seconds_left": _seconds_left}

func restore(state: Dictionary) -> void:
	_has_chatted = bool(state.get("has_chatted", false))
	_seconds_left = float(state.get("seconds_left", 0.0))
