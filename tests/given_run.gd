class_name GivenRun
extends RefCounted
## **A run put in a state a test sets up, through the parts' own save and restore**: each function
## reads a part's data (`RunSubState.to_data()`), changes one entry and hands it back
## (`RunSubState.restore()`), the path a save read off disk takes, so a test sets a list or a count
## the game builds one step at a time (the steps completed by day 8, the tears made so far) without a
## setter only tests would call, and nothing else about the part moves: its photograph stays as it
## was, and no signal is sent.

## The steps completed, in this order, replacing the list.
static func completed_steps(run: RunState, steps: Array[int]) -> void:
	var data := run.resistance().to_data()
	data["completed_resistance_steps"] = steps.duplicate()
	run.resistance().restore(data)

## The steps failed, replacing the list.
static func failed_steps(run: RunState, steps: Array[int]) -> void:
	var data := run.resistance().to_data()
	data["failed_resistance_steps"] = steps.duplicate()
	run.resistance().restore(data)

## Whether the last night's sabotage went through.
static func sabotage(run: RunState, done: bool) -> void:
	var data := run.resistance().to_data()
	data["sabotage_done"] = done
	run.resistance().restore(data)

## Whether the pram is carrying the package.
static func carrying_package(run: RunState, carrying: bool) -> void:
	var data := run.resistance().to_data()
	data["resistance_carrying_package"] = carrying
	run.resistance().restore(data)

## The alley tiles completed pickups used, replacing the list.
static func alley_tiles(run: RunState, tiles: Array[Vector2i]) -> void:
	var data := run.facts().to_data()
	var rows: Array = []
	for tile in tiles:
		rows.append({"x": tile.x, "y": tile.y})
	data["completed_resistance_alley_tiles"] = rows
	run.facts().restore(data)

## The calm area barriers stand around, and the act that chose it.
static func fenced_park(run: RunState, block: Vector2i, act: int) -> void:
	var data := run.facts().to_data()
	data["fenced_park"] = {"x": block.x, "y": block.y}
	data["fenced_park_act"] = act
	run.facts().restore(data)

## The run's scars, replacing the list: each `{"id", "position", "since_day"}`.
static func scars(run: RunState, kept: Array[Dictionary]) -> void:
	var data := run.attempt_spend().to_data()
	var rows: Array = []
	for scar in kept:
		var at: Vector2 = scar["position"]
		rows.append({"id": scar["id"], "x": at.x, "y": at.y, "since_day": scar["since_day"]})
	data["scars"] = rows
	run.attempt_spend().restore(data)

## The last day whose dawn pasting is on the walls, earlier than the walls' own record included.
static func pasted_through(run: RunState, day: int) -> void:
	var data := run.posters().to_data()
	data["pasted_through"] = day
	run.posters().restore(data)

## How many tears she has made.
static func tears(run: RunState, count: int) -> void:
	var data := run.posters().to_data()
	data["tears"] = count
	run.posters().restore(data)

## How many cyclists the run has drawn from its pelican bag.
static func pelican_draws(run: RunState, count: int) -> void:
	var data := run.pelican().to_data()
	data["draws"] = count
	run.pelican().restore(data)

## Where she settled on `day`, or `Vector2i(-1, -1)`, read off the save's snapshot: only the
## calendar asks the run's record of it (`RunCalendar.settled_this_act()`).
static func settled_on(run: RunState, day: int) -> Vector2i:
	var state: Dictionary = run.run_parts().run_data()["state"]
	for row: Dictionary in state["settled_in"]:
		if int(row["day"]) == day:
			return Vector2i(int(row["x"]), int(row["y"]))
	return Vector2i(-1, -1)

## Records `block` as where she settled on `day`, replacing that day's record, through the save's
## data (every part is read back as it was written, `RunStateRegistry.restore_run_data()`).
static func settled(run: RunState, day: int, block: Vector2i) -> void:
	var data := run.run_parts().run_data()
	var state: Dictionary = data["state"]
	var rows: Array = []
	for row: Dictionary in state["settled_in"]:
		if int(row["day"]) != day:
			rows.append(row)
	rows.append({"day": day, "x": block.x, "y": block.y})
	state["settled_in"] = rows
	run.run_parts().restore_run_data(data)
