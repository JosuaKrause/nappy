class_name ParkSign
extends ScenerySprite
## **A park sign at a junction corner**, pointing the way to a park (`ParkSigns`, which says where
## each stands and which way it points, worked out once for the run). City furniture fixed for the
## run like the signal heads: no body, no field and no part in the meter, so it is walked past
## like a street tree. The plate faces the camera whichever way the sign points, so the arrow
## printed on it is the whole of the direction, one picture per way.
##
## Feet-anchored and added to the y-sorted layer, so she walks in front of a sign on the near
## corner and behind one on the far side of the junction.

## Region names on the `street_kit` atlas group, one per way the arrow points; `_enter_tree()` and
## `_exit_tree()` acquire and release the group, as a signal head does.
const UP := &"props/park_sign_up"
const DOWN := &"props/park_sign_down"
const LEFT := &"props/park_sign_left"
const RIGHT := &"props/park_sign_right"

## The way the sign points, one step on the lattice.
var _points := Vector2i.UP
## The baked atlas pages the sign draws from (`AtlasLibrary`), handed by the city before it is
## added; a sign nobody handed one (a suite's) makes its own when it first enters the tree.
var _atlas: AtlasLibrary = null
## What the sign is drawn through (`ParkSignDrawer`), handed by the city before it is added; a
## sign nobody handed one makes its own over its `_atlas` when it first enters the tree.
var _drawer: ParkSignDrawer = null

## Mounts the sign pointing `points`, drawing from `library` through `drawer`, before the city
## adds it.
func mount(library: AtlasLibrary, drawer: ParkSignDrawer, points: Vector2i) -> void:
	_atlas = library
	_drawer = drawer
	_points = points

func _enter_tree() -> void:
	if _atlas == null:
		_atlas = AtlasLibrary.new()
	if _drawer == null:
		_drawer = ParkSignDrawer.new(_atlas)
	_atlas.acquire(&"street_kit")

func _exit_tree() -> void:
	_atlas.release(&"street_kit")

## Overrides ScenerySprite._scenery_bounds.
func _scenery_bounds() -> Rect2:
	return Rect2(global_position - Vector2(16, 48), Vector2(32, 56))

## The picture for the way the sign points.
func _picture() -> StringName:
	match _points:
		Vector2i.DOWN:
			return DOWN
		Vector2i.LEFT:
			return LEFT
		Vector2i.RIGHT:
			return RIGHT
	return UP

func _draw() -> void:
	if not residence().is_resident():
		return
	_drawer.draw_sign(self, _picture())
