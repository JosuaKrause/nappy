class_name EventUnreachable
extends EventBehaviour
## **A row sent down her line that cannot reach her is retired, not left to run on out of sight**
## (sunny-hedgehog): the loose dog. The director sends it ahead of her, but she may turn round or
## run (`RUN_SPEED` 168 against its 132), and a dog behind her that is not gaining never arrives.
## Once it is more than `Tuning.OUT_OF_SIGHT` from her — nothing on screen — and has not closed on
## her for `GIVES_UP` seconds, it is finished where it stands; nothing is seen to go. A dog that is
## closing, even slowly after a walker going away, runs on and passes her.

## How long it may be out of sight and not closing on her before it is retired, in seconds.
const GIVES_UP := 2.0
## How often the gap to her is looked at, in seconds, and the least it must have shrunk by, per
## second, to count as closing — a dog running at 132px/s after a walker going away at 92 closes at
## 40, a dog after someone running (168px/s) at none.
const LOOK_EVERY := 0.5
const CLOSING_AT_LEAST := 10.0

var _gap_looked_at := INF
var _look_clock := 0.0
var _not_closing_for := 0.0

func step(delta: float) -> void:
	if event.is_finished or event.is_leaving or event.player_at == Vector2.INF:
		return
	var gap: float = event.global_position.distance_to(event.player_at)
	if gap <= Tuning.OUT_OF_SIGHT:
		_gap_looked_at = INF
		_look_clock = 0.0
		_not_closing_for = 0.0
		return
	_look_clock += delta
	if _look_clock < LOOK_EVERY:
		return
	if _gap_looked_at != INF and (_gap_looked_at - gap) / _look_clock < CLOSING_AT_LEAST:
		_not_closing_for += _look_clock
	else:
		_not_closing_for = 0.0
	_gap_looked_at = gap
	_look_clock = 0.0
	if _not_closing_for >= GIVES_UP:
		event._finish()

func save() -> Dictionary:
	return {"gap_looked_at": _gap_looked_at, "look_clock": _look_clock,
			"not_closing_for": _not_closing_for}

func restore(state: Dictionary) -> void:
	_gap_looked_at = float(state.get("gap_looked_at", INF))
	_look_clock = float(state.get("look_clock", 0.0))
	_not_closing_for = float(state.get("not_closing_for", 0.0))
