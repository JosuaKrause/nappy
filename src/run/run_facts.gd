class_name RunFacts
extends RunSubState
## The run's facts that ride beside the `"state"` snapshot, each read with a default for its
## absence so a save from a build that never wrote it still loads: which section of the escape the
## run is in, the alley tiles the resistance has used and the park barriers may stand around.
## Nothing here is photographed or given back by a lost day.

## Which section of the escape this run is in, as a `DaySpec.Section` — `0` (`NONE`) for every one
## of the fourteen days, `BUILDING` or `CITY` once a won day 14 with every task complete has handed
## over to it. An `int` rather than the enum because a cross-script enum is not the same type as
## itself across a script boundary (see the **godot** skill), and a field on the *run* rather than
## on the scene for two reasons: it survives `reload_current_scene()`, which is how the handover
## reaches the escape's own boot with the run intact, and it is the one thing the save carries about
## the escape, so a game closed in a section opens on that section's brief.
var _escape_section: int = 0
## Alley tiles a completed pickup step's chalk mark stood at, this run — read by
## `ResistanceDirector._pick_reachable()` and `_nearest_alley_within()` so a later mark never
## relocates onto, or starts on, the same alley while another eligible one is still in reach
## (M177). **Not given back by a lost day**: a lost day's own placement never reads this list (the
## mark it is about was placed at dawn, before any tile could be recorded against it today), so an
## undone attempt's tile only ever costs the next placement one more alley to avoid.
var _completed_resistance_alley_tiles: Array[Vector2i] = []
## The one calm area barriers ever stand around this run, once she has used it — `(-1, -1)` until
## one is. Chosen no earlier than act III; see docs/CITY.md, "Shutting a spent park". `Main`
## hands this and `fenced_park_act` to `CityMap.set_fenced_park_state()` before the repaint and
## remembers its first choice once it returns. This history survives the act boundary even though
## the physical fence does not.
var _fenced_park := Vector2i(-1, -1)
## The act that chose `_fenced_park`.
var _fenced_park_act := 0

## Which section of the escape the run is in, a `DaySpec.Section` as an `int` (`_escape_section`).
func escape_section() -> int:
	return _escape_section

## Puts the run in `section`: `main` as a section begins, `RunCalendar` (`NONE`) as the run ends.
func set_escape_section(section: int) -> void:
	_escape_section = section

## The alley tiles completed pickups' marks stood at this run, the live list, which a reader does
## not change; `record_completed_alley_tile()` adds to it.
func completed_resistance_alley_tiles() -> Array[Vector2i]:
	return _completed_resistance_alley_tiles

## The one calm area barriers stand around this run, or `Vector2i(-1, -1)` until she has used one.
func fenced_park() -> Vector2i:
	return _fenced_park

## The act that chose `fenced_park()`.
func fenced_park_act() -> int:
	return _fenced_park_act

## Overrides RunSubState.slot.
func slot() -> Slot:
	return Slot.RIDER

## Overrides RunSubState.reset.
func reset() -> void:
	_escape_section = 0
	_completed_resistance_alley_tiles.clear()
	_fenced_park = Vector2i(-1, -1)
	_fenced_park_act = 0

## Records a tile a pickup's mark stood at when its step completed, ignoring one already recorded.
## `ResistanceDirector._on_contact_completed()` is the one caller.
func record_completed_alley_tile(tile: Vector2i) -> void:
	if tile not in _completed_resistance_alley_tiles:
		_completed_resistance_alley_tiles.append(tile)

func remember_fenced_park(block: Vector2i, act: int) -> void:
	if _fenced_park.x < 0 and block.x >= 0:
		_fenced_park = block
		_fenced_park_act = act

## Overrides RunSubState.to_data.
func to_data() -> Dictionary:
	var alley_tiles: Array = []
	for tile: Vector2i in _completed_resistance_alley_tiles:
		alley_tiles.append({"x": tile.x, "y": tile.y})
	return {
		"escape_section": _escape_section,
		"completed_resistance_alley_tiles": alley_tiles,
		"fenced_park": {"x": _fenced_park.x, "y": _fenced_park.y},
		"fenced_park_act": _fenced_park_act,
	}

## Overrides RunSubState.restore.
func restore(data: Dictionary) -> void:
	_escape_section = int(data.get("escape_section", 0))
	_completed_resistance_alley_tiles.clear()
	for raw: Dictionary in data.get("completed_resistance_alley_tiles", []):
		_completed_resistance_alley_tiles.append(Vector2i(int(raw["x"]), int(raw["y"])))
	var fenced: Variant = data.get("fenced_park", null)
	if fenced is Dictionary:
		var at: Dictionary = fenced
		_fenced_park = Vector2i(int(at.get("x", -1)), int(at.get("y", -1)))
	else:
		_fenced_park = Vector2i(-1, -1)
	_fenced_park_act = int(data.get("fenced_park_act", 0))
