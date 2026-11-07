class_name GroundShadow
extends Node2D
## **One object's contact shadow, drawn from its picture on the shadow page** and on the shadow
## draw layer (`DrawLayer.Layer.SHADOWS`): a child of the object it is the shadow of, so it goes
## where the object goes, is culled with its own small rectangle and hides when the object does,
## while it is drawn with every other shadow rather than between the sprites around it.
##
## The shape is the source (`GroundShape`): the bake drew the picture from it
## (`GroundShape.shadow_image()`), the shape names the picture it draws from
## (`GroundShape.shadow_picture_name()`) and draws it (`GroundShape.draw_shadow_picture()`), so the
## picture, the polygon the debug view traces (`GroundShape.shadow_outline()`) and the ground the
## object stands on are one datum. **The object still draws its own shadow**, through this node:
## one canvas item spanning a whole field and drawing every shadow in it would intersect the screen
## always and draw every shadow there is, the culling lost.
##
## It takes its own reference on the shadow page while it is in the tree, the proof every drawing
## node keeps that the page it draws from is there (`AtlasLibrary.acquire()`), and redraws only when
## the shape, the place or the axis it is handed changes: a walker's shadow is drawn once.

var _atlas: AtlasLibrary
var _shape: GroundShape = null
var _at := Vector2.ZERO
var _axis := Vector2.RIGHT

## A shadow drawn from `atlas`'s shadow page, of nothing until `cast()` hands it a shape. Named
## for what it is, so it can be told apart from the object's other children in the tree.
func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas
	name = "Shadow"

func _enter_tree() -> void:
	_atlas.acquire(GroundShape.SHADOW_GROUP)
	DrawLayer.draw_on(self, DrawLayer.Layer.SHADOWS)

func _exit_tree() -> void:
	_atlas.release(GroundShape.SHADOW_GROUP)

## The shadow of `shape`, with its centre at `at` in the object's own frame and its spine along
## `axis` (a point's shadow ignores the axis, as its outline does). Redraws only on a change.
func cast(shape: GroundShape, at: Vector2 = Vector2.ZERO, axis: Vector2 = Vector2.RIGHT) -> void:
	if shape == _shape and at == _at and axis == _axis:
		return
	_shape = shape
	_at = at
	_axis = axis
	queue_redraw()

func _draw() -> void:
	if _shape == null:
		return
	_shape.draw_shadow_picture(self, _at, _axis, _atlas.region(_shape.shadow_picture_name()))
