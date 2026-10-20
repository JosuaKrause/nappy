class_name RunTrace
extends RefCounted
## The one sink game logic writes its own account of a decision into, for the run log to keep:
## why a placement went where it did, which way a roll fell, what a director set in motion and
## what a day cost. docs/TELEMETRY.md's "the other half of the log": a single line at the point of
## the roll, built from what is in scope there and nowhere else.
##
## **Handed in, never fetched.** Whoever builds a component hands it the run's trace (`RunSession`
## makes the one that writes to the run log); a component nobody handed one writes nowhere, so a
## test builds the part it wants and hands it a trace that records into a list, or none at all.
## Nothing that decides anything names the run log itself.
##
## **It must not touch gameplay**, the run log's own rule: a caller formats a line from values it
## already has, hoisting a roll into a variable to print it and never drawing one for it.

## Where a line goes: a `Callable(kind: String, text: String)`, or none, which drops every line.
var _write: Callable

func _init(write := Callable()) -> void:
	_write = write

## One line of the deciding system's own account. `kind` is a kind from docs/TELEMETRY.md's table,
## reused rather than invented.
func note(kind: String, text: String) -> void:
	if _write.is_valid():
		_write.call(kind, text)

## A trace that keeps every line it is handed as `"kind text"`, for a test to read back.
static func recording(into: Array[String]) -> RunTrace:
	return RunTrace.new(func(kind: String, text: String) -> void:
		into.append("%s %s" % [kind, text]))

# ------------------------------------------------------------------ formatting ---
# Shared by every writer, so a tile reads the same whichever system wrote the line — the run's own
# account through a trace, or the run log's observer.

static func tile(at: Vector2i) -> String:
	return "(%d,%d)" % [at.x, at.y]

## Which way something is pointing, as a compass bearing in whole degrees rather than a word.
## +y is south — the city is drawn from above — so the bearing runs clockwise from north (-y)
## at 0°, through east (+x) at 90°, south (+y) at 180° and west (-x) at 270°, the same way a
## real compass reads. A press sets an arbitrary unit vector
## (`TouchControls.heading_to()`), so most headings are diagonal, and a word would either lose
## the difference between two headings a player can tell apart or invent a ninth word for every
## one of them; the bearing is exact instead. `nowhere` stays for a genuinely zero vector — the
## absence of a direction, not a rounded one.
static func compass(direction: Vector2) -> String:
	if direction.length_squared() < 0.0001:
		return "nowhere"
	var degrees := roundi(rad_to_deg(atan2(direction.x, -direction.y))) % 360
	if degrees < 0:
		degrees += 360
	return "%d°" % degrees

static func purpose(which: GameEnums.BlockPurpose) -> String:
	return GameEnums.BlockPurpose.keys()[which].to_lower()

## The ground somebody is standing on. Where she chose to stop is most of what a stand means:
## a kerb is somebody waiting for a gap in the traffic, a pavement in the middle of a block is
## somebody waiting for a meter.
static func tile_type(which: GameEnums.TileType) -> String:
	return GameEnums.TileType.keys()[which].to_lower()
