class_name WalkThroughHutWatcher
extends HintWatcher
## **Walk through the hut**: when a checkpoint hut she may walk through first comes into her view,
## the bubble hints that she can (curly-moose #819, "it will become useful eg to also show that
## guard huts can be walked through"). Which bodies those are and whether she can see one are the
## events' answer (`EventManager.doors_in_sight()`). A door's bodies in view when the bubble goes
## up are all met; the next door she sees asks again, within the lesson's few shows.

var _events: EventManager
## The instance ids of the doors' bodies met this walk.
var _met := {}

func _init(events: EventManager) -> void:
	_events = events

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WALK_THROUGH_HUT

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_met.clear()

## Overrides HintWatcher.asks.
func asks(_frame: HintFrame) -> bool:
	for door in _events.doors_in_sight():
		if not _met.has(door.get_instance_id()):
			return true
	return false

## Overrides HintWatcher.shown.
func shown() -> void:
	for door in _events.doors_in_sight():
		_met[door.get_instance_id()] = true
