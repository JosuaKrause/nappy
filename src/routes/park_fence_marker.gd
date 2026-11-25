class_name ParkFenceMarker
extends ClosureMarker
## The park's connected fence in upright projection. The two rails share a ground line:
## elevation shifts only screen Y, so the upper rail hides most of the lower one end-on.
## Posts keep their full standing height on either axis and at every corner.

const RAIL_ALONG := &"closures/park_rail_along"
const JOINT := &"closures/park_post"
const MOUNTED_SIGN := &"closures/park_sign"
const RAIL_HEIGHT := 5.6
const UPPER_RISE := 21.0
const LOWER_RISE := 12.6

## The run's terminal support is its separately placed joint, shared with the next side.
var _draws_support := true
## A narrow rail attaches to the inward face of its pole; the shaft remains visible beside it.
var _rail_offset := 0.0
## The mounted sign's true ground point relative to the panel that draws in front of its rails.
var _sign_offset := Vector2.ZERO

## Mounts the sign on this panel, once, before it enters the tree: `offset` is the sign's true
## ground point relative to this panel's feet.
func mount_sign(offset: Vector2) -> void:
	_sign_offset = offset

## Mounts an end-on panel's rails on the run's poles, once, before it enters the tree: whether it
## draws the support its rails start from (the run's last panel ends on the separately placed post
## instead, `ParkClosure.posts()`), and `offset`, how far across the screen the rails sit from the
## pole's centre, on its inward face.
func mount_rail(draws_support: bool, offset: float) -> void:
	_draws_support = draws_support
	_rail_offset = offset

## Overrides ClosureMarker._draw.
func _draw() -> void:
	if not residence().is_resident():
		return
	if _piece == Piece.POST:
		_stand(_atlas.region(JOINT), Vector2.ZERO)
	elif _piece == Piece.SIGN:
		_draw_panel()
		_stand(_atlas.region(MOUNTED_SIGN), _sign_offset)
	else:
		super._draw()

## Overrides ClosureMarker._draw_panel.
func _draw_panel() -> void:
	if _across:
		super._draw_panel()
		return
	# Supports are upright even when the rail travels away from the camera. The feet and
	# y-sort origin remain on the near end of this panel's ground span.
	if _draws_support:
		_stand(_atlas.region(JOINT), Vector2.ZERO)
	_draw_rail(LOWER_RISE, 5.2)
	_draw_rail(UPPER_RISE, RAIL_HEIGHT)

## Only the top surface stretches along the ground. The near face retains its height;
## stretching the whole elevation would make short archway rails shorter than park rails.
func _draw_rail(elevation: float, face_height: float) -> void:
	var texture := _atlas.region(RAIL_ALONG)
	var top_height := texture.get_height() - RAIL_HEIGHT
	_drawer.draw(self, texture, Rect2(_rail_offset - 3.0, -_span - elevation, 6.0, _span),
			Rect2(0.0, 0.0, 6.0, top_height))
	_drawer.draw(self, texture, Rect2(_rail_offset - 3.0, -elevation, 6.0, face_height),
			Rect2(0.0, top_height, 6.0, RAIL_HEIGHT))
