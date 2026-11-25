class_name SettledState
extends RunSubState
## The calm block she settled in on each day, so the next day's calm ground is somewhere else. Not
## photographed: `RunCalendar.finish_day()` erases the lost day's own entry, which is
## what a retry has to forget.

## The calm block the baby actually went to sleep in, per day: `day -> Vector2i`. Run-scoped and
## gameplay-owned, deliberately *not* read out of the telemetry log even though the `calm` entries
## say the same thing: telemetry never touches gameplay, and a rule that reads a trace to decide
## tomorrow's events would make the game play differently with `--no-telemetry`.
var _settled_in: Dictionary = {}

## Where she settled on `on_day`, or `Vector2i(-1, -1)` for a day she has not.
func block_on(on_day: int) -> Vector2i:
	return _settled_in.get(on_day, Vector2i(-1, -1))

## Keeps `block` as where she settled on `on_day`, unless that day already has one: the record is
## written once (`RunCalendar.remember_where_she_settled()`).
func remember(on_day: int, block: Vector2i) -> bool:
	if _settled_in.has(on_day):
		return false
	_settled_in[on_day] = block
	return true

## Forgets where she settled on `on_day`, which a lost day's retry has to (`RunCalendar.finish_day()`).
func forget(on_day: int) -> void:
	_settled_in.erase(on_day)

## Overrides RunSubState.reset.
func reset() -> void:
	_settled_in.clear()

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	var settled_data: Array = []
	for settled_day: int in _settled_in:
		var block: Vector2i = _settled_in[settled_day]
		settled_data.append({"day": settled_day, "x": block.x, "y": block.y})
	return {"settled_in": settled_data}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_settled_in.clear()
	for raw: Dictionary in data["settled_in"]:
		_settled_in[int(raw["day"])] = Vector2i(int(raw["x"]), int(raw["y"]))
