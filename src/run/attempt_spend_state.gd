class_name AttemptSpendState
extends RunSubState
## What an attempt can spend and a lost day gives back: the one-shot events already used, the scars
## the city carries and where every block stands along its arc. The walls' tears and the pelican
## bag's count are spent the same way and are their own parts (`PosterState`, `PelicanState`).

## The one-shot events already used this run, by id.
var consumed_one_shots: Array[String] = []
## What the city carries from earlier days: `{"id", "position", "since_day"}`.
var scars: Array[Dictionary] = []
var city_state := CityState.new()

var _dawn_consumed_one_shots: Array[String] = []
var _dawn_scars: Array[Dictionary] = []
var _dawn_city_state := {}

func reset() -> void:
	consumed_one_shots.clear()
	scars.clear()
	city_state.reset()
	_dawn_consumed_one_shots = []
	_dawn_scars = []
	_dawn_city_state = {}

func photograph() -> void:
	_dawn_consumed_one_shots = consumed_one_shots.duplicate()
	_dawn_scars = scars.duplicate()
	_dawn_city_state = city_state.snapshot()

func give_back() -> void:
	consumed_one_shots = _dawn_consumed_one_shots.duplicate()
	scars = _dawn_scars.duplicate()
	city_state.restore(_dawn_city_state)

func to_data() -> Dictionary:
	return {
		"consumed_one_shots": consumed_one_shots.duplicate(),
		"scars": _scars_as_data(scars),
		"city_state": city_state.snapshot(),
		"_dawn_consumed_one_shots": _dawn_consumed_one_shots.duplicate(),
		"_dawn_scars": _scars_as_data(_dawn_scars),
		"_dawn_city_state": _dawn_city_state.duplicate(true),
	}

func restore(data: Dictionary) -> void:
	consumed_one_shots.assign(data["consumed_one_shots"])
	scars = _scars_from_data(data["scars"])
	city_state.restore(data["city_state"])
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
