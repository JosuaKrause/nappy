class_name SceneryResidence
extends RefCounted
## One placement's standing with the scenery residency (`SceneryResidency`), which stands its
## pictures up near the view and frees them far away: whether they are resident now, the ground they
## cover, and the switch between the two. A building, the home door and every `ScenerySprite` are
## each composed of one, so the residency asks all of them through this one class, though they share
## no class below `Node2D`.
##
## The placement keeps what is its own: the ground it covers (`bounds`) and what standing up or
## freeing its pictures does to it (`apply`), each handed in as one of its own methods. A Callable
## names its method, so a subclass's override of either is the one called.

var _owner: Node2D
var _bounds: Callable
var _apply: Callable
var _counted_as: FrameTiming.Job
var _resident: bool

## `owner` is the placement this standing belongs to; `bounds` answers its world rectangle
## (`func() -> Rect2`) and `apply` stands its pictures up or frees them (`func(resident: bool)`),
## run only when the standing changes. `counted_as` is the job the frame record counts its
## preparation as. A placement starts resident, drawing on its own until the residency takes it,
## unless `resident` says otherwise.
func _init(owner: Node2D, bounds: Callable, apply: Callable,
		counted_as := FrameTiming.Job.PROP, resident := true) -> void:
	_owner = owner
	_bounds = bounds
	_apply = apply
	_counted_as = counted_as
	_resident = resident

## Whether the placement's pictures are resident now. Its gameplay facts (collision, poster
## frontage, a sealed door) stay whichever way this answers.
func is_resident() -> bool:
	return _resident

## Stands the placement's pictures up or frees them; nothing happens when it already stands that
## way.
func set_resident(resident: bool) -> void:
	if _resident == resident:
		return
	_resident = resident
	_apply.call(resident)

## The world rectangle the placement's pictures can cover, which the residency tests against its
## load and retention boundaries.
func bounds() -> Rect2:
	var rect: Rect2 = _bounds.call()
	return rect

## The job the frame record counts this placement's preparation as (`FrameTiming.Job`).
func counted_as() -> FrameTiming.Job:
	return _counted_as

## Whether the placement is freed or about to be, after which the residency lets it go. This
## standing outlives its owner while the residency still holds it, so it is asked before anything
## else.
func is_gone() -> bool:
	return not is_instance_valid(_owner) or _owner.is_queued_for_deletion()
