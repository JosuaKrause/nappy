extends RefCounted
## One event drawn for a check about what its look draws: set up on a street, handed a recording
## drawer (`tests/recording_event_drawer.gd`) through `EventInstance.drawer`, the member its manager's
## spawner assigns, stood in the tree and drawn over real frames, its slices and its band with it.
## A helper, not a suite: the runner loads only `test_*.gd`.

const RecordingEventDrawer := preload("res://tests/recording_event_drawer.gd")
const EastWestStreet := preload("res://tests/east_west_street.gd")

## Where the event stands, clear of the origin so a slice's place and the event's differ.
const AT := Vector2(300.0, 300.0)

## `def` standing at `at` under `parent`, drawn: on an east-west street when `vertical`, which its
## spread reads its axis off as it does in a city (`EventInstance.runs_vertically()`), on open
## ground otherwise, or on `map` when one is handed. `atlas`, when given, is the drawer's, for a look
## whose slices stand scenery cut from it (a crash, a burst main). Three process frames pass: the
## slices are put in beside it at the end of the first and drawn by the next. The caller frees the
## instance, which takes its slices with it.
static func stand(parent: Node, def: EventDef, vertical: bool,
		atlas: AtlasLibrary = null, map: WorldMap = null, at := AT) -> EventInstance:
	var instance := build(parent, def, vertical, atlas, map, at)
	await frames(parent)
	return instance

## `stand()` without the frames: the event is set up and in the tree, drawn by the frames the caller
## lets pass (`frames()`), so many can be drawn by one wait.
static func build(parent: Node, def: EventDef, vertical: bool,
		atlas: AtlasLibrary = null, map: WorldMap = null, at := AT) -> EventInstance:
	var instance := EventInstance.new()
	instance.atlas = atlas
	instance.drawer = RecordingEventDrawer.new(atlas)
	var ground: WorldMap = map
	if ground == null:
		ground = EastWestStreet.new() if vertical else WorldMap.open_ground()
	instance.setup(def, at, PackedVector2Array(), Vector2.RIGHT, ground)
	parent.add_child(instance)
	return instance

## The frames an event built by `build()` needs to be drawn.
static func frames(parent: Node) -> void:
	for i in 3:
		await parent.get_tree().process_frame

## What `instance` shows now: the pictures its drawer recorded for the time each canvas was last
## drawn (`RecordingEventDrawer.shown()`).
static func shown(instance: EventInstance) -> Array[Dictionary]:
	return (instance.drawer as RecordingEventDrawer).shown()
