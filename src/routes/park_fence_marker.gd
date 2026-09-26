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
var draw_support := true
## A narrow rail attaches to the inward face of its pole; the shaft remains visible beside it.
var rail_offset := 0.0
## The mounted sign's true ground point relative to the panel that draws in front of its rails.
var sign_offset := Vector2.ZERO

func _draw() -> void:
	if piece == Piece.POST:
		Sprites.draw_standing(self, AtlasLibrary.region(JOINT), Vector2.ZERO)
	elif piece == Piece.SIGN:
		_draw_panel()
		Sprites.draw_standing(self, AtlasLibrary.region(MOUNTED_SIGN), sign_offset)
	else:
		super._draw()

func _draw_panel() -> void:
	if across:
		super._draw_panel()
		return
	# Supports are upright even when the rail travels away from the camera. The feet and
	# y-sort origin remain on the near end of this panel's ground span.
	if draw_support:
		Sprites.draw_standing(self, AtlasLibrary.region(JOINT), Vector2.ZERO)
	_draw_rail(LOWER_RISE, 5.2)
	_draw_rail(UPPER_RISE, RAIL_HEIGHT)

## Only the top surface stretches along the ground. The near face retains its height;
## stretching the whole elevation would make short archway rails shorter than park rails.
func _draw_rail(elevation: float, face_height: float) -> void:
	var texture := AtlasLibrary.region(RAIL_ALONG)
	var top_height := texture.get_height() - RAIL_HEIGHT
	draw_texture_rect_region(texture, Rect2(rail_offset - 3.0, -span - elevation, 6.0, span),
			Rect2(0.0, 0.0, 6.0, top_height))
	draw_texture_rect_region(texture, Rect2(rail_offset - 3.0, -elevation, 6.0, face_height),
			Rect2(0.0, top_height, 6.0, RAIL_HEIGHT))
