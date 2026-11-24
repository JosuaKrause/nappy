extends RefCounted
## The stand-ins the screen-edge badge's suites read it through: a source of live events it is
## brought by hand (`Source`, an `EventManager` answering `instances()`) and one live event of a
## row (`Coming`), standing wherever it is put. A helper, not a suite: the runner loads only
## `test_*.gd`.

## The day's events, holding the live events it was brought. Its view is the manager's own, which the
## rig looks through about her at the origin with nothing covering it; with no player handed in, the
## manager's own tick never looks it through again.
class Source extends EventManager:
	var _coming: Array[EventInstance] = []

	## Puts `instance` in the world, among the live events.
	func bring(instance: EventInstance) -> void:
		add_child(instance)
		instance.set_process(false)
		_coming.append(instance)

	## Overrides EventManager.instances.
	func instances() -> Array[EventInstance]:
		return _coming

## A live event of `row` the edge reads: its row, its name in the log and the box it draws, standing
## wherever it is put, set up for nothing else and hidden.
class Coming extends EventInstance:
	var _row: EventDef
	var _box: Rect2

	func _init(the_row: EventDef, box: Rect2) -> void:
		super()
		_row = the_row
		_box = box
		visible = false

	## Overrides EventInstance._ready.
	func _ready() -> void:
		pass

	## Overrides EventInstance.row.
	func row() -> EventDef:
		return _row

	## Overrides EventInstance.logged_name.
	func logged_name() -> String:
		return _row.id()

	## Overrides EventInstance.drawn_box.
	func drawn_box() -> Rect2:
		return _box
