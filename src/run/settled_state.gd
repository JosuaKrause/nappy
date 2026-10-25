class_name SettledState
extends RunSubState
## The calm block she settled in on each day, so the next day's calm ground is somewhere else. Not
## photographed: `GameState.finish_day()` erases the lost day's own entry, which is what a retry
## has to forget.

## Day -> the block she settled in.
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
