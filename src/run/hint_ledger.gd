class_name HintLedger
extends RunSubState
## How many times each thought-bubble hint has shown this run (`HintWatch`): the count that
## makes a bubble appear only a few times per lesson (`Tuning.HINT_SHOWS_PER_LESSON`) and never
## again. **A lost attempt gives its shows back**, so a day replayed is taught again the way the
## day-3 run lesson is (`HUD._teach_the_day()`). Saved under a key of its own, so a save written
## before the bubbles loads with none shown.

const SAVE_KEY := "hints"

## Shows by hint id (`HintKind.id_of()`).
var _shown := {}
var _dawn_shown := {}

## Overrides RunSubState.slot.
func slot() -> Slot:
	return Slot.NESTED

## Overrides RunSubState.save_key.
func save_key() -> String:
	return SAVE_KEY

## How many times `hint` has shown this run.
func _shows_of(hint: StringName) -> int:
	return int(_shown.get(hint, 0))

## Whether `hint` may show once more, `limit` being the most shows its lesson gets.
func has_shows_left(hint: StringName, limit: int) -> bool:
	return _shows_of(hint) < limit

## Counts one show of `hint` and answers how many it has had now.
func record_show(hint: StringName) -> int:
	_shown[hint] = _shows_of(hint) + 1
	return _shows_of(hint)

## Overrides RunSubState.reset.
func reset() -> void:
	_shown = {}
	_dawn_shown = {}

## Overrides RunSubState.photograph.
func photograph() -> void:
	_dawn_shown = _shown.duplicate()

## Overrides RunSubState.give_back.
func give_back() -> void:
	_shown = _dawn_shown.duplicate()

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	return {"shown": _as_data(_shown), "dawn_shown": _as_data(_dawn_shown)}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_shown = _from_data(data.get("shown", {}))
	_dawn_shown = _from_data(data.get("dawn_shown", {}))

static func _as_data(counts: Dictionary) -> Dictionary:
	var data := {}
	for hint: StringName in counts:
		data[String(hint)] = int(counts[hint])
	return data

static func _from_data(raw: Dictionary) -> Dictionary:
	var counts := {}
	for key: String in raw:
		counts[StringName(key)] = int(raw[key])
	return counts
