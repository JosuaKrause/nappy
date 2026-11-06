extends RefCounted
## What a `CityState` has recorded, read off the snapshot the save writes (`CityState.snapshot()`),
## the one place the game reads a block's arc history back out.

## The day `block` last became something else, or 1 where it never has.
static func changed_on(state: CityState, block: Vector2i) -> int:
	for entry: Dictionary in state.snapshot()["changed_on"]:
		if int(entry["x"]) == block.x and int(entry["y"]) == block.y:
			return int(entry["v"])
	return 1
