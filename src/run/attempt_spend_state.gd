class_name AttemptSpendState
extends RunSubState
## What an attempt can spend and a lost day gives back: the one-shot events already used, the scars
## the city carries and where every block stands along its arc. The walls' tears and the pelican
## bag's count are spent the same way and are their own parts (`PosterState`, `PelicanState`).

## The one-shot events already used this run, by id, so they never fire twice.
var _consumed_one_shots: Array[String] = []
## Permanent marks a one-off event left on the city: `{"id", "position", "since_day"}`. The building
## day 3's fire caught is still drawn burnt on that corner on day 12, never repaired — the city
## remembers, which is most of how the escalation is told.
var _scars: Array[Dictionary] = []
## Where each block currently is along its arc: the arcs themselves belong to the `CityMap` and never
## change, this is only how far along them the run has got. See docs/CITY.md, "Block purposes".
var _city_state := CityState.new()

var _dawn_consumed_one_shots: Array[String] = []
var _dawn_scars: Array[Dictionary] = []
var _dawn_city_state := {}

## The city's block arcs as far as the run has got: what the dawn, the day's events and the resistance
## advance, and what a block's purpose is read from.
func block_arcs() -> CityState:
	return _city_state

## The one-shot events this run has used: the live list, which the day's events are handed and add
## to as one fires (`EventManager.start_day()`), so the run keeps what the day spent.
func consumed_one_shots() -> Array[String]:
	return _consumed_one_shots

## The scars the run holds, each `{"id", "position", "since_day"}`: the live list, which a reader
## does not change; `record_scar()` adds to it.
func scars() -> Array[Dictionary]:
	return _scars

## Whether the run holds a scar `id` (a mark a one-off event left, kept for the rest of the run).
func has_scar(id: String) -> bool:
	return scar_position(id) != Vector2.INF

## Where the run recorded its scar `id`, or `Vector2.INF` when it never recorded one.
func scar_position(id: String) -> Vector2:
	for scar in _scars:
		if String(scar["id"]) == id:
			return scar["position"]
	return Vector2.INF

## Every position the run recorded a scar `id` at, in the order they were recorded.
func scar_positions(id: String) -> Array[Vector2]:
	var found: Array[Vector2] = []
	for scar in _scars:
		if String(scar["id"]) == id:
			found.append(scar["position"] as Vector2)
	return found

## Records a scar of `id` at `position` on day `since_day`, ignoring one already there (within a pixel).
func record_scar(id: String, position: Vector2, since_day: int) -> void:
	for scar in _scars:
		if scar["id"] == id and (scar["position"] as Vector2).distance_to(position) < 1.0:
			return
	_scars.append({"id": id, "position": position, "since_day": since_day})

## Overrides RunSubState.reset.
func reset() -> void:
	_consumed_one_shots.clear()
	_scars.clear()
	_city_state.reset()
	_dawn_consumed_one_shots = []
	_dawn_scars = []
	_dawn_city_state = {}

## Overrides RunSubState.photograph.
func photograph() -> void:
	_dawn_consumed_one_shots = _consumed_one_shots.duplicate()
	_dawn_scars = _scars.duplicate()
	_dawn_city_state = _city_state.snapshot()

## Overrides RunSubState.give_back.
func give_back() -> void:
	_consumed_one_shots = _dawn_consumed_one_shots.duplicate()
	_scars = _dawn_scars.duplicate()
	_city_state.restore(_dawn_city_state)

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	return {
		"consumed_one_shots": _consumed_one_shots.duplicate(),
		"scars": _scars_as_data(_scars),
		"city_state": _city_state.snapshot(),
		"_dawn_consumed_one_shots": _dawn_consumed_one_shots.duplicate(),
		"_dawn_scars": _scars_as_data(_dawn_scars),
		"_dawn_city_state": _dawn_city_state.duplicate(true),
	}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_consumed_one_shots.assign(data["consumed_one_shots"])
	_scars = _scars_from_data(data["scars"])
	_city_state.restore(data["city_state"])
	_dawn_consumed_one_shots.assign(data["_dawn_consumed_one_shots"])
	_dawn_scars = _scars_from_data(data["_dawn_scars"])
	_dawn_city_state = _cast_dawn_city_state(data["_dawn_city_state"])

static func _scars_as_data(from: Array[Dictionary]) -> Array:
	var data: Array = []
	for scar in from:
		var position: Vector2 = scar["position"]
		data.append({
			"id": scar["id"], "x": position.x, "y": position.y, "since_day": scar["since_day"],
		})
	return data

static func _scars_from_data(raw: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for scar: Dictionary in raw:
		found.append({
			"id": String(scar["id"]),
			"position": Vector2(float(scar["x"]), float(scar["y"])),
			"since_day": int(scar["since_day"]),
		})
	return found

static func _cast_dawn_city_state(raw: Dictionary) -> Dictionary:
	var cast := {}
	for key: String in raw:
		var cast_entries: Array = []
		for entry: Dictionary in (raw[key] as Array):
			cast_entries.append({"x": int(entry["x"]), "y": int(entry["y"]), "v": int(entry["v"])})
		cast[key] = cast_entries
	return cast
