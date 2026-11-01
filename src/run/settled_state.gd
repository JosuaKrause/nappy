class_name SettledState
extends RunSubState
## The calm block she settled in on each day, so the next day's calm ground is somewhere else. Not
## photographed: `GameState.calendar.finish_day()` erases the lost day's own entry, which is
## what a retry has to forget.

## The calm block the baby actually went to sleep in, per day: `day -> Vector2i`. Run-scoped and
## gameplay-owned, deliberately *not* read out of the telemetry log even though the `calm` entries
## say the same thing: telemetry never touches gameplay, and a rule that reads a trace to decide
## tomorrow's events would make the game play differently with `--no-telemetry`.
var settled_in: Dictionary = {}

func reset() -> void:
	settled_in.clear()

func to_data() -> Dictionary:
	var settled_data: Array = []
	for settled_day: int in settled_in:
		var block: Vector2i = settled_in[settled_day]
		settled_data.append({"day": settled_day, "x": block.x, "y": block.y})
	return {"settled_in": settled_data}

func restore(data: Dictionary) -> void:
	settled_in.clear()
	for raw: Dictionary in data["settled_in"]:
		settled_in[int(raw["day"])] = Vector2i(int(raw["x"]), int(raw["y"]))
