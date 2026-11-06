extends RefCounted
## Which lane a packed lane key names, for a suite that stands a car or reads a walker in that lane.
## The game packs a key (`LaneMover.make_lane_key()`) and never unpacks one, so the suite finds the
## four parts by asking the same packing which of the lanes it tells apart makes the key.

## Every key a lane in the searched range packs to.
static func all_keys() -> Array[int]:
	var keys: Array[int] = []
	for vertical in [false, true]:
		for corridor in range(-1, 12):
			for lane in range(-1, 8):
				for direction in [-1, 1]:
					keys.append(LaneMover.make_lane_key(vertical, corridor, lane, float(direction)))
	return keys

## `[vertical, corridor, lane, direction]` of the lane `key` names, in `make_lane_key()`'s argument
## order, the direction as -1 or 1; an empty array for a key no lane packs to.
static func parts_of(key: int) -> Array:
	for vertical in [false, true]:
		for corridor in range(-1, 12):
			for lane in range(-1, 8):
				for direction in [-1, 1]:
					if LaneMover.make_lane_key(vertical, corridor, lane, float(direction)) == key:
						return [vertical, corridor, lane, direction]
	return []
