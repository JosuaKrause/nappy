class_name HintWatcher
extends RefCounted
## **One hint's question**, asked every tick by `HintWatch`: does the hint apply now, and which way
## does it point. A watcher keeps its own arming (a hint that applied and is still true does not ask
## again), is handed only what its question needs, and knows no other watcher: the order they win in
## is `HintWatch`'s list.
##
## `asks()` never changes what the watcher is armed for: a hint that loses to another is neither
## shown nor counted and asks again next tick. `shown()` is called only for the hint that wins.

## The hint this watcher asks for.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WAY_TO_PARK

## Whether the hint shows every time its moment comes, rather than a few times (`HintLedger`).
func every_time() -> bool:
	return false

## Whether the hint applies this tick. Overrides pass the frame's own answer.
func asks(_frame: HintFrame) -> bool:
	return false

## The way the hint points, as a unit vector from her, or zero for a hint that points nowhere.
func direction(_frame: HintFrame) -> Vector2:
	return Vector2.ZERO

## Whether the bubble this watcher put up stays while its moment lasts (`true`, ended by
## `still_applies()`), or stands for `HintWatch.SHOW_SECONDS` and goes (`false`).
func holds_while_true() -> bool:
	return false

## Whether a bubble put up and held (`holds_while_true()`) still applies this tick.
func still_applies(_frame: HintFrame) -> bool:
	return true

## Called when this watcher's hint wins and goes up, so it can disarm.
func shown() -> void:
	pass
